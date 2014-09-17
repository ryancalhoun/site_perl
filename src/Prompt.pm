package Prompt;

use strict;
use warnings;

=head1 NAME

  Prompt - manage a variety of user prompt scenarios

=head1 SYNOPSIS

  use Prompt;

  my $name = Prompt::string("Name: ");
  my $age = Prompt::string("Age: ", qr/^\d+/);
  my $image = Prompt::file("Selfie: ");

=head1 METHODS

=over 4

=item Prompt::string $prompt_text, $pattern

Display prompt text and return result. If $pattern is given, the response must match it, or
the prompt will loop until satisfied.

=item Prompt::file $prompt_text

Display prompt text and return a valid filename. If the package Term::ReadKey (or the fallback /bin/stty) is available,
provide a tab-complete semantic to navigate existing filenames.

=item Prompt::directory $prompt_text

Display prompt text and return a valid directory name. If the package Term::ReadKey (or the fallback /bin/stty) is available,
provide a tab-complete. Non-directories are filtered out of tab-complete candidates.

=back

=cut

use List::Util;
use File::Basename;

our $IN = *STDIN;
our $completion_limit = 100;

my $stty = 0;

BEGIN
{
	eval { require Term::ReadKey };

	if(not $@)
	{
		*complete_file = \&complete_file_term;
		*term_raw = sub { Term::ReadKey::ReadMode(4, $IN) };
		*term_normal = sub { Term::ReadKey::ReadMode(1, $IN) };
		*term_getc = sub { Term::ReadKey::ReadKey(0, $IN) };
		*term_width = sub { (Term::ReadKey::GetTerminalSize(0, $IN))[0] };
	}
	elsif(-x '/bin/stty')
	{
		$stty = 1;
		*complete_file = \&complete_file_term;
		*term_raw = sub { system "stty raw icrnl opost -echo" };
		*term_normal = sub { system "stty cooked echo" };
		*term_getc = sub { getc };
		*term_width = sub {
			open my $s, "stty size|cut -d' ' -f2|";
			chomp(my $w = <$s>);
			close $s;
			return $w;
		};
	}
	else
	{
		*complete_file = \&complete_file_basic;
	}
}

sub import
{
	my $pkg = shift;
	my %cfg = @_;

	my $caller = (caller)[0];

	no strict 'refs';
	$IN = *{$caller . '::' . $_} for grep { defined } $cfg{IN};
	$completion_limit = $_ for grep { defined } $cfg{completion_limit};

	*complete_file = \&complete_file_basic if $stty and ! -t $IN;
}

sub string
{
	my ($p,$exp) = @_;

	print $p;
	my $value;
	while(1)
	{
		chomp($value = <$IN>);
		if($value and $exp and $value !~ $exp)
		{
			print "Not understood, try again: ";
			next;
		}
		last;
	}
	$value;
}

sub file
{
	my $f = complete_file(@_);
}

sub directory
{
	my $f = complete_file(@_, sub { grep { -d } @_ });
}

sub complete_file_basic
{
	chomp(my $value = <$IN>);
	return $value;
}

sub complete_file_term
{
	my ($p,$filter) = @_;

	$filter ||= sub { @_ };

	print $p;

	my $line = '';
	my $value = '';
	my $prev = '';
	my @candidates;

	my $readchar;
	my $readpath;
	my $read_yn;

	my $showall = sub
	{
		my @f = map { -d $_ ? basename($_) . '/' : basename($_) } @candidates;

		my $termwidth = term_width();
		my $textwidth = (List::Util::max map { length($_) } @f) + 4;

		my $cols = int($termwidth / $textwidth) || 1;
		my $colwidth = int($termwidth / $cols);

		print "\n";
		my $i = 0;
		for(@f)
		{
			printf "%-${colwidth}s", $_;
			print "\n" if(++$i % $cols == 0);
		}

		print "\n" if(scalar @f % $cols != 0);
	};

	$readpath = sub
	{
		my $c = shift;
		if($c eq "\n")
		{
			return 0;
		}
		elsif(ord($c) == 3 or ord($c) == 4)
		{
			undef $value;
			return 0;
		}
		elsif(ord($c) == 8 or ord($c) == 127)
		{
			print "\b \b";
			chop $value if $value eq $line;
			chop $line;
		}
		elsif($c eq "\t" and not -f $value)
		{
			@candidates = $filter->(glob "$line*");

			if(@candidates)
			{
				my $prefix = common_prefix(@candidates);
				my $remainder = substr($prefix, length $line);
				$value = $line = $prefix;

				if(scalar @candidates == 1)
				{
					-f $value
						and map { $_ .= ' ' } $line, $remainder
						or map { $_ .= '/' } $value, $line, $remainder;
					print $remainder;
				}
				else
				{
					if($prev eq "\t")
					{
						if(scalar @candidates > $completion_limit)
						{
							print "\nDisplay all ", scalar @candidates, " possibilities? (y or n)";
							$readchar = $read_yn;
						}
						else
						{
							$showall->();
							print "$p$line";
						}
					}
					else
					{
						print "$remainder";
					}
				}
			}
		}
		elsif($c =~ /[[:print:]]/)
		{
			print $c;
			map { $_ .= $c } $line, $value;
		}
		else
		{
		}
		$prev = $c;
		return 1;
	};

	$read_yn = sub
	{
		my $c = shift;
		if($c eq 'y' or $c eq ' ')
		{
			$showall->();
		}
		elsif($c eq 'n')
		{
			print "\n";
		}
		else
		{
			return 1;
		}

		print "$p$line";
		$readchar = $readpath;
		return 1;
	};

	$readchar = $readpath;

	term_raw();
	eval
	{
		while(1)
		{
			my $c = term_getc();
			last unless ord($c) and $readchar->($c);
		}
	};
	term_normal();

	print "\n";

	die $@ if($@);
	return $value;
}

sub common_prefix
{
	my $p = shift;
	for(@_) { chop $p while(!/^\Q$p\E/); }
	$p;
}

1
