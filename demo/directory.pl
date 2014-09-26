use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my $dir = CommandLine::Prompt::directory("Pick a directory: ");
print "You chose $dir\n";
