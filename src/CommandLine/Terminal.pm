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

require IO::Handle;

our $IN = *STDIN;
our $ReadKey = 0;
our $STTY = 0;

my $getchar;
my $getchar_nb;

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
		require Fcntl;
		$getchar = sub { getc $IN; };
		$getchar_nb = sub {
			my $ch;
			my $f = fcntl($IN, &Fcntl::F_GETFL, 0);
			fcntl($IN, &Fcntl::F_SETFL, $f|&Fcntl::O_NONBLOCK);

			$ch = getc $IN;

			fcntl($IN, &Fcntl::F_SETFL, $f);

			$ch;
		};

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
		$getchar = sub { Term::ReadKey::ReadKey(0, $IN) };
		$getchar_nb = sub { Term::ReadKey::ReadKey(-1, $IN) };
		*raw = sub { Term::ReadKey::ReadMode(4, $IN) };
		*normal = sub { Term::ReadKey::ReadMode(1, $IN) };
		*width = sub { eval { (Term::ReadKey::GetTerminalSize(0, $IN))[0] } || 80 };

		$ReadKey = 1;
	}
}

sub getchar
{
	my $c = $getchar->();

	if(ord($c) == 27)
	{
		my $k = $getchar_nb->();
		if(defined $k)
		{
			if($k eq '[')
			{
				$c .= $k;
				do {
					$k = $getchar_nb->();
					last unless defined $k;
					$c .= $k;
				} until(ord($k) >= 64 and ord($k) <= 126);
			}
			elsif($k eq 'O')
			{
				$c .= $k;
				$c .= $getchar_nb->();
			}
			else
			{
				$IN->ungetc(ord($k));
			}
		}
	}

	CommandLine::Terminal::Key->new($c);
}

sub supports_raw
{
	($ReadKey or $STTY) ? 1 : 0;
}

package CommandLine::Terminal::Key;

use overload '""' => sub { $_[0]->{value} };
use overload 'eq' => sub { "$_[0]" eq $_[1] };

sub new
{
	my ($pkg,$str) = @_;
	my $self = bless {};

	$self->{value} = $str;
	$self;
}

BEGIN
{
	no strict 'refs';
	for ('A' .. 'Z')
	{
		my $ch = $_;
		*{"CTRL_$ch"} = sub { ord($_[0]) == ord($ch) - 64 };
	}
}

sub NUL
{
	ord($_[0]) == 0;
}

sub ESC
{
	$_[0] eq "\033";
}

sub ENTER
{
	$_[0] eq "\n";
}

sub TAB
{
	$_[0] eq "\t";
}

sub BS
{
	ord($_[0]) == 8 or ord($_[0]) == 127;
}

*BACKSPACE = \&BS;

sub HOME
{
	$_[0] eq "\033[1~" or $_[0] eq "\033OH";
}

*END = sub {
	$_[0] eq "\033[4~" or $_[0] eq "\033OF";
};

sub DELETE
{
	$_[0] eq "\033[3~";
}

sub PAGEUP
{
	$_[0] eq "\033[5~";
}

sub PAGEDOWN
{
	$_[0] eq "\033[6~";
}

sub F5
{
	$_[0] eq "\033[15~";
}

sub F6
{
	$_[0] eq "\033[17~";
}

sub F7
{
	$_[0] eq "\033[18~";
}

sub F8
{
	$_[0] eq "\033[19~";
}

sub F9
{
	$_[0] eq "\033[20~";
}

sub F10
{
	$_[0] eq "\033[21~";
}

sub F11
{
	$_[0] eq "\033[23~";
}

sub F12
{
	$_[0] eq "\033[24~";
}

sub UP
{
	$_[0] eq "\033[A";
}

sub DOWN
{
	$_[0] eq "\033[B";
}

sub RIGHT
{
	$_[0] eq "\033[C";
}

sub LEFT
{
	$_[0] eq "\033[D";
}

sub CHAR
{
	$_[0] =~ /^[[:print:]]$/;
}

1
