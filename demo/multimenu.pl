use File::Basename;
use lib dirname($0) . '/../src';
use CommandLine::Prompt;

my @values = CommandLine::Prompt::multimenu("Select toppings: ",
	'Lettuce',
	'Tomato',
	'Pickles',
	'Onions',
	'Ketchup',
	'Mustard',
);

print scalar(@values), "\n";
print "You selected ", join(', ', @values), "\n";
