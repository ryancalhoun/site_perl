require 'rake/testtask'

desc 'Remove build artifacts'
task :clean do
	rm_rf 'dist'
end

desc 'Build sources'
task :build do
	version = File.open('site_perl.version') {|f|
		Hash[f.readlines.map {|line|
			line.chomp.split('=').tap {|a| a[0] = a[0].to_sym}
		}]
	}

	mkdir_p 'dist'
	Dir['src/**'].each {|f|
		next if File.directory?(f)
		File.open(f) {|fin|
			out = File.join('dist', f[4..-1])
			mkdir_p File.dirname(out)
			File.open(out, 'w') {|fout|
				fin.each_line {|line|
					if line =~ /^=head1\sSYNOPSIS/
						fout.puts '=head1 VERSION'
						fout.puts
						fout.puts "  #{version[:version]}"
						fout.puts
					end

					fout.write line	
				}
			}
		}
	}
end

desc 'Run tests'
Rake::TestTask.new {|t|
	t.libs << 'test'
}

task :all => [:clean, :build, :test]
task :default => :all
