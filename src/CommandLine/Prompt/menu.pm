sub _name
{
	ref($_[0]) eq 'HASH' ? $_[0]->{name} : $_[0];
};

sub _menu_basic_impl
{
	my ($multi,$p,@values) = @_;

	print "$p$/";
	my @result;
	my $label = sub {
		my $i = shift;
		if(ref($values[$i]) eq 'HASH')
		{
			$values[$i]->{name} . " (enter \"" . ($i+1) . "*\" to expand)";
		}
		else
		{
			$values[$i]
		}
	};
	while(1)
	{
		printf "  %2d %s$/", $_+1, $label->($_) for 0..$#values;
		my $exp;

		if($multi)
		{
			$exp = qr/^([\d\-,\s]+)$/;
			print "Enter range (e.g. 1,2,4-6), or type [A]ll, or [n]one: ";
		}
		else
		{
			$exp = qr/^(\d+)(\*)?$/;
			print "Choose number, or ENTER to skip: ";
		}

		my $n = getline();

		@result = @values if $multi and $n =~ /^a/i;
		last if ($multi and (not $n or $n =~ /^(n|a)/i)) or (not $multi and not $n);

		my @m = $n =~ $exp;

		my @nums = map {
			my ($i,$j) = split /\s*-\s*/;
			$i-1..($j || $i)-1;
		} split /\s*,\s*/, $m[0];

		if(my @out = grep { $_ < 0 or $_ > $#values } @nums)
		{
			print "'", join(',', map {$_+1} @out), "' is not a valid choice, try again:\n";
			next;
		}

		if($m[1])
		{
			if(ref($values[$nums[0]]) ne 'HASH')
			{
				print "Cannot expand choice $nums[0], try again:\n";
				next;
			}
			@values = @{$values[$i-1]->{values}};
			next;
		}

		@result = map { _name($values[$_]); } @nums;

		last;
	}

	$multi ? @result : $result[0];
}

sub _menu_term_impl
{
	my ($multi,$p,@values) = @_;

	my $rows = 10;
	my @item = (0);
	my @pos = (0);
	my $depth = 0;

	my $reset;
	my $line = '';
	my %value;

	my $limit;
	$limit = sub {
		my ($d,$v,$x) = @_;

		$v ||= \@values;
		$x ||= $d;

		if($d == 0)
		{
			return scalar(@$v);
		}
		else
		{
			return $limit->($d-1, $v->[$item[$x-$d]]->{values}, $x);
		}
	};

	my $width;
	$width = sub {
		my ($d,$v,$x) = @_;

		$v ||= \@values;
		$x ||= $d;

		if($d == 0)
		{
			return (sort { $a <=> $b }  map { length(_name($_)) } @$v)[-1] + 6;
		}
		else
		{
			return $width->($d-1, $v->[$item[$x-$d]]->{values}, $x);
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
		my ($d,$i,$v,$x) = @_;

		$v ||= \@values;
		$x ||= $d;

		if($d == 0)
		{
			my $selected = $value{join(',', @item[0..$x-1], $i)};
			if(ref($v->[$i]) eq 'HASH')
			{
				if($selected)
				{
					"[$v->[$i]->{name}]...";
				}
				else
				{
					" $v->[$i]->{name} ...";
				}

			}
			elsif($selected)
			{
				"[$v->[$i]]";
			}
			else
			{
				" $v->[$i]";
			}
		}
		else
		{
			return $label->($d-1, $i, $v->[$item[$x-$d]]->{values}, $x);
		}
	};

	my $get_value;
	$get_value = sub {
		my $v = \@values;
		for(@_)
		{
			$v = $v->{values} if ref($v) eq 'HASH';
			return undef unless ref($v) eq 'ARRAY';
			$v = $v->[$_];
		}

		$v;
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
							printf " \033[7;1m %2d %-${w}s   \033[0m", $i + 1, $text;
						}
						else
						{
							printf " \033[37;40m %2d %-${w}s   \033[0m", $i + 1, $text;
						}
					}
					else
					{
						printf "  %2d %-${w}s   ", $i + 1, $text;
					}
				}
				else
				{
					print " " x ($w + 8);
				}
			}

			print "\n";
		}

		for(0..$depth)
		{
			my $w = $width->($_);
			if($pos[0] + $rows < $limit->($_))
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

			last if $ch->CTRL_C;

			my $key = join(',', @item[0..$depth]);

			if($ch->ENTER)
			{
				$value{$key} = 1 unless $multi;
				last;
			}
			elsif($ch->ESC or $ch =~ /q/i)
			{
				%value = ();
				$item[$depth] = -1;
				last;
			}
			elsif($ch eq " " and $multi)
			{
				$value{$key} = not $value{$key};
			}
			elsif($ch->CTRL_A and $multi)
			{
				$value{$_} = 1 for map {
					join(',', @item[0..$depth-1], $_)
				} 0..$limit->($depth);
			}
			elsif($ch->CTRL_N and $multi)
			{
				$value{$_} = 0 for map {
					join(',', @item[0..$depth-1], $_)
				} 0..$limit->($depth);
			}
			elsif($ch->UP)
			{
				if($item[$depth] > 0)
				{
					--$item[$depth];
				}
			}
			elsif($ch->DOWN)
			{
				if($item[$depth] < $limit->($depth) - 1)
				{
					++$item[$depth];
				}
			}
			elsif($ch->RIGHT)
			{
				if(ref($selected->()) eq 'HASH')
				{
					++$depth;
					$line = '';
				}
			}
			elsif($ch->LEFT)
			{
				if($depth > 0)
				{
					$item[$depth--] = 0;
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
			elsif($ch->BS)
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

	my @result = map { _name($get_value->(split /,/)); } sort {
		my @ai = split /,/, $a;
		my @bi = split /,/, $b;

		my $len = $#ai;
		$len = $#bi if $#bi > $#ai;

		for(0..$len)
		{
			return -1 if $#ai < $len;
			return 1 if $#bi < $len;

			my $c = $ai[$_] <=> $bi[$_];
			return $c unless $c == 0;
		}

		return 0;

	} grep { $value{$_} } keys %value;
	$multi ? @result : $result[0];
}

1

