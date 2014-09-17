package CommandLine::OptParse;
use strict;
use warnings;

=head1 NAME

  CommandLine::OptParse - a command-line option parser that produces its own help text

=head1 SYNOPSIS

  use CommandLine::OptParse
      prog => 'myprogram',
      banner => 'A Sample Program';

  my $help;
  my $version;
  my $file;
  my $opts = CommandLine::OptParse::options {
    on('-h', '--help', "Display help", \$help);
    on('-v', '--version', "Display version", \$version);
    on('-f', '--file FILE', "Input file", \$file);
  };

  my @args = $opts->(@ARGV);
  print "$opts" and exit if $help;

=head1 METHODS

=over 4

=item CommandLine::OptParse::options $code_block

Create an option parser based on the given $code_block. The $code_block should call the method on() with the
short and long option names including a value label if any, the option description text, and a $ref to
receive the option value.

The returned value is a subroutine ref, which takes the argument array (@ARGV or another) as its parameter list, and
returns the arguments remaining after parsing out options and values. This subroutine does not return if there is a
parsing error.

The subroutine ref is also stringifiable as the program's help text.

=item $code_block::on [$short] [$long] [$description] $ref

Option names, $short and $long, are each optional, but at least one must be given. The union of the option names
is passed to Getopt::Long::GetOptions() as the option specification (e.g. '-h' and '--help' together become 'h|help').
If either the $short or $long name includes a value label, it is appended to the specification as '=s'.

The $ref is passed to Getopt::Long::GetOptions(), and can be a scalar ref, hash ref, list ref, or subroutine.

Nothing is returned.

=back

=cut

use overload '""' => \&formatusage;

use Getopt::Long qw(:config bundling);
use File::Basename;
use Pod::Usage;

our $prog = basename($0, '.pl');
our $banner;
our $description;

sub import
{
	my $pkg = shift;
	my %cfg = @_;

	$prog            = $_ for grep { defined } $cfg{prog};
	$banner          = $_ for grep { defined } $cfg{banner};
	$description     = $_ for grep { defined } $cfg{description};
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
		my $caller = (caller)[0];

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
			if($long and $long =~ $longval)
			{
				die "cannot specify value name twice for single option ($long)" if $value;
				($long,$value) = $long =~ $longval;
			}

			if($long)
			{
				my $longtext = $value ? "$long $value" : $long;
				push @help, sprintf " %-2s %-22s   %s", $short || '', $longtext, $desc || '';
			}
			else
			{
				my $shorttext = $value ? "$short $value" : $short;
				push @help, sprintf " %-2s %-22s   %s", $shorttext, "", $desc || '';
			}

			my @names = ();
			push @names, substr($short, 1) if $short;
			push @names, substr($long, 2) if $long;

			my $key = join('|', @names);
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
	$usagemsg .= "=head1 DESCRIPTION$/$/$description" if $description;

	my $fn = sub {
		local @ARGV = @_;

		open my $infd, '<', \$usagemsg;
		Getopt::Long::GetOptions(%opts) or pod2usage(exitval=>1, verbose=>3, input=>$infd);

		@ARGV;
	};

	my $package = "CommandLine::OptParse::$fn";

	no strict 'refs';
	@{$package . '::ISA'} = qw/CommandLine::OptParse/;
	*{$package . '::_getmessage'} = sub { $usagemsg };
	bless $fn, $package;
}


1
