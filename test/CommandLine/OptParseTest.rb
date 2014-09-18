require 'test/unit'
require 'open3'

class OptParseTest < Test::Unit::TestCase

	def testDefault
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', '--version', 'display version', \\$version);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options]

			     -h --help                   display help
			     -v --version                display version

		END
		assert_equal expected, out

	end 

	def testOption
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - -hv") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', '--version', 'display version', \\$version);
				};
				$opts->(@ARGV);
				print "help $help version $version\n";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "help 1 version 1\n", out

	end 

	def testUnknownOption
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - -q") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', '--version', 'display version', \\$version);
				};
				$opts->(@ARGV);
			END
			stdin.close

			stderr.read
		}

		assert_equal "Unknown option: q\n", out

	end 

	def testShortOnly
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', 'display version', \\$version);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options]

			     -h --help                   display help
			     -v                          display version

		END
		assert_equal expected, out

	end 

	def testLongOnly
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('--version', 'display version', \\$version);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options]

			     -h --help                   display help
			        --version                display version

		END
		assert_equal expected, out

	end 

	def testValues
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-i', '--input FILE', 'input file', \\$in);
					on('-o', '--output=FILE', 'output file', \\$out);
					on('-dDIR', '--directory', 'directory', \\$dir);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options]

			     -i --input FILE             input file
			     -o --output FILE            output file
			     -d --directory DIR          directory

		END
		assert_equal expected, out

	end 

	def testValuesOptions
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - -iinput.txt --output=output.txt -d dir") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-i', '--input FILE', 'input file', \\$in);
					on('-o', '--output=FILE', 'output file', \\$out);
					on('-dDIR', '--directory', 'directory', \\$dir);
				};
				$opts->(@ARGV);
				print "in $in out $out dir $dir\n";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "in input.txt out output.txt dir dir\n", out
	end 

	def testLeftovers
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - -iinput.txt foo bar wow") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program';
				my $opts = CommandLine::OptParse::options {
					on('-i', '--input FILE', 'input file', \\$in);
				};
				my @args = $opts->(@ARGV);
				print "in $in args ", join(',', @args), "\n";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "in input.txt args foo,bar,wow\n", out
	end 

	def testDescription
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program',
					description => 'This is my test program description. It is cool. There are lots of things this program can do.';
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', '--version', 'display version', \\$version);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options]

			     -h --help                   display help
			     -v --version                display version

			DESCRIPTION
			    This is my test program description. It is cool. There are lots of
			    things this program can do.

		END
		assert_equal expected, out

	end 

	def testUsage
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::OptParse
					prog => 'testprog',
					banner => 'A Test Program',
					usage => ['[options] FILE...', 'foo [-c|-w]'];
				my $opts = CommandLine::OptParse::options {
					on('-h', '--help', 'display help', \\$help);
					on('-v', '--version', 'display version', \\$version);
				};
				print "$opts";
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			NAME
			     testprog - A Test Program

			SYNOPSIS
			     testprog [options] FILE...
			     testprog foo [-c|-w]

			     -h --help                   display help
			     -v --version                display version

		END
		assert_equal expected, out

	end 


	def left_chomp(str)
		ws = /^\s+/.match(str)
		str.each_line.collect {|line|
			line.sub(/^#{ws}/, '')
		}.join
	end

end
