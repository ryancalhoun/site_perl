package prompt;

use strict;
use warnings;

use Term::ReadKey;
use List::Util;
use File::Basename;

sub file
{
	my $p = shift;

	print $p;
	my $line = '';
	my $value = '';
	my $prev = '';
	my @candidates;

	my $readchar;

	my $showall = sub
	{
		my @f = map { -d $_ ? basename($_) . '/' : basename($_) } @candidates;

		my ($termwidth) = Term::ReadKey::GetTerminalSize();
		my $textwidth = (List::Util::max map { length($_) } @f) + 4;

		my $cols = int($termwidth / $textwidth);
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

	my $readpath = sub
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
			@candidates = glob "$line*";

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
						if(scalar @candidates > 100)
						{
							print "\nDisplay all ", scalar @candidates, " possibilities? (y or n)";
							$readchar = \&read_yn;
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

	my $read_yn = sub
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

	Term::ReadKey::ReadMode(4);
	eval
	{
		while(1)
		{
			my $c = Term::ReadKey::ReadKey(0);
			last unless $readchar->($c);
		}
	};
	Term::ReadKey::ReadMode(1);

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
