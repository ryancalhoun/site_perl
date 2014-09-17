package CommandLine::Prompt;

use strict;
use warnings;

=head1 NAME

  CommandLine::Prompt - manage a variety of user prompt scenarios

=head1 SYNOPSIS

  use CommandLine::Prompt;

  my $name = CommandLine::Prompt::string("Name: ");
  my $age = CommandLine::Prompt::string("Age: ", qr/^\d+/);
  my $image = CommandLine::Prompt::file("Selfie: ");

=head1 METHODS

=over 4

=item CommandLine::Prompt::string $prompt_text, $pattern

Display prompt text and return result. If $pattern is given, the response must match it, or
the prompt will loop until satisfied.

=item CommandLine::Prompt::file $prompt_text

Display prompt text and return a valid filename. If the input handle (STDIN) can be put into raw mode,
provide a tab-complete semantic to navigate existing filenames.

=item CommandLine::Prompt::directory $prompt_text

Display prompt text and return a valid directory name. If the input handle (STDIN) can be put into raw mode,
provide a tab-complete. Non-directories are filtered out of tab-complete candidates.

=back

=cut

use List::Util;
use File::Basename;

our $IN = *STDIN;
our $completion_limit = 100;

sub import
{
	my $pkg = shift;
	my %cfg = @_;

	my $caller = (caller)[0];

	no strict 'refs';

	$IN = *{$caller . '::' . $_} for grep { defined } $cfg{IN};
	$completion_limit = $_ for grep { defined } $cfg{completion_limit};

	my $handle = (split(/::/, $IN))[-1];
	*{$handle} = $IN;

	require CommandLine::Terminal;
	CommandLine::Terminal->import(IN=>$handle);

	*complete_file = CommandLine::Terminal::supports_raw() ? \&complete_file_term : \&complete_file_basic;
}

sub string
{
	my ($p,$exp) = @_;

	print $p;
	my $value;
	while(1)
	{
		chomp($value = <$IN>);
		if($value and $exp and $value !~ $exp)
		{
			print "Not understood, try again: ";
			next;
		}
		last;
	}
	$value;
}

sub file
{
	my $f = complete_file(@_);
}

sub directory
{
	my $f = complete_file(@_, sub { grep { -d } @_ });
}

sub complete_file_basic
{
	chomp(my $value = <$IN>);
	return $value;
}

sub complete_file_term
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
			@candidates = $filter->(glob "$line*");

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
			last unless ord($c) and $readchar->($c);
		}
	};
	CommandLine::Terminal::normal();

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
