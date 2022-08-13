#!/usr/bin/perl

use strict;
use warnings;

# NOTE:
#	dirname(__FILE__) == "." => dirname(dirname(__FILE__)) eq "."
# FindBin works better and still is standard.
use FindBin qw($Bin);
use lib "$Bin/../";

use Test::More;
use FTests;

require "analogtag";

# ./data contains some test files
my $datad = File::Basename::dirname(__FILE__)."/data";

# checkandparserules() wrapper to ease some tests
sub checkandparserules2 {
	my ($rs, $err) = @{checkandparserules(@_)};

	# Simplify error message which contains lots of noise.
	if ($err =~ m/^(rule [0-9]+: exprs regex syntax for column '[^']+')/) {
		$err = "$1: ...";
	}
	return [$rs, $err];
}

# checkandparserules() wrapper to ease some tests
sub slurpjson2 {
	my ($x, $err) = @{slurpjson(@_)};

	# Simplify error message which contains lots of noise.
	if ($err =~ m/^(.*JSON parsing error)/) {
		$err = "$1: ...";
	}
	return [$x, $err];
}

FTests::run([
	#
	# slurp()
	#
	{
		"f"        => \&slurp,
		"args"     => ["/missing/file"],
		"expected" => [undef,
			"Failed to open '/missing/file': No such file or directory"
		],
		"descr"    => "Missing file",
	},
	{
		"f"        => \&slurp,
		"args"     => ["$datad/file"],
		# Force scalar context (default is array,
		# one line per entry)
		"expected" => [$a = `cat $datad/file`, undef],
		"descr"    => "File found and slurped",
	},

	#
	# slurpjson()
	#
	{
		"f"        => \&slurpjson,
		"args"     => ["/missing/file"],
		"expected" => [undef,
			"Failed to open '/missing/file': No such file or directory"
		],
		"descr"    => "Missing file",
	},
	{
		"f"        => \&slurpjson,
		"args"     => ["$datad/file-ok.json"],
		"expected" => [[
			{
				"exprs" => {
					"agent" => "curl-sugar-tests"
				},
				"tags"  => ["sugar:tests"]
			},
			{
				"exprs" => {
					"path"   => ".*",
					"status" => "^[45]"
				},
				"tags"   => ["hack:fail"]
			},
			{
				"exprs" => {
					"path"   => ".*",
					"status" => "^[123]"
				},
				"tags"   => ["hack:success"]
			}
		], undef],
		"descr"    => "Missing file",
	},
	{
		"f"        => \&slurpjson2,
		"args"     => ["$datad/file-ko.json"],
		"expected" => [undef,
			"$datad/file-ko.json: JSON parsing error: ..."
		],
		"descr"    => "Missing file",
	},

	#
	# checkandparserules()
	#
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, []],
		"expected" => [[], undef],
		"descr"    => "No input -> no output",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, {}],
		"expected" => [undef, "rules should be stored in an array"],
		"descr"    => "Rules not in an array",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, [[
		]]],
		"expected" => [undef, "rule 1: not in a hash"],
		"descr"    => "Each rule should be in a hash",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, [{}]],
		"expected" => [[{
			'exprs'    => {},
			'tags'     => [],
			'continue' => undef,
		}],undef],
		"descr"    => "Default value for empty rule",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, [{
			'exprs'    => "nope",
			'tags'     => [],
			'continue' => undef,
		}]],
		"expected" => [undef, "rule 1: exprs should be a hash, got ''"],
		"descr"    => "exprs should be a hash",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, [{
			'exprs'    => {},
			'tags'     => {},
			'continue' => undef,
		}]],
		"expected" => [undef, "rule 1: tags should be an array, got 'HASH'"],
		"descr"    => "tags should be a hash",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{}, [{
			'exprs'    => {
				"missing" => "hello",
			},
			'tags'     => {},
			'continue' => undef,
		}]],
		"expected" => [undef, "rule 1: unknown column in exprs: 'missing'"],
		"descr"    => "exprs refer to an unknown column",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{"agent" => 0}, [{
			'exprs'    => {
				"agent" => ["Mozilla.*Linux"],
			},
			'tags'     => {},
			'continue' => undef,
		}]],
		"expected" => [undef, "rule 1: field 'agent': string expected, got 'ARRAY'"],
		"descr"    => "each field should be associated to a string",
	},
	{
		"f"        => \&checkandparserules2,
		"args"     => [{"agent" => 0}, [{
			'exprs'    => {
				"agent" => "[Mozilla.*Linux",
			},
			'tags'     => {},
			'continue' => undef,
		}]],
		"expected" => [undef, "rule 1: exprs regex syntax for column 'agent': ..."],
		"descr"    => "regex syntax error",
	},
	{
		"f"        => \&checkandparserules,
		"args"     => [{"agent" => 0}, [{
			'exprs'    => {
				"agent" => "Mozilla.*Linux",
			},
			'tags' => ["browser:mozilla", "os:linux"],
		}]],
		"expected" => [[{
			'exprs'    => {
				"agent" => qr(Mozilla.*Linux),
			},
			'tags'     => ["browser:mozilla", "os:linux"],
			'continue' => undef,
		}], undef],
		"descr"    => "Single, valid rule",
	},

	# tag()
	#
	{
		"f"        => \&tag,
		"args"     => [{}, []],
		"expected" => [],
		"descr"    => "No input -> no output",
	},
	{
		"f"        => \&tag,
		"args"     => [{0 => "test"}, []],
		"expected" => [],
		"descr"    => "No input -> no output (bis)",
	},
	{
		"f"        => \&tag,
		"args"     => [{}, []],
		"expected" => [],
		"descr"    => "No input -> no output",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/favicon.ico",
				"400",
			],
			{
				"path"   => 0,
				"status" => 1,
			},
			[
				{
					"exprs" => {
						# NOTE: strings, not regexp
						"path"   => '^/favicon.ico$',
						"status" => '^[45]',
					},
					"tags"   => ["todo"],
				},
			],
		],
		"expected" => ["todo"],
		"descr"    => "Single matching rule on two fields",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/favicon.ico",
				"200",
			],
			{
				"path"   => 0,
				"status" => 1,
			},
			[
				{
					"exprs" => {
						"path"   => '^/favicon.ico$',
						"status" => '^[45]',
					},
					"tags"   => ["todo"],
				},
			],
		],
		"expected" => [],
		"descr"    => "Single non matching rule on two fields",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/favicon2.ico",
				"400",
			],
			{
				"path"   => 0,
				"status" => 1,
			},
			[
				{
					"exprs" => {
						"path"   => '^/favicon.ico$',
						"status" => '^[45]',
					},
					"tags"   => ["todo"],
				},
			],
		],
		"expected" => [],
		"descr"    => "Single non matching rule on two fields (bis)",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/favicon2.ico",
				"400",
			],
			{
				"path"   => 0,
				"status" => 1,
			},
			[
				{
					"exprs" => {
						"path"   => '^/favicon.ico$',
						"status" => '^[45]',
					},
					"tags"   => ["todo"],
				},
			],
		],
		"expected" => [],
		"descr"    => "Single non matching rule on two fields (bis)",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/index.html",
				"200",
				"www.example.com",
			],
			{
				"path"   => 0,
				"status" => 1,
				"domain" => 2,
			},
			[
				{
					"exprs" => {
						"domain" => '^www.',
						"status" => '^[12]',
					},
					"tags"     => ["www:success"],
					"continue" => 1,
				},
				{
					"exprs" => {
						"path" => '/index\.html',
					},
					"tags"     => ["www:index"],
				},
			],
		],
		"expected" => ["www:success", "www:index"],
		"descr"    => "Two matching rules with a continue",
	},
	{
		"f"        => \&tag,
		"args"     => [
			[
				"/index.html",
				"200",
				"www.example.com",
			],
			{
				"path"   => 0,
				"status" => 1,
				"domain" => 2,
			},
			[
				{
					"exprs" => {
						"domain" => '^www.',
						"status" => '^[12]',
					},
					"tags"     => ["www:success"],
				},
				{
					"exprs" => {
						"path" => '/index\.html',
					},
					"tags"     => ["www:index"],
				},
			],
		],
		"expected" => ["www:success"],
		"descr"    => "Two matching rules without continue",
	},
]);

Test::More::done_testing();
