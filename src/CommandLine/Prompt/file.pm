use strict;
use warnings;

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

	my $reset = "\033[A\n\033[K";
	my $nosuch = sub
	{
		print $reset;
		$reset = "\033[2A\n\033[K";
		print "\033[31;1mError: no such file or directory: $_[0]\033[0m\n";
		print "$p$line";
	};

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
			return 0 if not defined($value) or not length($value) or -e $value;
			$nosuch->($value);
		}
		elsif($c->CTRL_C)
		{
			die "<Ctrl+C>$/" unless defined($value) and length($value);
			undef $value;
			return 0;
		}
		elsif($c->CTRL_D or $c->ESC)
		{
			undef $value;
			return 0;
		}
		elsif($c->BACKSPACE)
		{
			print "\b\033[K" if defined($value) and length($value);
			chop $value if $value eq $line;
			chop $line;
		}
		elsif($c->TAB and not -f $value)
		{
			@candidates = $filter->(glob "$line*");

			if(@candidates)
			{
				my $prefix = String::Util::longest_common_prefix(@candidates);
				my $remainder = substr($prefix, length($line));

				my $update = $value ne substr($prefix, 0, length($value));

				$value = $line = $prefix;

				if(scalar @candidates == 1)
				{
					-f $value
						and map { $_ .= ' ' } $line, $remainder
						or map { $_ .= '/' } $value, $line, $remainder;
					if($update)
					{
						print "\033[A\n\033[K$p$line";
					}
					else
					{
						print $remainder;
					}
				}
				else
				{
					if($prev eq "\t")
					{
						if(scalar @candidates > $CommandLine::Prompt::completion_limit)
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
						if($update)
						{
							print "\033[A\n\033[K$p$line";
						}
						else
						{
							print $remainder;
						}
					}
				}
			}
		}
		elsif($c->CHAR)
		{
			my $part = "$value$c";
			$part .= '*' unless $part eq '~';

			print $c;
			map { $_ .= $c } $line, $value;

			$nosuch->($value) unless($filter->(glob $part));
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
