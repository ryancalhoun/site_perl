package OptParseTest;

use UnitTest;
use base 'UnitTest';

use OptParse
	prog => "testprog";

sub test_default
{
	my ($this,$name) = @_;

	my $help;
	my $version;

	my $opt = OptParse::options {
		on('-h', '--help', "display help", \$help);
		on('-v', '--version', "display version", \$version);
	};

	is("$opt", "", $name);
}

