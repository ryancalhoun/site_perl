
sub _getline_term_impl
{
	my $value = '';

	CommandLine::Terminal::raw();
	eval
	{
		while(1)
		{
			my $c = CommandLine::Terminal::getchar();

			die "error: reached end of input$/" if ord($c) == 0;
			die "<Ctrl+C>$/" if ord($c) == 3;

			if(ord($c) == 4)
			{
				undef $value;
				last;
			}
			elsif($c eq "\n")
			{
				last;
			}
			elsif(ord($c) == 8 or ord($c) == 127)
			{
				print "\b\033[K" if($value);
				chop $value;
			}
			elsif($c =~ /[[:print:]]/)
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
