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

sub test_short_only
{
	my ($this,$name) = @_;

	my $help;
	my $version;

	my $opt = OptParse::options {
		on('-h', '--help', "display help", \$help);
		on('-v', "display version", \$version);
	};

my $expected =<<END;
NAME
    testprog - A Test Program

SYNOPSIS
    testprog [options]

     -h --help                   display help
     -v                          display version

END

	is("$opt", $expected, $name);
}

sub test_long_only
{
	my ($this,$name) = @_;

	my $help;
	my $version;

	my $opt = OptParse::options {
		on('-h', '--help', "display help", \$help);
		on('--version', "display version", \$version);
	};

my $expected =<<END;
NAME
    testprog - A Test Program

SYNOPSIS
    testprog [options]

     -h --help                   display help
        --version                display version

END

	is("$opt", $expected, $name);
}

sub test_values
{
	my ($this,$name) = @_;

	my $help;
	my $version;
	my $file;

	my $opt = OptParse::options {
		on('-h', '--help', "display help", \$help);
		on('-v', '--version', "display version", \$version);
		on('-f', '--file=FILE', "input file", \$file);
	};

my $expected =<<END;
NAME
    testprog - A Test Program

SYNOPSIS
    testprog [options]

     -h --help                   display help
     -v --version                display version
     -f --file FILE              input file

END

	is("$opt", $expected, $name);

	my @argv = ('-fmyfile.txt');
	$opt->(@argv);

	is('myfile.txt', $file, $name);
}

