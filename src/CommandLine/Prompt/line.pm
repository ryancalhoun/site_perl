use strict;
use warnings;

sub _getline_term_impl
{
	my $value = '';
	my $i = 0;

	CommandLine::Terminal::raw();
	eval
	{
		while(1)
		{
			my $len = $i;
			my $c = CommandLine::Terminal::getchar();

			die "error: reached end of input$/" if $c->NUL;
			die "<Ctrl+C>$/" if $c->CTRL_C;

			if($c->CTRL_D or $c->ESC)
			{
				undef $value;
				last;
			}
			elsif($c->ENTER)
			{
				last;
			}
			elsif($c->BACKSPACE)
			{
				if($i > 0)
				{
					$value = substr($value, 0, $i-1) . substr($value, $i);
					--$i;
				}
			}
			elsif($c->DELETE)
			{
				if($i < length($value))
				{
					$value = substr($value, 0, $i) . substr($value, $i + 1);
				}
			}
			elsif($c->LEFT)
			{
				--$i if $i > 0;
			}
			elsif($c->RIGHT)
			{
				++$i if $i < length($value);
			}
			elsif($c->HOME)
			{
				$i = 0;
			}
			elsif($c->END)
			{
				$i = length($value);
			}
			elsif($c->CHAR)
			{
				$value = substr($value, 0, $i) . $c . substr($value, $i);
				++$i;
			}

			print "\033[${len}D\033[K" if $len > 0;
			print "$value\033[K";

			my $x = length($value) - $i;
			print "\033[${x}D" if $x > 0;
		}
	};
	CommandLine::Terminal::normal();

	print $/;

	die $@ if($@);
	$value;
}

1
