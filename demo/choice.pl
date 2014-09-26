use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my $value = CommandLine::Prompt::choice("Are you ready for some football?", "Yes", "No", "Maybe");
print "You are $value ready\n";
