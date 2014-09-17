require 'test/unit'
require 'open3'

class UtilTest < Test::Unit::TestCase

	def testLongestCommonPrefix

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - allover allone allout allof") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use String::Util;
				print String::Util::longest_common_prefix(@ARGV);
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "allo", out

	end

	def testLongestCommonPrefix_None

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist - apple banana") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use String::Util;
				print String::Util::longest_common_prefix(@ARGV);
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "", out

	end

	def left_chomp(str)
		ws = /^\s+/.match(str)
		str.each_line.collect {|line|
			line.sub(/^#{ws}/, '')
		}.join
	end

end

