require 'test/unit'
require 'open3'
require 'fileutils'

class PromptTest < Test::Unit::TestCase

	def testString

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $s = CommandLine::Prompt::string("> ");
				print "GOT $s\n";
				__DATA__
				hello world
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "> hello world\nGOT hello world\n", out
	end

	def testStringPattern

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $s = CommandLine::Prompt::string("> ", qr/yes|no/);
				print "GOT $s\n";
				__DATA__
				goodbye
				yes
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		assert_equal "> goodbye\nNot understood, try again: yes\nGOT yes\n", out
	end

	def testFile
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::file("> ");
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

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::file("> ");
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
			file.txt\\s+file.xml\\s+
			> tmpdir/foo/bar/file.txt 
			GOT tmpdir/foo/bar/file.txt
		END

		assert_match /#{expected}/, out

	ensure
		FileUtils.rm_rf 'tmpdir'
	end

	def testFileTabLimit

		FileUtils.mkdir_p 'tmpdir/foo/bar'
		FileUtils.mkdir_p 'tmpdir/fun'

		File.open('tmpdir/foo/bar/file.txt', 'w') {}
		File.open('tmpdir/foo/bar/file.xml', 'w') {}

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA, completion_limit=>1;
				my $f = CommandLine::Prompt::file("> ");
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
			Display all 2 possibilities\\? \\(y or n\\)
			foo/\\s+fun/\\s+
			> tmpdir/foo/bar/
			Display all 2 possibilities\\? \\(y or n\\)
			file.txt\\s+file.xml\\s+
			> tmpdir/foo/bar/file.txt 
			GOT tmpdir/foo/bar/file.txt
		END

		assert_match /#{expected}/, out

	ensure
		FileUtils.rm_rf 'tmpdir'
	end

	def testDirectoryTab

		FileUtils.mkdir_p 'tmpdir/foo/bar'
		FileUtils.mkdir_p 'tmpdir/fun'

		File.open('tmpdir/file.txt', 'w') {}
		File.open('tmpdir/foo/back.txt', 'w') {}

		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::directory("> ");
				print "GOT $f\n";
				__DATA__
				tmpdir/		o		
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> tmpdir/f
			foo/\\s+fun/\\s+
			> tmpdir/foo/bar/
			GOT tmpdir/foo/bar/
		END

		assert_match /#{expected}/, out

	ensure
		FileUtils.rm_rf 'tmpdir'
	end

	def testMenu
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::menu("> ", "one", "two", "three");
				print "GOT $f\n";
				__DATA__
				\033[B\033[B
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> 
			\e[K \e[7;1m  1  one          \e[0m
			\e[K   2  two          
			\e[K   3  three        
			\e[K                   
			                    
			\e[KUse UP/DOWN to select, ENTER to choose, ESC to skip: \e[53D\e[5A\e[K   1  one          
			\e[K \e[7;1m  2  two          \e[0m
			\e[K   3  three        
			\e[K                   
			                    
			\e[KUse UP/DOWN to select, ENTER to choose, ESC to skip: \e[53D\e[5A\e[K   1  one          
			\e[K   2  two          
			\e[K \e[7;1m  3  three        \e[0m
			\e[K                   
			                    
			\e[KUse UP/DOWN to select, ENTER to choose, ESC to skip: \e[53D\e[KGOT three
		END

		assert_equal expected, out
	end

	def testSubMenu
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::menu("> ", "one", "two", {name=>"three",values=>["four", "five"]});
				print "GOT $f\n";
				__DATA__
				\033[B\033[B\033[B\033[C\033[B
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> 
			\e[K \e[7;1m  1  one          \e[0m
			\e[K   2  two          
			\e[K   3  three ...    
			\e[K                   
			                    
			\e[KUse UP/DOWN to select, ENTER to choose, ESC to skip: \e[53D\e[5A\e[K   1  one          
			\e[K \e[7;1m  2  two          \e[0m
			\e[K   3  three ...    
			\e[K                   
			                    
			\e[KUse UP/DOWN to select, ENTER to choose, ESC to skip: \e[53D\e[5A\e[K   1  one          
			\e[K   2  two          
			\e[K \e[7;1m  3  three ...    \e[0m
			\e[K                   
			                    
			\e[KUse UP/DOWN/LEFT/RIGHT to select, ENTER to choose, ESC to skip: \e[64D\e[5A\e[K   1  one          
			\e[K   2  two          
			\e[K \e[7;1m  3  three ...    \e[0m
			\e[K                   
			                    
			\e[KUse UP/DOWN/LEFT/RIGHT to select, ENTER to choose, ESC to skip: \e[64D\e[5A\e[K   1  one           \e[7;1m  1  four        \e[0m
			\e[K   2  two             2  five        
			\e[K \e[37;40m  3  three ...    \e[0m                  
			\e[K                                     
			                                       
			\e[KUse UP/DOWN/LEFT/RIGHT to select, ENTER to choose, ESC to skip: \e[64D\e[5A\e[K   1  one             1  four        
			\e[K   2  two           \e[7;1m  2  five        \e[0m
			\e[K \e[37;40m  3  three ...    \e[0m                  
			\e[K                                     
			                                       
			\e[KUse UP/DOWN/LEFT/RIGHT to select, ENTER to choose, ESC to skip: \e[64D\e[KGOT five
		END

		assert_equal expected, out

	end

	def testMultiMenu
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my @f = CommandLine::Prompt::multimenu("> ", "one", "two", "three");
				print "GOT @f\n";
				__DATA__
				\033[B \033[B 
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			> 
			\e[K \e[7;1m  1  one          \e[0m
			\e[K   2  two          
			\e[K   3  three        
			\e[K                   
			                    
			\e[KUse UP/DOWN and SPACE to select, ENTER to accept: \e[50D\e[5A\e[K   1  one          
			\e[K \e[7;1m  2  two          \e[0m
			\e[K   3  three        
			\e[K                   
			                    
			\e[KUse UP/DOWN and SPACE to select, ENTER to accept: \e[50D\e[5A\e[K   1  one          
			\e[K \e[7;1m  2 [two]         \e[0m
			\e[K   3  three        
			\e[K                   
			                    
			\e[KUse UP/DOWN and SPACE to select, ENTER to accept: \e[50D\e[5A\e[K   1  one          
			\e[K   2 [two]         
			\e[K \e[7;1m  3  three        \e[0m
			\e[K                   
			                    
			\e[KUse UP/DOWN and SPACE to select, ENTER to accept: \e[50D\e[5A\e[K   1  one          
			\e[K   2 [two]         
			\e[K \e[7;1m  3 [three]       \e[0m
			\e[K                   
			                    
			\e[KUse UP/DOWN and SPACE to select, ENTER to accept: \e[50D\e[KGOT two three
		END

		assert_equal expected, out
	end

	def testChoice
		out = Open3.popen3("perl -I#{File.dirname(__FILE__)}/../../dist -") {|stdin,stdout,stderr,th|
			stdin.puts left_chomp(<<-END)
				use CommandLine::Prompt IN=>DATA;
				my $f = CommandLine::Prompt::choice("Ready? ", "yes", "no", "maybe");
				print "GOT $f\n";
				__DATA__
				\033[C\033[C 
	
			END
			stdin.close

			STDERR.write stderr.read

			stdout.read
		}

		expected = left_chomp(<<-END)
			Ready?  \e[7;1m   \e[4my\e[24mes   \e[0m    \e[4mn\e[24mo       \e[4mm\e[24maybe   
			\e[A\e[7C\e[K    \e[4my\e[24mes    \e[7;1m   \e[4mn\e[24mo   \e[0m    \e[4mm\e[24maybe   
			\e[A\e[7C\e[K    \e[4my\e[24mes       \e[4mn\e[24mo    \e[7;1m   \e[4mm\e[24maybe   \e[0m
			\e[A\e[7C\e[K    \e[4my\e[24mes       \e[4mn\e[24mo    \e[7;1m   \e[4mm\e[24maybe   \e[0m
			GOT maybe
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

