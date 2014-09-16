package OptParseTest;

use UnitTest;
use base 'UnitTest';

use OptParse
	prog => "testprog",
	banner => "A Test Program";

sub test_default
{
	my ($this,$name) = @_;

	my $help;
	my $version;

	my $opt = OptParse::options {
		on('-h', '--help', "display help", \$help);
		on('-v', '--version', "display version", \$version);
	};

my $expected =<<END;
NAME
    testprog - A Test Program

SYNOPSIS
    testprog [options]

     -h --help                   display help
     -v --version                display version

END

	is("$opt", $expected, $name);
}

