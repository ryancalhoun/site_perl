
sub _menu_term_impl
{
	my ($p,@values) = @_;

	my $rows = 10;
	my @item = (0);
	my @pos = (0);
	my $depth = 0;

	my $reset;
	my $line = '';
	my $value;

	my $limit;
	$limit = sub {
		my ($d,$v) = @_;

		$v ||= \@values;

		if($d == 0)
		{
			return scalar(@$v);
		}
		else
		{
			return $limit->($d-1, $v->[$item[$depth-$d]]->{values});
		}
	};

	my $width;
	$width = sub {
		my ($d,$v) = @_;

		$v ||= \@values;

		if($d == 0)
		{
			return (sort { $a <=> $b }  map { length(ref($_) eq 'HASH' ? $_->{name} : $_) } @$v)[-1] + 4;
		}
		else
		{
			return $width->($d-1, $v->[$item[$depth-$d]]->{values});
		}
	};

	my $height;
	$height = sub {
		my ($d,$v) = @_;

		$d ||= 0;
		$v ||= \@values;

		(sort { $a <=> $b } (scalar(@$v), map { $height->($d+1, $_->{values}) } grep { ref($_) eq 'HASH' } @$v))[-1];
	};

	my $label;
	$label = sub {
		my ($d,$i,$v) = @_;

		$v ||= \@values;

		if($d == 0)
		{
			return ref($v->[$i]) eq 'HASH' ? $v->[$i]->{name} . " ..." : $v->[$i];
		}
		else
		{
			return $label->($d-1, $i, $v->[$item[$depth-$d]]->{values});
		}
	};

	my $selected;
	$selected = sub {
		my ($d,$v) = @_;

		$d = $depth unless defined $d;
		$v ||= \@values;

		return undef if $item[$depth - $d] < 0;

		if($d == 0)
		{
			return $v->[$item[$depth - $d]];
		}
		else
		{
			return $selected->($d-1, $v->[$item[$depth - $d]]->{values});
		}
	};

	my $set_column_positions = sub {
		for(0..$depth)
		{
			$item[$_] ||= 0;
			$pos[$_] ||= 0;
			if($item[$_] > $pos[$_] + ($rows - 2) && $item[$_] < $limit->($_))
			{
				$pos[$_] = $item[$_] - ($rows - 2);
			}
			elsif($item[$_] <= $pos[$_] && $item[$_] >= 0)
			{
				if($item[$_] <= 0)
				{
					$pos[$_] = 0;
				}
				else
				{
					$pos[$_] = $item[$_] - 1;
				}
			}
		}
	};

	my $display = sub {
		if($reset)
		{
			print $reset;
		}
		else
		{
			$reset = sprintf "\033[%dA", ($rows + 1);
		}

		$set_column_positions->();

		for(0..$rows-1)
		{
			print "\033[K";

			my $x = $_;

			for(0..$depth)
			{
				my $d = $_;
				my $w = $width->($d);
				my $i = $pos[$d] + $x;

				if($i >= 0 and $i < $limit->($d))
				{
					my $text = $label->($d, $i);
					if($i == $item[$d])
					{
						if($d == $depth)
						{
							printf " \033[7;1m %2d  %-${w}s   \033[0m", $i + 1, $text;
						}
						else
						{
							printf " \033[37;40m %2d  %-${w}s   \033[0m", $i + 1, $text;
						}
					}
					else
					{
						printf "  %2d  %-${w}s   ", $i + 1, $text;
					}
				}
				else
				{
					print " " x ($w + 9);
				}


			}

			print "\n";
		}

		for(0..$depth)
		{
			my $w = $width->($_);
			if($pos[0] + 9 < $limit->($_))
			{
				print "      ...", " " x ($w);
			}
			else
			{
				print " " x ($w + 9);
			}
		}

		print "\n";

		my $status;

		if($depth > 0 or ref($selected->()) eq 'HASH')
		{
			$status = "Use UP/DOWN/LEFT/RIGHT to select, ENTER to choose, ESC to skip: ";
		}
		else
		{
			$status = "Use UP/DOWN to select, ENTER to choose, ESC to skip: ";
		}

		my $msg = $status . $line;
		printf "\033[K%s\033[%dD", $msg, length($msg);
	};

	my $h = $height->();
	$rows = $h + 1 if($h < $rows);

	print "$p\n";
	$display->();

	CommandLine::Terminal::raw();
	eval
	{
		while(1)
		{
			my $ch = CommandLine::Terminal::getchar();

			last if ord($ch) == 3;

			if($ch eq "\n")
			{
				$value = $selected->();
				$value = $value->{name} if ref($value) eq 'HASH';
				last;
			}
			elsif($ch =~ /q/i)
			{
				$item[$depth] = -1;
				last;
			}
			elsif(ord($ch) == 27)
			{
				$ch = CommandLine::Terminal::getchar(0.1);
				unless(defined $ch)
				{
					last;
				}

				if(ord($ch) == 91)
				{
					$ch = CommandLine::Terminal::getchar();
					if(ord($ch) == 65)
					{
						if($item[$depth] > 0)
						{
							--$item[$depth];
						}
					}
					elsif(ord($ch) == 66)
					{
						if($item[$depth] < $limit->($depth) - 1)
						{
							++$item[$depth];
						}
					}
					elsif(ord($ch) == 67)
					{
						if(ref($selected->()) eq 'HASH')
						{
							++$depth;
							$line = '';
						}
					}
					elsif(ord($ch) == 68)
					{
						if($depth > 0)
						{
							$item[$depth--] = 0;
						}
					}
				}
			}
			elsif($ch =~ /\d/)
			{
				$line .= $ch;
				if($line > 0)
				{
					$item[$depth] = $line - 1;
				}
			}
			elsif(ord($ch) == 8 or ord($ch) == 127)
			{
				chop $line;
				$item[$depth] = int($line || 0) - 1;
			}
			$display->();
		}
	};
	CommandLine::Terminal::normal();

	print "\n";

	die $@ if $@;

	$value;
}

1

