require 'test/unit'
require 'open3'
require 'fileutils'

class TestPrompt < Test::Unit::TestCase

	def testString

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../src -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use Prompt IN=>DATA;
				my $s = Prompt::string("> ");
				print "\nGOT $s\n";
				__DATA__
				hello world
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "> \nGOT hello world\n", out
	end

	def testStringPattern

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../src -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use Prompt IN=>DATA;
				my $s = Prompt::string("> ", qr/yes|no/);
				print "\nGOT $s\n";
				__DATA__
				goodbye
				yes
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "> Not understood, try again: \nGOT yes\n", out
	end

	def testFile
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../src -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use Prompt IN=>DATA;
				my $f = Prompt::file("> ");
				print "GOT $f\n";
				__DATA__
				#{__FILE__}
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "> #{__FILE__}\nGOT #{__FILE__}\n", out
	end

	def testFileTab

		FileUtils.mkdir_p 'tmpdir/foo/bar'
		FileUtils.mkdir_p 'tmpdir/fun'

		File.open('tmpdir/foo/bar/file.txt', 'w') {}
		File.open('tmpdir/foo/bar/file.xml', 'w') {}

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../src -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use Prompt IN=>DATA;
				my $f = Prompt::file("> ");
				print "GOT $f\n";
				__DATA__
				tmpdir/	o			t	
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> tmpdir/foo/bar/
			file.txt    file.xml    
			> tmpdir/foo/bar/file.txt 
			GOT tmpdir/foo/bar/file.txt
		END

		assert_equal expected, out

	ensure
		FileUtils.rm_rf 'tmpdir'
	end

	def testFileTabLimit

		FileUtils.mkdir_p 'tmpdir/foo/bar'
		FileUtils.mkdir_p 'tmpdir/fun'

		File.open('tmpdir/foo/bar/file.txt', 'w') {}
		File.open('tmpdir/foo/bar/file.xml', 'w') {}

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../src -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use Prompt IN=>DATA, completion_limit=>1;
				my $f = Prompt::file("> ");
				print "GOT $f\n";
				__DATA__
				tmpdir/		yo			yt	
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> tmpdir/f
			Display all 2 possibilities? (y or n)
			foo/    fun/    
			> tmpdir/foo/bar/
			Display all 2 possibilities? (y or n)
			file.txt    file.xml    
			> tmpdir/foo/bar/file.txt 
			GOT tmpdir/foo/bar/file.txt
		END

		assert_equal expected, out

	ensure
		FileUtils.rm_rf 'tmpdir'
	end

	def left_chomp(str)
		ws = /^\s+/.match(str)
		str.each_line.collect {|line|
			line.sub(/^#{ws}/, '')
		}.join
	end

end

