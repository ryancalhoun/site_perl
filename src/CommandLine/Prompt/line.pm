use strict;
use warnings;

sub _getline_term_impl
{
	my $value = '';

	CommandLine::Terminal::raw();
	eval
	{
		while(1)
		{
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
			elsif($c->BS)
			{
				print "\b\033[K" if($value);
				chop $value;
			}
			elsif($c->CHAR)
			{
				print $c;
				$value .= $c;
			}
		}
	};
	CommandLine::Terminal::normal();

	print "\n";

	die $@ if($@);
	$value;
}

1
