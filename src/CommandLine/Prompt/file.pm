
sub _complete_file_term_impl
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

		my $termwidth = CommandLine::Terminal::width();
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
		if($c->ENTER)
		{
			return 0;
		}
		elsif($c->CTRL_C)
		{
			die "<Ctrl+C>$/" unless $value;
			undef $value;
			return 0;
		}
		elsif($c->CTRL_D)
		{
			undef $value;
			return 0;
		}
		elsif($c->BS)
		{
			print "\b\033[K" if $value;
			chop $value if $value eq $line;
			chop $line;
		}
		elsif($c->TAB and not -f $value)
		{
			@candidates = $filter->(glob "$line*");

			if(@candidates)
			{
				my $prefix = String::Util::longest_common_prefix(@candidates);
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
		elsif($c->CHAR)
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

	CommandLine::Terminal::raw();
	eval
	{
		while(1)
		{
			my $c = CommandLine::Terminal::getchar();
			die "error: reached end of input$/" if $c->NUL;

			last unless $readchar->($c);
		}
	};
	CommandLine::Terminal::normal();

	print "\n";

	die $@ if($@);
	return $value;
}

1
