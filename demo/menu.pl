use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my $value = CommandLine::Prompt::menu("Choose language: ",
	'ADA',
	'bash',
	'C',
	{name=>'C++', values=>['C++98', 'C++11']},
	{name=>'Java', values=>['Java 1.5', 'Java 1.6', 'Java 1.7', 'Java 1.8']},
	'Matlab',
	'Haskell',
	{name=>'Ruby', values=>[
		{name=>'Matz Ruby', values=>['Ruby 1.8', 'Ruby 1.9', 'Ruby 2.0', 'Ruby 2.1']},
		{name=>'JRuby', values=>['JRuby 1.6', 'JRuby 1.7']},
		{name=>'Rubinius', values=>['Rubinius 2.0', 'Rubinius 2.1', 'Rubinius 2.2']},
	]},
	{name=>'Perl', values=>['Perl 5.8', 'Perl 5.10', 'Perl 5.16']},
	{name=>'Python', values=>['Python 2.7', 'Python 3.4']},
	'ML',
	'FORTRAN',
	{name=>'COBAL', values=>['COBOL-60', 'COBOL-61', 'COBOL-68', 'COBOL-74', 'COBOL-85', 'COBOL 2002']},
	'R',
	'Whitespace',
);

print "You selected \"$value\"\n";
