package String::Util;

use strict;
use warnings;

=head1 NAME

  String::Util - string manipulation utilities

=head1 SYNOPSIS

  use String::Util;

  my $prefix = String::Util::longest_common_prefix("ale", "all", "alt"); # returns "al"

=head1 METHODS

=over 4

=item String::Util::longest_common_prefix @candidates

Find the longest prefix common to all candidate strings.

=back

=cut

sub longest_common_prefix
{
	my $p = shift;
	for(@_) { chop $p while(!/^\Q$p\E/); }
	$p;
}

1
