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

require "analogtweak";

# Augment a state variable, as returned by parseopts,
# to include some static IP location data.
#
# Input:
#	$S : state variable
# Output:
#	$S : extended state variable
sub withipdb {
	my ($S) = @_;

	my $f = sub { return ipv4tonum(@_)->[0]; };

	return { %$S, 'ipdb' => [
		parseipdbline([],
			'"'.$f->("222.73.54.00").'","'.$f->("222.73.54.255").'","CN","China"'
		)->[0][0],
		parseipdbline([],
			'"'.$f->("135.125.203.00").'","'.$f->("135.125.203.255").'","FR","France"'
		)->[0][0],
		parseipdbline([],
			'"'.$f->("221.2.163.0").'","'.$f->("221.2.163.255").'","CN","China"'
		)->[0][0],
		parseipdbline([],
			'"'.$f->("45.134.144.140").'","'.$f->("45.134.144.140").'","US","United States of America"'
		)->[0][0],
	]};
}

# Apply a regex on a string; returns captured elements.
#
# Input:
#	$r : regex to apply
#	$s : string to apply the regex to
# Output:
#	Array ref of captured elements.
sub applyre {
	my ($r, $s) = @_;
	$s =~ $r;
	return [map { $_ // "" } @{^CAPTURE}];
}

FTests::run([
	#
	# date2ts()
	#
	{
		"f"        => \&date2ts,
		"args"     => ["2022-07-02 14:30:17"],
		"expected" => [1656765017, undef],
		"descr"    => "Basic date parsing using default format",
	},
	{
		"f"        => \&date2ts,
		"args"     => ["26/Jun/2022:00:13:06 +0200", "%d/%b/%Y:%T %z"],
		"expected" => [1656187986, undef],
		"descr"    => "Date parsing with new format",
	},
	{
		"f"        => \&date2ts,
		"args"     => ["45/Jun/2022:00:13:06", "%d/%b/%Y:%T %z"],
		"expected" => [undef, "cannot parse '45/Jun/2022:00:13:06' as '%d/%b/%Y:%T %z'"],
		"descr"    => "Invalid date",
	},
	{
		"f"        => \&date2ts,
		"args"     => ["2022-07-11T17:37:54.961Z", "%Y-%m-%dT%H:%M:%S.%fZ"],
		"expected" => [1657561074, undef],
		"descr"    => "ISO format, valid date",
	},

	#
	# isrealip()
	#
	{
		"f"        => \&isrealip,
		"args"     => [""],
		"expected" => 0,
		"descr"    => "empty string is not a real ip",
	},
	{
		"f"        => \&isrealip,
		"args"     => ["-"],
		"expected" => 0,
		"descr"    => "dash is not a real ip",
	},
	{
		"f"        => \&isrealip,
		"args"     => ["127.0.0.2"],
		"expected" => 1,
		"descr"    => "lo.2 is a 'real' ip",
	},

	#
	# ipv4tonum()
	#
	{
		"f"        => \&ipv4tonum,
		"args"     => ["0.0.0.0"],
		"expected" => [0, undef],
		"descr"    => "0.0.0.0 -> 0",
	},
	{
		"f"        => \&ipv4tonum,
		"args"     => ["127.0.0.1"],
		"expected" => [(127<<24)+1, undef],
		"descr"    => "127.0.0.1 -> (127<<24)+1",
	},
	{
		"f"        => \&ipv4tonum,
		"args"     => ["noise"],
		"expected" => [0, "Not an IPv4: 'noise'"],
		"descr"    => "Invalid IPv4",
	},

	#
	# OpenBSD httpd(8) logs regex
	#
	{
		"f"        => \&applyre,
		"args"     => [
			httpdfwre(),
			'http-to-https 167.94.138.62 - - [23/Jul/2022:09:09:58 +0200] "<UNKNOWN> " 400 0 "" "" - -',
		],
		"expected" => [
			'http-to-https',
			'167.94.138.62',
			'-',
			'-',
			'23/Jul/2022:09:09:58 +0200',
			'<UNKNOWN>',
			'',
			'',
			'',
			'400',
			'0',
			'',
			'',
			'-',
			'-',
		],
		"descr"    => "Bad HTTP request",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			httpdfwre(),
			'tales.mbivert.com 127.0.0.1 - - [23/Jul/2022:09:34:25 +0200] "GET /fr/de-quelques-outils-pour-acme-plan9/?x=1 HTTP/1.1" 200 13105 "https://tales.mbivert.com/fr/" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)" 114.119.136.109 -',
		],
		"expected" => [
			'tales.mbivert.com',
			'127.0.0.1',
			'-',
			'-',
			'23/Jul/2022:09:34:25 +0200',
			'GET',
			'/fr/de-quelques-outils-pour-acme-plan9/',
			'?x=1',
			'HTTP/1.1',
			'200',
			'13105',
			'https://tales.mbivert.com/fr/',
			'Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)',
			'114.119.136.109',
			'-',
		],
		"descr"    => "Full valid request",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			httpdfwre(),
			'http-to-https 221.2.163.231 - - [03/Jul/2022:01:53:00 +0200] "GET / HTTP/1.1" 301 0 "" "Mozilla/5.0" - -',
		],
		"expected" => [
			'http-to-https',
			'221.2.163.231',
			'-',
			'-',
			'03/Jul/2022:01:53:00 +0200',
			'GET',
			'/',
			'',
			'HTTP/1.1',
			'301',
			'0',
			'',
			'Mozilla/5.0',
			'-',
			'-',
		],
		"descr"    => "Valid 301",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			httpdfwre(),
			'http-to-https 221.2.163.231 - - [03/Jul/2022:01:53:00 +0200] "GET / HTTP/1.1" 301 0 "" ""Mozilla/5.0" - -',
		],
		"expected" => [
			'http-to-https',
			'221.2.163.231',
			'-',
			'-',
			'03/Jul/2022:01:53:00 +0200',
			'GET',
			'/',
			'',
			'HTTP/1.1',
			'301',
			'0',
			'',
			'"Mozilla/5.0',
			'-',
			'-',
		],
		"descr"    => "Quote injection",
	},

	#
	# OpenBSD authlog (syslogd(8)) logs regex
	#
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-23T10:58:46.255Z main sshd[2296]: Accepted publickey for root from 13.89.11.11 port 1796 ssh2: ED25519 SHA256:XXX',
		],
		"expected" => [
			'2022-07-23T10:58:46.255Z',
			'root',
			'13.89.11.11',
		],
		"descr"    => "Accepted connection for root",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-23T11:18:23.070Z main sshd[2296]: Received disconnect from 13.89.11.11 port 1796:11: disconnected by user',
		],
		"expected" => [
			'2022-07-23T11:18:23.070Z',
			'',
			'13.89.11.11',
		],
		"descr"    => "Disconnect, no user",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-11T17:37:54.754Z main sshd[84971]: User git not allowed because shell /usr/local/bin/git-shell does not exist',
		],
		"expected" => [
			'2022-07-11T17:37:54.754Z',
			'git',
			'',
		],
		"descr"    => "Missing shell, no IP",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'Jun 29 03:57:11 main sshd[4555]: error: kex_exchange_identification: client sent invalid protocol identifier "GET http://cccc.uochb.cas.cz/50/1/0001/ HTTP/1.1"',
		],
		"expected" => [],
		"descr"    => "Bad date format: no capture",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-11T17:37:54.754Z main sshd[84971]: error: kex_exchange_identification: client sent invalid protocol identifier "GET http://cccc.uochb.cas.cz/50/1/0001/ HTTP/1.1"',
		],
		"expected" => [
			'2022-07-11T17:37:54.754Z',
			'',
			''
		],
		"descr"    => "error on kex exchange; no IP/user",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-11T17:37:54.754Z main sshd[84971]: Connection closed by 13.89.11.11 port 58278 [preauth]',
		],
		"expected" => [
			'2022-07-11T17:37:54.754Z',
			'',
			'13.89.11.11',
		],
		"descr"    => "connection closed; no user",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-11T17:37:54.961Z main sshd[84971]: Connection closed by invalid user git 13.89.11.11 port 34822 [preauth]',
		],
		"expected" => [
			'2022-07-11T17:37:54.961Z',
			'git',
			'13.89.11.11',
		],
		"descr"    => "connection closed, invalid user",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-25T03:32:23.968Z main sshd[2773]: Connection closed by authenticating user root 13.89.11.11 port 45533 [preauth]',
		],
		"expected" => [
			'2022-07-25T03:32:23.968Z',
			'root',
			'13.89.11.11',
		],
		"descr"    => "connection closed during authentication",
	},
	{
		"f"        => \&applyre,
		"args"     => [
			authlogre(),
			'2022-07-25T03:32:23.968Z main sshd[4555]: banner exchange: Connection from 185.240.246.6 port 51906: invalid format',
		],
		"expected" => [
			'2022-07-25T03:32:23.968Z',
			'',
			'185.240.246.6',
		],
		"descr"    => "banner exchange issue",
	},

	#
	# parseipdbline()
	#
	{
		"f"        => \&parseipdbline,
		"args"     => [[], ""],
		"expected" => [undef, "Regex failed on: ''"],
		"descr"    => "Empty db, empty line",
	},
	{
		"f"        => \&parseipdbline,
		"args"     => [[], '"0","16777215","-","-"'],
		"expected" => [
			[{
				'from'    => 0,
				'to'      => 16777215,
				'a2'      => '-',
				'country' => '-',
			}],
			undef,
		],
		"descr"    => 'Empty db, "valid" line',
	},
	{
		"f"        => \&parseipdbline,
		"args"     => [[], '"16777216","16777471","US","United States of America"'],
		"expected" => [
			[{
				'from'    => 16777216,
				'to'      => 16777471,
				'a2'      => 'US',
				'country' => 'United States of America',
			}],
			undef,
		],
		"descr"    => 'Empty db, valid line',
	},
	{
		"f"        => \&parseipdbline,
		"args"     => [[], '"86155264","86157311","PS","Palestine, State of"'],
		"expected" => [
			[{
				'from'    => 86155264,
				'to'      => 86157311,
				'a2'      => 'PS',
				'country' => 'Palestine, State of',
			}],
			undef,
		],
		"descr"    => 'Empty db, valid line, country name contains a coma',
	},
	{
		"f"        => \&parseipdbline,
		"args"     => [[], '"16797696","16797951","JP","Japan","Shimane","Matsue","35.467000","133.050000","690-0015","+09:00"'],
		"expected" => [
			[{
				'from'    => 16797696,
				'to'      => 16797951,
				'a2'      => 'JP',
				'country' => 'Japan',
			}],
			undef,
		],
		"descr"    => 'Empty db, IP2LOCATION-LITE-DB11.CSV entry is correctly truncated',
	},
	{
		"f"        => \&parseipdbline,
		"args"     => [[{
			'from'    => 86155264,
			'to'      => 86157311,
			'a2'      => 'PS',
			'country' => 'Palestine, State of',
		}], '"86155264","86157311","PS","Palestine, State of"'],
		"expected" => [
			[
				{
					'from'    => 86155264,
					'to'      => 86157311,
					'a2'      => 'PS',
					'country' => 'Palestine, State of',
				},
				{
					'from'    => 86155264,
					'to'      => 86157311,
					'a2'      => 'PS',
					'country' => 'Palestine, State of',
				},
			],
			undef,
		],
		"descr"    => 'valid line, same entry is added twice to non-empty db',
	},

	#
	# parseipdb()
	#
	# TODO

	#
	# locateipnum()
	#
	{
		"f"        => \&locateipnum,
		"args"     => [[], 10],
		"expected" => "Unknown",
		"descr"    => "Empty db",
	},
	{
		"f"        => \&locateipnum,
		"args"     => [[{
			'from'    => 111,
			'to'      => 222,
			'a2'      => "cc",
			'country' => "dddd",
		}], 10],
		"expected" => "Unknown",
		"descr"    => "Unknown IP",
	},
	{
		"f"        => \&locateipnum,
		"args"     => [[{
			'from'    => 111,
			'to'      => 222,
			'a2'      => "cc",
			'country' => "dddd",
		}], 111],
		"expected" => "dddd",
		"descr"    => "IP on range border",
	},
	{
		"f"        => \&locateipnum,
		"args"     => [[{
			'from'    => 111,
			'to'      => 222,
			'a2'      => "cc",
			'country' => "dddd",
		}], 222],
		"expected" => "dddd",
		"descr"    => "IP on range border (bis)",
	},

	#
	# locateip()
	#
	{
		"f"        => \&locateip,
		"args"     => [[], "1.0.3"],
		"expected" => [undef, "Not an IPv4: '1.0.3'"],
		"descr"    => "Empty db, not an IP",
	},
	{
		"f"        => \&locateip,
		"args"     => [[], "1.0.3.200"],
		"expected" => ["Unknown", undef],
		"descr"    => "Empty db",
	},
	{
		"f"        => \&locateip,
		"args"     => [[
			{
				'from'    => ipv4tonum("1.0.0.0")->[0],
				'to'      => ipv4tonum("1.0.0.255")->[0],
				'a2'      => "US",
				'country' => "United States of America",
			},
			{
				'from'    => ipv4tonum("1.0.1.0")->[0],
				'to'      => ipv4tonum("1.0.3.255")->[0],
				'a2'      => "CN",
				'country' => "China",
			},
		], "10.0.3.200"],
		"expected" => ["Unknown", undef],
		"descr"    => "Unknown IP",
	},
	{
		"f"        => \&locateip,
		"args"     => [[
			{
				'from'    => ipv4tonum("1.0.0.0")->[0],
				'to'      => ipv4tonum("1.0.0.255")->[0],
				'a2'      => "US",
				'country' => "United States of America",
			},
			{
				'from'    => ipv4tonum("1.0.1.0")->[0],
				'to'      => ipv4tonum("1.0.3.255")->[0],
				'a2'      => "CN",
				'country' => "China",
			},
		], "1.0.3.200"],
		"expected" => ["China", undef],
		"descr"    => "Chinese IP",
	},

	#
	# locateips()
	#
	{
		"f"        => \&locateips,
		"args"     => [
			{ "ip" => "127.0.0.1" },
			{ "country" => "ip" },
			[
				{
					'from'    => ipv4tonum("1.0.0.0")->[0],
					'to'      => ipv4tonum("1.0.0.255")->[0],
					'a2'      => "US",
					'country' => "United States of America",
				},
				{
					'from'    => ipv4tonum("1.0.1.0")->[0],
					'to'      => ipv4tonum("1.0.3.255")->[0],
					'a2'      => "CN",
					'country' => "China",
				},
			],
		],
		"expected" => [{
			"ip"      => "127.0.0.1",
			"country" => "Unknown",
		}, undef],
		"descr"    => "Unknown IP (127.0.0.1 is ignored)",
	},
	{
		"f"        => \&locateips,
		"args"     => [
			{ "ip" => "1.0.3.200" },
			{ "country" => "ip" },
			[
				{
					'from'    => ipv4tonum("1.0.0.0")->[0],
					'to'      => ipv4tonum("1.0.0.255")->[0],
					'a2'      => "US",
					'country' => "United States of America",
				},
				{
					'from'    => ipv4tonum("1.0.1.0")->[0],
					'to'      => ipv4tonum("1.0.3.255")->[0],
					'a2'      => "CN",
					'country' => "China",
				},
			],
		],
		"expected" => [{
			"ip"      => "1.0.3.200",
			"country" => "China",
		}, undef],
		"descr"    => "Chinese IP",
	},
	{
		"f"        => \&locateips,
		"args"     => [
			{ "fw-ip" => "-", "ip" => "1.0.3.200" },
			{ "country" => "ip" },
			[
				{
					'from'    => ipv4tonum("1.0.0.0")->[0],
					'to'      => ipv4tonum("1.0.0.255")->[0],
					'a2'      => "US",
					'country' => "United States of America",
				},
				{
					'from'    => ipv4tonum("1.0.1.0")->[0],
					'to'      => ipv4tonum("1.0.3.255")->[0],
					'a2'      => "CN",
					'country' => "China",
				},
			],
		],
		"expected" => [{
			"fw-ip"   => "-",
			"ip"      => "1.0.3.200",
			"country" => "China",
		}, undef],
		"descr"    => "Chinese IP (fw-ip unused; ip used)",
	},
	{
		"f"        => \&locateips,
		"args"     => [
			{ "fw-ip" => "1.0.0.1", "ip" => "1.0.3.200" },
			{ "country" => "fw-ip" },
			[
				{
					'from'    => ipv4tonum("1.0.0.0")->[0],
					'to'      => ipv4tonum("1.0.0.255")->[0],
					'a2'      => "US",
					'country' => "United States of America",
				},
				{
					'from'    => ipv4tonum("1.0.1.0")->[0],
					'to'      => ipv4tonum("1.0.3.255")->[0],
					'a2'      => "CN",
					'country' => "China",
				},
			],
		],
		"expected" => [{
			"fw-ip"   => "1.0.0.1",
			"ip"      => "1.0.3.200",
			"country" => "United States of America",
		}, undef],
		"descr"    => "USA (fw-ip valid, ip not used)",
	},

	#
	# parsecols()
	#
	{
		"f"        => \&parsecols,
		"args"     => ["", " ", []],
		"expected" => [{}, undef],
		"descr"    => "No input, no columns",
	},
	{
		"f"        => \&parsecols,
		"args"     => ["foo bar ", " ", ["first", "second", "third"]],
		"expected" => [{
			'first'  => 'foo',
			'second' => 'bar',
			'third'  => '',
		}, undef],
		"descr"    => "Basic columns; one last empty colum",
	},
	{
		"f"        => \&parsecols,
		"args"     => ["foo bar baz foobar foobaz", " ", ["first", "", "third", "", "fifth"]],
		"expected" => [{
			'first'  => 'foo',
			'third'  => 'baz',
			'fifth'  => 'foobaz',
			''       => 'foobar',
		}, undef],
		"descr"    => "ignored columns successively stored to ''",
	},

	#
	# meltips()
	#
	{
		"f"        => \&meltips,
		"args"     => [{}, []],
		"expected" => {},
		"descr"    => "No input, no output",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"dummy" => "nothing"}, []],
		"expected" => {"dummy" => "nothing"},
		"descr"    => "No input, no output (bis)",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"dummy" => "nothing"}, ["real-ip"]],
		"expected" => {"dummy" => "nothing"},
		"descr"    => "Not enough IPs fields: no-op",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"dummy" => "nothing"}, ["real-ip", "ip"]],
		"expected" => {"dummy" => "nothing"},
		"descr"    => "no 'ip' field: no-op",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"ip" => "-"}, ["real-ip", "ip"]],
		"expected" => {"ip" => "-"},
		"descr"    => "'-' is not a real ip; real-ip not created",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"ip" => "8.8.8.8"}, ["real-ip", "ip"]],
		"expected" => {"ip" => "8.8.8.8", "real-ip" => "8.8.8.8"},
		"descr"    => "real-ip created from single source",
	},
	{
		"f"        => \&meltips,
		"args"     => [{"fw-ip" => "-", "ip" => "8.8.8.8"}, ["real-ip", "fw-ip", "ip"]],
		"expected" => {"fw-ip" => "-", "ip" => "8.8.8.8", "real-ip" => "8.8.8.8"},
		"descr"    => "real-ip created from two sources",
	},

	#
	# parseopts()
	#
	{
		"f"        => \&parseopts,
		"args"     => [["-f", "/dev/null"]],
		"expected" => [{
			'ifs'    => "␜",
			'ofs'    => "␜",
			're'     => '',
			'cols'   => [],
			'prints' => [],
			'dates'  => {},
			'begin'  => "-3600",
			'end'    => "32503762799",
			'ipdbfn' => "/dev/null",
			'ipdb'   => [],
			'joins'  => {},
			'melts'  => {},
			'skips'  => undef,
			'iplocs' => {},
			'fns'    => ["/dev/stdin"],
			'ips'    => [],
			'strict' => 0,
		}, undef],
		"descr"    => "default options, besides ipdbfn",
	},
	{
		"f"        => \&parseopts,
		"args"     => [["-f", "/dev/null", "path/to/access.log"]],
		"expected" => [{
			'ifs'    => "␜",
			'ofs'    => "␜",
			're'     => '',
			'cols'   => [],
			'prints' => [],
			'dates'  => {},
			'begin'  => "-3600",
			'end'    => "32503762799",
			'ipdbfn' => "/dev/null",
			'ipdb'   => [],
			'joins'  => {},
			'melts'  => {},
			'skips'  => undef,
			'iplocs' => {},
			'fns'    => ["path/to/access.log"],
			'ips'    => [],
			'strict' => 0,
		}, undef],
		"descr"    => "default options; single filename",
	},
	{
		"f"        => \&parseopts,
		"args"     => [[
			"-f", "/dev/null",
			"-c", "domain,ip,,,date,",

			"path/to/access.log", "test.log"
		]],
		"expected" => [{
			'ifs'    => "␜",
			'ofs'    => "␜",
			're'     => '',
			'cols'   => ["domain", "ip", "", "", "date", ""],
			'prints' => [],
			'dates'  => {},
			'begin'  => "-3600",
			'end'    => "32503762799",
			'ipdbfn' => "/dev/null",
			'ipdb'   => [],
			'joins'  => {},
			'melts'  => {},
			'skips'  => undef,
			'iplocs' => {},
			'fns'    => ["path/to/access.log", "test.log"],
			'ips'    => [],
			'strict' => 0,
		}, undef],
		"descr"    => "Columns are splitted, with empty last field; two filenames",
	},
	{
		"f"        => \&parseopts,
		"args"     => [[
			"-f", "/dev/null",
			"-c", "domain,ip,,,date,date2,",
			"-d", "date,ts,%F %H:%M:%S",
			"-d", "date2,ts2,%F",

			"path/to/access.log", "test.log"
		]],
		"expected" => [{
			'ifs'    => "␜",
			'ofs'    => "␜",
			're'     => '',
			'cols'   => ["domain", "ip", "", "", "date", "date2", ""],
			'prints' => [],
			'dates'  => {
				"date"  => ["ts",  "%F %H:%M:%S"],
				"date2" => ["ts2", "%F"],
			},
			'begin'  => "-3600",
			'end'    => "32503762799",
			'ipdbfn' => "/dev/null",
			'ipdb'   => [],
			'joins'  => {},
			'melts'  => {},
			'skips'  => undef,
			'iplocs' => {},
			'fns'    => ["path/to/access.log", "test.log"],
			'ips'    => [],
			'strict' => 0,
		}, undef],
		"descr"    => "Dates format are correctly stored",
	},

	#
	# processline()
	# NOTE: central function; main tests are here
	#
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "1st,2nd,3rd",
				"-i", " ",
				"-p", "1st,3rd",
			])->[0],
			"first second third",
		],
		"expected" => [["first", "third"], undef],
		"descr"    => "Extracting only a few columns",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "domain,ip,,,date",
				"-p", "domain,ip,date,ts",
				"-d", "ts,date,%d/%b/%Y:%T %z",
				"-b", "2022-06-25",
			])->[0],
			"www.zhongmu.eu␜127.0.0.1␜-␜-␜26/Jun/2022:00:13:06 +0200",
		],
		"expected" => [
			["www.zhongmu.eu", "127.0.0.1", "26/Jun/2022:00:13:06 +0200", 1656187986],
			undef
		],
		"descr"    => "Date conversion; within filter",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "domain,ip,,,date",
				"-p", "domain,ip,date,ts",
				"-d", "date,ts,%d/%b/%Y:%T %z",
				"-b", "2022-06-30",
			])->[0],
			"www.zhongmu.eu␜127.0.0.1␜-␜-␜26/Jun/2022:00:13:06 +0200",
		],
		"expected" => [ undef, undef ],
		"descr"    => "Date conversion; filtered",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "request",
				"-p", "method,path,version,values",
				"-m", "request method,path,values,version ^(\\w+) ([^ \\?]+)(\\?[^ ]*|) (.*)\$",
			])->[0],
			"GET / HTTP/1.1",
		],
		"expected" => [["GET", "/", "HTTP/1.1", ""], undef],
		"descr"    => "Melt a single field",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "request",
				"-p", "method,path,version,values",
				"-m", "request method,path,values,version ^(\\w+) ([^ \\?]+)(\\?[^ ]*|) (.*)\$",
			])->[0],
			"GET /?foo=bar HTTP/1.1",
		],
		"expected" => [["GET", "/", "HTTP/1.1", "?foo=bar"], undef],
		"descr"    => "Melt a single field, with values",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "request",
				"-p", "method,path,version,values",
				"-m", "request method,path,values,version ^(\\w+) ([^ \\?]+)(\\?[^ ]*|) (.*)\$",
			])->[0],
			"<UNKNOWN> ",
		],
		"expected" => [["", "", "", ""], undef],
		"descr"    => "Regexp doesn't match",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "request",
				"-p", "method,path,version,values",
				"-m", "request method,path,values,version ^(\\w+) ([^ \\?]+)(\\?[^ ]*|) (.*)\$",
			])->[0],
			"GET /index.php?s=/Index/\think\app/invokefunction&function=call_user_func_array&vars[0]=md5&vars[1][]=HelloThinkPHP21 HTTP/1.1",
		],
		"expected" => [[
			"GET", "/index.php", "HTTP/1.1",
			"?s=/Index/\think\app/invokefunction&function=call_user_func_array&vars[0]=md5&vars[1][]=HelloThinkPHP21"
		], undef],
		"descr"    => "Melt a single field, with annoying values",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts([
				"-f", "/dev/null",
				"-c", "request,ip",
				"-p", "request,ip,country",
				"-l", "country,ip",
			])->[0]),
			"GET / HTTP/1.1␜135.125.203.30",
		],
		"expected" => [[
			"GET / HTTP/1.1", "135.125.203.30", "France"
		], undef],
		"descr"    => "IP geolocalisation: known country",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts([
				"-f", "/dev/null",
				"-c", "request,ip",
				"-p", "request,ip,country",
				"-l", "country,ip",
			])->[0]),
			"GET / HTTP/1.1␜137.125.203.30",
		],
		"expected" => [[
			"GET / HTTP/1.1", "137.125.203.30", "Unknown"
		], undef],
		"descr"    => "IP geolocalisation: unknown country",
	},
	{
		"f"        => \&processline,
		"args"     => [
			parseopts([
				"-f", "/dev/null",
				"-c", "month,mday,time,host,,msg",
				"-p", "date,msg",
				"-j", "date month,mday,time ,",
			])->[0],
			"Jun␜28␜20:10:58␜gw␜sshd[64535]␜error: kex_exchange_identification: banner line contains invalid characters",
		],
		"expected" => [[
			"Jun,28,20:10:58", "error: kex_exchange_identification: banner line contains invalid characters"
		], undef],
		"descr"    => "Joining fields for authlog",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts([
				"-f", "/dev/null",
				"-c", "month,mday,time,host,,msg",
				"-d", "ts,tmp,%b %d %T",
				"-p", "ts,msg",
				"-j", "tmp month,mday,time",
			])->[0]),
			"Jun␜28␜20:10:58␜gw␜sshd[64535]␜error: kex_exchange_identification: banner line contains invalid characters",
		],
		"expected" => [[
			date2ts("1970-06-28 20:10:58")->[0], "error: kex_exchange_identification: banner line contains invalid characters"
		], undef],
		"descr"    => "Joining fields for authlog: making a date out of them",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts([
				"-f", "/dev/null",
				"-c", "month,mday,time,host,,msg",
				"-s", '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d*Z␜.*␜logfile.*turned.*over$',
#				"-s", '.*logfile.*turned.*over$',
			])->[0]),
			"2022-06-29T23:00:01.575Z␜gw␜newsyslog[59535]:␜logfile␜turned␜over",
		],
		"expected" => [undef, undef],
		"descr"    => "Useless line is skipped",
	},

	#
	# Still processline();
	#
	# OpenBSD httpd(8) forwarded log format tests.
	#
	# NOTE: we're testing both the qsplit version and the regular version;
	# the qsplit version was historically there first, and still provides
	# a few interesting tests.
	#
	# Both are tested essentially on the same input;
	#
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw-qs", "-f", "/dev/null"])->[0]),
			"2022-06-29T23:00:01.575Z␜gw␜newsyslog[59535]:␜logfile␜turned␜over",
		],
		"expected" => [undef, undef],
		"descr"    => "OpenBSD/httpd: useless line is skipped [qsplit]",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw", "-f", "/dev/null"])->[0]),
			"2022-06-29T23:00:01.575Z gw newsyslog[59535]: logfile turned over",
		],
		"expected" => [undef, undef],
		"descr"    => "OpenBSD/httpd: useless line is skipped",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw-qs", "-f", "/dev/null"])->[0]),
			'http-to-https␜221.2.163.231␜-␜-␜03/Jul/2022:01:53:00 +0200␜GET / HTTP/1.1␜301␜0␜␜Mozilla/5.0␜-␜-',
		],
		"expected" => [
			[
				"http-to-https",
				"03/Jul/2022:01:53:00 +0200",
				date2ts("03/Jul/2022:01:53:00 +0200", "%d/%b/%Y:%T %z")->[0],
				"GET",
				"/",
				301,
				"HTTP/1.1",
				"China",
				"221.2.163.231",
				"",
				"Mozilla/5.0",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 301 redirection (HTTP to HTTPs) [qsplit]",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw", "-f", "/dev/null"])->[0]),
			'http-to-https 221.2.163.231 - - [03/Jul/2022:01:53:00 +0200] "GET / HTTP/1.1" 301 0 "" "Mozilla/5.0" - -',
		],
		"expected" => [
			[
				"http-to-https",
				"03/Jul/2022:01:53:00 +0200",
				date2ts("03/Jul/2022:01:53:00 +0200", "%d/%b/%Y:%T %z")->[0],
				"GET",
				"/",
				301,
				"HTTP/1.1",
				"China",
				"221.2.163.231",
				"",
				"Mozilla/5.0",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 301 redirection (HTTP to HTTPs)",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw-qs", "-f", "/dev/null"])->[0]),
			'zhongmu.eu␜127.0.0.1␜-␜-␜03/Jul/2022:00:43:07 +0200␜GET /remote/fgt_lang?lang=/../../../..//////////dev/ HTTP/1.1␜404␜0␜␜python-requests/2.6.0 CPython/2.7.5 Linux/3.10.0-1160.el7.x86_64␜45.134.144.140␜-',
		],
		"expected" => [
			[
				"zhongmu.eu",
				"03/Jul/2022:00:43:07 +0200",
				date2ts("03/Jul/2022:00:43:07 +0200", "%d/%b/%Y:%T %z")->[0],
				"GET",
				"/remote/fgt_lang",
				404,
				"HTTP/1.1",
				"United States of America",
				"45.134.144.140",
				"?lang=/../../../..//////////dev/",
				"python-requests/2.6.0 CPython/2.7.5 Linux/3.10.0-1160.el7.x86_64",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 404; random bot hack attempt [qsplit]",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw", "-f", "/dev/null"])->[0]),
			'zhongmu.eu 127.0.0.1 - - [03/Jul/2022:00:43:07 +0200] "GET /remote/fgt_lang?lang=/../../../..//////////dev/ HTTP/1.1" 404 0 "" "python-requests/2.6.0 CPython/2.7.5 Linux/3.10.0-1160.el7.x86_64" 45.134.144.140 -',
		],
		"expected" => [
			[
				"zhongmu.eu",
				"03/Jul/2022:00:43:07 +0200",
				date2ts("03/Jul/2022:00:43:07 +0200", "%d/%b/%Y:%T %z")->[0],
				"GET",
				"/remote/fgt_lang",
				404,
				"HTTP/1.1",
				"United States of America",
				"45.134.144.140",
				"?lang=/../../../..//////////dev/",
				"python-requests/2.6.0 CPython/2.7.5 Linux/3.10.0-1160.el7.x86_64",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 404; random bot hack attempt",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw-qs", "-f", "/dev/null"])->[0]),
			'zhongmu.eu␜109.237.103.9␜-␜-␜10/Jul/2022:17:18:52 +0200␜<UNKNOWN> ␜400␜0␜␜␜-␜-',
		],
		"expected" => [
			[
				"zhongmu.eu",
				"10/Jul/2022:17:18:52 +0200",
				date2ts("10/Jul/2022:17:18:52 +0200", "%d/%b/%Y:%T %z")->[0],
				"",
				"",
				400,
				"",
				"Unknown",
				"109.237.103.9",
				"",
				"",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 400; UNKNOWN HTTP request [qsplit]",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw", "-f", "/dev/null"])->[0]),
			'zhongmu.eu 109.237.103.9 - - [10/Jul/2022:17:18:52 +0200] "<UNKNOWN> " 400 0 "" "" - -',
		],
		"expected" => [
			[
				"zhongmu.eu",
				"10/Jul/2022:17:18:52 +0200",
				date2ts("10/Jul/2022:17:18:52 +0200", "%d/%b/%Y:%T %z")->[0],
				"<UNKNOWN>",
				"",
				400,
				"",
				"Unknown",
				"109.237.103.9",
				"",
				"",
			],
			undef
		],
		"descr"    => "OpenBSD/httpd: 400; UNKNOWN HTTP request",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw-qs", "-f", "/dev/null"])->[0]),
			# Generated by qsplit from:
			# www.zhongmu.eu 127.0.0.1 - - [16/Jun/2022:08:08:59 +0200] "GET / HTTP/1.1" 301 0 "" ""Mozilla/5.0 (Windows; U; Windows NT 6.1; en-us) AppleWebKit/534.50 (KHTML" 121.46.25.189 -
			# NOTE: qsplit was taking () into account as quotes, which, while
			# begnin, is incorrect
			'www.zhongmu.eu␜127.0.0.1␜-␜-␜16/Jun/2022:08:08:59 +0200␜GET / HTTP/1.1␜301␜0␜␜␜Mozilla/5.0␜Windows; U; Windows NT 6.1; en-us␜AppleWebKit/534.50␜KHTML" 121.46.25.189 -',
		],
		"expected" => [
			undef,
			'Wrong number of column (got 14 != 12): www.zhongmu.eu␜127.0.0.1␜-␜-␜16/Jun/2022:08:08:59 +0200␜GET / HTTP/1.1␜301␜0␜␜␜Mozilla/5.0␜Windows; U; Windows NT 6.1; en-us␜AppleWebKit/534.50␜KHTML" 121.46.25.189 -',
		],
		"descr"    => "OpenBSD/httpd: 400, user-agent quote injection [qsplit]",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-httpd-fw", "-f", "/dev/null"])->[0]),
			# Generated by qsplit from:
			'www.zhongmu.eu 127.0.0.1 - - [16/Jun/2022:08:08:59 +0200] "GET / HTTP/1.1" 301 0 "" ""Mozilla/5.0 (Windows; U; Windows NT 6.1; en-us) AppleWebKit/534.50 (KHTML" 121.46.25.189 -',
		],
		"expected" => [
			[
				"www.zhongmu.eu",
				"16/Jun/2022:08:08:59 +0200",
				date2ts("16/Jun/2022:08:08:59 +0200", "%d/%b/%Y:%T %z")->[0],
				"GET",
				"/",
				301,
				"HTTP/1.1",
				"Unknown",
				"121.46.25.189",
				"",
				'"Mozilla/5.0 (Windows; U; Windows NT 6.1; en-us) AppleWebKit/534.50 (KHTML',
			],
			undef,
		],
		"descr"    => "OpenBSD/httpd: 400, user-agent quote injection",
	},

	#
	# /var/log/authlog parsing, with dates
	# in "ISO format" (syslogd -Z)
	#
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-auth-iso", "-f", "/dev/null"])->[0]),
			"2022-07-06T18:00:01.669Z main newsyslog[88552]: logfile turned over",
		],
		"expected" => [undef, undef],
		"descr"    => "OpenBSD/authlog: logfile turned over skipped",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-auth-iso", "-f", "/dev/null"])->[0]),
			"Jul  8 05:17:40 main sshd[1]: Connection closed by 1.1.1.1 port 1 [preauth]",
		],
		"expected" => [undef, undef],
		"descr"    => "OpenBSD/authlog: invalid date are skipped",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-auth-iso", "-f", "/dev/null"])->[0]),
			"2022-07-23T10:58:46.255Z main sshd[2296]: Accepted publickey for root from 222.73.54.00 port 1796 ssh2: ED25519 SHA256:XXX",
		],
		"expected" => [[
			"2022-07-23T10:58:46.255Z",
			date2ts("2022-07-23T10:58:46.255Z", "%Y-%m-%dT%H:%M:%S.%fZ")->[0],
			"root",
			"222.73.54.00",
			"China",
		], undef],
		"descr"    => "OpenBSD/authlog: regular entry, user, IP, geo",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-auth-iso", "-f", "/dev/null"])->[0]),
			"2022-07-23T11:18:23.070Z main sshd[2296]: Received disconnect from 13.89.11.11 port 1796:11: disconnected by user",
		],
		"expected" => [[
			"2022-07-23T11:18:23.070Z",
			date2ts("2022-07-23T11:18:23.070Z", "%Y-%m-%dT%H:%M:%S.%fZ")->[0],
			"",
			"13.89.11.11",
			"Unknown",
		], undef],
		"descr"    => "OpenBSD/authlog: regular entry, no user, IP, no geo",
	},
	{
		"f"        => \&processline,
		"args"     => [
			withipdb(parseopts(["--openbsd-auth-iso", "-f", "/dev/null"])->[0]),
			"2022-07-11T17:37:54.754Z main sshd[84971]: User git not allowed because shell /usr/local/bin/git-shell does not exist",
		],
		"expected" => [[
			"2022-07-11T17:37:54.754Z",
			date2ts("2022-07-11T17:37:54.754Z", "%Y-%m-%dT%H:%M:%S.%fZ")->[0],
			"git",
			"",
			"Unknown",
		], undef],
		"descr"    => "OpenBSD/authlog: regular entry, user, no IP, no geo",
	},
]);

Test::More::done_testing();
