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
  my $item = CommandLine::Prompt::menu("Pick: ", "water", "beer");

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

=item CommandLine::Prompt::menu $prompt_text, @values

Display prompt text and numbered menu values. If the input handle (STDIN) can be put into raw mode,
show a highlighted menu navigable with arrow keys.

=back

=cut

use List::Util;
use File::Basename;
use String::Util;

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
	CommandLine::Terminal->import(map { $_ => $cfg{$_} } grep { /IN/ } keys %cfg);

	*complete_file = CommandLine::Terminal::supports_raw() ? \&complete_file_term : \&complete_file_basic;
	*getline = CommandLine::Terminal::supports_raw() ? \&getline_term : \&getline_basic;
	*menu = CommandLine::Terminal::supports_raw() ? \&menu_term : \&menu_basic;
	*multimenu = CommandLine::Terminal::supports_raw() ? \&multimenu_term : \&multimenu_basic;
}

sub string
{
	my ($p,$exp) = @_;

	print $p;
	my $value;
	while(1)
	{
		$value = getline();
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

require 'CommandLine/Prompt/menu.pm';
sub menu_basic
{
	_menu_basic_impl(0, @_);
}

sub menu_term
{
	_menu_term_impl(0, @_);
}

sub multimenu_basic
{
	_menu_basic_impl(1, @_);
}

sub multimenu_term
{
	_menu_term_impl(1, @_);
}
sub getline_basic
{
	chomp(my $value = <$IN>);
	$value;
}

require 'CommandLine/Prompt/line.pm';
sub getline_term
{
	_getline_term_impl(@_);
}

sub complete_file_basic
{
	chomp(my $value = <$IN>);
	return $value;
}

require 'CommandLine/Prompt/file.pm';
sub complete_file_term
{
	_complete_file_term_impl(@_);
}

1
