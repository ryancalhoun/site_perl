use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my $value = CommandLine::Prompt::choice("Ready to launch missles?",
	"Yes",
	"No",
	"Maybe");

if($value eq "Yes")
{
	print "Fire!\n";
}
elsif($value eq "No")
{
	print "Dang, I was all ready.\n";
}
else
{
	print "Make up your mind already.\n";
}
