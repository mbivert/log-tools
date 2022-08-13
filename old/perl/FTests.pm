package FTests;

use strict;
use warnings;

# Test::Deep::cmp_deeply() would be slightly better
# than Test::More::is_deeply(), but Test::More comes
# with a default perl(1) installation.
use Test::More;

use B;

# Retrieve a name for a coderef.
#
# See https://stackoverflow.com/a/7419346
#
# Input:
#	$_[0] : coderef
# Output:
#	string, generally module::fn
sub getsubname {
	my ($f) = @_;

	my $cv = B::svref_2object($f) or return "";
	return "" unless $cv->isa('B::CV');
	my $gv = $cv->GV or return "";

	my $n = '';
	if (my $st = $gv->STASH) {
		$n = $st->NAME . '::';
	}

	if ($gv->NAME) {
		$n .= $gv->NAME . '()';
	}

	return $n;
}

# A test is encoded as a hashref containing:
#
# {
#	"f"        => \&function_pointer,
#	"fn"       => $optional_function_name,
#	"args"     => $arrayref_holding_input_arguments,
#	"expected" => $expected_output_values
#	"descr"    => "Test description, string",
# }

# Run a single test.
#
# Input:
#	$1 : hashref describing the test (see above)
# Output:
#	Boolean: 1 if the test was successfully executed,
#	0 otherwise.
#
#	May die().
sub run1 {
	my ($test) = @_;

	my (
		$f,
		$fn,
		$args,
		$expected,
		$descr,
	) = @{$test}{qw(f fn args expected descr)};

	my $n = $fn || FTests::getsubname($f);

	# NOTE: We could manage exceptions
	return Test::More::is_deeply(
		$f->(@$args),
		$expected,
		sprintf("% -35s: %s", $n, $descr),
	);
}

# Run a list of tests in order, stopping in case of
# failure.
#
# Input:
#	$1 : arrayref of tests
# Output:
#	Boolean: 1 if all tests were successfully executed,
#	0 otherwise.
#
#	May die().
sub run {
	my ($tests) = @_;

	foreach my $test (@$tests) {
		return 0 unless(FTests::run1($test));
	}

	return 1;
}

1;
