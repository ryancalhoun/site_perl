package CommandLine::Terminal;

use strict;
use warnings;

=head1 NAME

  CommandLine::Terminal - handle input mode and character reading

=head1 SYNOPSIS

  use CommandLine::Terminal;

  CommandLine::Terminal::raw();
  my $ch = CommandLine::Terminal::getchar();
  CommandLine::Terminal::normal();

=head1 METHODS

=over 4

=item CommandLine::Terminal::getchar

Get a single character from the terminal's input.

=item CommandLine::Terminal::raw

Put the terminal's input into raw mode with echo off.

=item CommandLine::Terminal::normal

Restore cooked mode and echo.

=item CommandLine::Terminal::width

Get the with (number of columns) of the terminal.

=item CommandLine::Terminal::supports_raw

True if the Term::ReadKey package is available, or if the terminal represents a tty and /bin/stty is available.

=back

=cut

our $IN = *STDIN;
our $ReadKey = 0;
our $STTY = 0;

sub import
{
	my $pkg = shift;
	my %cfg = @_;

	my $caller = (caller)[0];
	no strict 'refs';
	$IN = *{$caller . '::' . $_} for grep { defined } $cfg{IN};

	eval { require Term::ReadKey };

	if($@)
	{
		*getchar = sub { getc $IN };

		if(-t $IN)
		{
			*raw = sub { system "stty raw icrnl opost -echo" };
			*normal = sub { system "stty cooked echo" };
			*width = sub {
				open my $s, "stty size|cut -d' ' -f2|";
				chomp(my $w = <$s>);
				close $s;
				return $w;
			};

			$STTY = 1;
		}
		else
		{
			*raw = sub { die "cannot put non-terminal handle into raw mode" };
			*normal = sub { };
			*width = sub { };
		}
	}
	else
	{
		*getchar = sub { Term::ReadKey::ReadKey(0, $IN) };
		*raw = sub { Term::ReadKey::ReadMode(4, $IN) };
		*normal = sub { Term::ReadKey::ReadMode(1, $IN) };
		*width = sub { (Term::ReadKey::GetTerminalSize(0, $IN))[0] || 80 };

		$ReadKey = 1;
	}
}

sub supports_raw
{
	($ReadKey or $STTY) ? 1 : 0;
}

1
