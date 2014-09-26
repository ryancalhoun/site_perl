use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my $file = CommandLine::Prompt::file("Pick a file: ");
print "You chose $file\n";
