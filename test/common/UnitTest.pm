package UnitTest;

use 5.008005;
use strict;
use warnings;

BEGIN
{
	use Test::More;
	require Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = (@Test::More::EXPORT, qw(catch));

	no strict 'refs';
	no warnings 'redefine';

	for my $assert (qw(is isnt like unlike isa_ok))
	{
		*$assert = sub ($$;$)
		{
			my $a = "Test::More::$assert";
			&$a(@_) or die new UnitTest::Failure;
		}
	}

	*ok = sub ($;$)
	{
		Test::More::ok($_[0], $_[1]) or die new UnitTest::Failure;
	};

	*cmp_ok = sub ($$$;$)
	{
		Test::More::cmp_ok($_[0], $_[1], $_[2], $_[3]) or die new UnitTest::Failure;
	};

	*is_deeply = sub
	{
		# Test::Builder 0.72 (perl 5.10) defines a _try, which is used internally to
		# check types in a safe way. This is a bit of a hack to work with Test::Builder 0.32
		# (perl 5.8), but it'll have to do.
		my $failed;
		{
			local $SIG{__DIE__};
			eval { Test::More::is_deeply(@_) } or $failed = 1;
		}
		die new UnitTest::Failure if $failed;
		
	};

	# Time::HiRes is not included in perl 5.8.5 (rhel4), so we invoke the system call
	# directly, if possible.
	eval
	{
		require Time::HiRes;
		Time::HiRes->import(qw(gettimeofday));
		1
	}
	or *gettimeofday = sub ()
	{
		require 'sys/syscall.ph';
		my $timeval = pack('LL', ());
		syscall(&SYS_gettimeofday, $timeval, 0) != -1 or die "gettimeofday() syscall failed: $!";
		my ($sec,$usec) = unpack('LL', $timeval);
		$sec + $usec/1e6;
	};
}

sub new
{
	my ($class,$name) = @_;
	my $this = {};
	bless $this, $class;

	$this->{class} = $class;
	$this->{name} = $name;

	$this;
}

sub quiet
{
	my ($this) = @_;
	$this->{quiet} = 1;
}

sub run
{
	my ($this) = @_;

	my $stdout = '';
	my $stderr = '';
	open my $out_fh, '>', \$stdout;
	open my $err_fh, '>', \$stderr;

	# reset singleton
	my $t = new Test::Builder;
	$t->reset;
	$t->plan('no_plan');
	$t->no_header(1);
	$t->no_ending(1);

	$t->output($out_fh);
	$t->failure_output($err_fh);
	my %results;

	$this->begin;

	no strict 'refs';

	my $package = "$this->{class}::";
	for my $test(sort grep { /^test/ } keys %$package)
	{
		my $name = "$package$test";
		my $state = '.';

		my $start = gettimeofday;

		eval
		{
			local $SIG{__DIE__} = sub
			{
				if(ref($_[0]) eq 'UnitTest::Failure')
				{
					$state = 'F';
				}
				else
				{
					$state = 'E';
					local *__ANON__ = 'stackdump';
					print $err_fh Carp::longmess(@_);
					fail($name);
				}
			};
			$this->setup($name);
			$this->$test($name);
		};
		$this->teardown($name);
		print STDERR $state;

		$results{$name} = UnitTest::Result->new($state eq '.', $state, gettimeofday - $start);
	}

	$this->end;

	close $out_fh;
	close $err_fh;

	unless($this->{quiet})
	{
		print STDOUT "$/$stdout";
	}
	if($stderr)
	{
		print STDERR "$/$stderr";
	}

	for(new Test::Builder->details())
	{
		$results{$_->{name}}->_count_passed if $_->{ok};
	}
	\%results;
}

sub begin
{
	# override
}

sub setup
{
	# override
}

sub teardown
{
	# override
}

sub end
{
	# override
}

sub catch
{
	my ($sub) = @_;
	eval
	{
		local $SIG{__DIE__} = sub {};
		$sub->();
	};
	$@;
}

package UnitTest::Result;

sub new
{
	my ($class,$success,$reason,$elapsed) = @_;
	my $this = bless {}, $class;

	$this->{success}        = $success;
	$this->{reason}         = $reason;
	$this->{elapsed}        = $elapsed;
	$this->{asserts_passed} = 0;

	$this;
}

sub success
{
	my ($this) = @_;
	$this->{success};
}

sub failure
{
	my ($this) = @_;
	$this->{reason} eq 'F';
}

sub error
{
	my ($this) = @_;
	$this->{reason} eq 'E';
}

sub elapsed
{
	my ($this) = @_;
	$this->{elapsed};
}

sub asserts_passed
{
	my ($this) = @_;
	$this->{asserts_passed};
}

sub _count_passed
{
	my ($this) = @_;
	++$this->{asserts_passed};
}

package UnitTest::Failure;

sub new
{
	my ($class) = @_;
	my $this = bless {}, $class;

	$this;
}

1
