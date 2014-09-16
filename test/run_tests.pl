#!/usr/bin/env perl

use 5.008005;
use strict;
use warnings;

my $dirname;

BEGIN
{
	use Carp;
	use Cwd qw(abs_path cwd);
	use Getopt::Long qw(:config bundling);
	use File::Basename;

	$dirname = dirname($0);
	unshift @INC, abs_path("$dirname/../src"), abs_path("$dirname/common");
}

use UnitTest;

my %opt = ();
Getopt::Long::GetOptions(
	'x|xml=s'=>\$opt{xml},
);

run_suites($dirname, $opt{xml});

sub run_suites
{
	my ($dirname,$xml) = @_;

	opendir my $dir, $dirname or die "Failed to read test directory: $dirname";
	my @suites = sort grep { !/^(\.|common$)/ and -d "$dirname/$_" } readdir $dir;

	closedir $dir;

	unshift @suites, '.';

	my $results = {};
	$results->{"$dirname/$_"} = run_suite($dirname, $_) for @suites;

	report_results($results, $xml);
}

sub run_suite
{
	my ($dirname,$suitename) = @_;

	my $old = cwd;
	chdir "$dirname/$suitename";

	local $@;
	my $suite_results = eval { run_tests($dirname, $suitename) };
	print STDERR $@ if $@;

	chdir $old;

	$suite_results;
}

sub run_tests
{
	my ($dirname,$suitename) = @_;

	opendir my $dir, "." or die "Failed to read test suite directory: $dirname/$suitename";
	my @tests = sort grep { /[tT]est.*\.pm/ } readdir $dir;
	closedir $dir;

	print "Running suite '$dirname/$suitename'\n";

	for(@tests)
	{
		local $0 = $_;
		eval { require $_ }
		or print STDERR "Failed to load test $_\n";
	}

	my @packages = grep {eval { $_->isa('UnitTest')} and $_ ne 'UnitTest'} map { /(\w+)::/; $1} keys %main::;

	my $suite_results = {
		tests    => 0,
		asserts  => 0,
		failures => 0,
		errors   => 0,
		elapsed  => 0,
	};

	for(@packages)
	{
		local $@;
		my $test_results = eval { run_test($_) };
		if($@)
		{
			print STDERR $@;
			++$suite_results->{errors};
		}
		delete $main::{"${_}::"};

		$suite_results = add($suite_results, $test_results);
	}

	my $message = ($suite_results->{errors} + $suite_results->{failures})
		? "FAILED ($suite_results->{errors} errors $suite_results->{failures} failures)"
		: "OK ($suite_results->{tests} tests $suite_results->{asserts} asserts)";

	printf "$/$message Time: %.6f seconds$/$/$/", $suite_results->{elapsed};

	$suite_results;
}

sub run_test
{
	my ($testname) = @_;

	print "Test $testname:$/";
	my $test = $testname->new($testname);
	#$test->quiet;
	my $results = $test->run;

	my $sum = {
		tests    => scalar keys %$results,
		asserts  => 0,
		failures => 0,
		errors   => 0,
		elapsed  => 0,
	};

	while(my ($name,$result) = each %$results)
	{
		if($result->failure)
		{
			++$sum->{failures};
		}
		elsif($result->error)
		{
			++$sum->{errors};
		}
		$sum->{asserts} += $result->asserts_passed;
		$sum->{elapsed} += $result->elapsed;
	}

	$sum;
}

sub report_results
{
	my ($results,$xml) = @_;

	my $total_results = {
		tests    => 0,
		asserts  => 0,
		failures => 0,
		errors   => 0,
		elapsed  => 0,
	};

	my @xml_summary;
	while(my ($suite,$results) = each %$results)
	{
		$total_results = add($total_results, $results);
		push @xml_summary, join(' ', "<testsuite",
		                                 sprintf("name=\"%s\"", abs_path($suite)),
		                                 sprintf("time=\"%.6f\"", $results->{elapsed}),
		                                 "tests=\"$results->{tests}\"",
		                                 "asserts=\"$results->{asserts}\"",
		                                 "failures=\"$results->{failures}\"",
	                                     "errors=\"$results->{errors}\"",
		                             ">$/</testsuite>$/") if $xml;
	}

	if($xml)
	{
		open my $results_file, ">$xml" or warn "Failed to open results file $xml$/";
		printf $results_file "<run_perl_tests total_time=\"%.6f\">$/", $total_results->{elapsed};
		print $results_file $_ for @xml_summary;
		print $results_file "</run_perl_tests>$/";
		close $results_file;
	}

	print  "______________________________________________$/";
	print  "### Total Tests   :  $total_results->{tests}$/";
	print  "### Total Asserts :  $total_results->{asserts}$/";
	print  "### Total Failures:  $total_results->{failures}$/";
	print  "### Total Errors  :  $total_results->{errors}$/";
	printf "### Total Seconds :  %.6f$/", $total_results->{elapsed};
}

sub add
{
	my ($a,$b) = @_;
	my %c = %$a;
	$c{$_} += $b->{$_} for keys %$b;
	\%c;
}



