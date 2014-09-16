package OptParse;
use strict;
use warnings;

use overload '""' => \&formatusage;

use Getopt::Long qw(:config bundling);
use File::Basename;
use Pod::Usage;

our $prog = basename($0, '.pl');
our $banner;
our $caller;

sub import
{
	my $pkg = shift;
	my %cfg = @_;

	$caller = (caller)[0];

	$prog = $_ for grep { defined } $cfg{prog};
	$banner = $_ for grep { defined } $cfg{banner};
}

sub formatusage
{
	my ($self) = @_;
	open my $infd, '<', \$self->_getmessage();
	open my $outfd, '>', \(my $out = '');
	pod2usage(exit=>'NOEXIT', verbose=>3, input=>$infd, output=>$outfd);
	close $infd;
	close $outfd;

	$out;
}

sub options(&)
{
	my $block = \&{shift @_};

	my @help;
	my %opts;

	{
		no strict 'refs';
		local *{"${caller}::on"} = sub
		{
			my $ref = pop;
			my $short;
			my $long;
			my $desc;

			if($_[0] =~ /^--/)
			{
				$long = shift;
			}
			elsif($_[0] =~ /^-/)
			{
				$short = shift;
				$long = shift if $_[0] =~ /^--/;
			}
			else
			{
				die "option names must begin with - or -- ($_[0])";
			}

			$desc = shift;

			my $shortval = qr/(-.)\s?(.*)/;
			my $longval = qr/(--[\w\-_]+?)(?:=|\s)(.*)/;
			my $value;

			($short,$value) = $short =~ $shortval if($short and $short =~ $shortval);
			if($long =~ $longval)
			{
				die "cannot specify value name twice for single option ($long)" if $value;
				($long,$value) = $long =~ $longval;
			}

			if($long)
			{
				my $longtext = $value ? "$long $value" : $long;
				push @help, sprintf " %-2s %-22s   %s", $short, $longtext, $desc || '';
			}
			else
			{
				my $shorttext = $value ? "$short $value" : $short;
				push @help, sprintf " %-2s %-22s   %s", $shorttext, "", $desc || '';
			}

			my $key = join('|', substr($short, 1), substr($long, 2));
			$key .= '=s' if $value;

			$opts{$key} = $ref;
		};

		$block->();
	}

	my $usagemsg = join($/,
		join("$/$/", '=head1 NAME', $prog . ' - ' . ($banner || ''), '=head1 SYNOPSIS', ''),
		sprintf("%s [options]$/", $prog),
		@help, '', ''
	);

	my $fn = sub {
		open my $infd, '<', \$usagemsg;
		Getopt::Long::GetOptions(%opts) or pod2usage(exitval=>1, verbose=>3, input=>$infd);
	};

	my $package = "OptParse::$fn";
	bless $fn;

	no strict 'refs';
	@{$package . '::ISA'} = (ref($fn));
	*{$package . '::_getmessage'} = sub { $usagemsg };
	bless $fn, $package;
}


1
