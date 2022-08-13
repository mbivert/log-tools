# Introduction
Small tools to help parse OpenBSD's [httpd(8)][httpd-8]
logs (forwarded format).

The code is mostly split in:

  1. [``logtweak``][logtweak]: parses one or multiple log files (access.log),
  eventually filtering them on date, localizing IPs, etc. It outputs
  a table-like format, with a special character as column-separator;
  2. [``logtag``][logtag]: reads ``logtweak``'s output, and, according to
  a set of rules described in a JSON file, will tag each log
  line.

Additionally, [``iploc``][iploc] geolocalizes IPs from the CLI.

Finally, ad hoc scripts can be written to generate basic analytics,
identify/ban nefarious IPs, etc.

# IP location
Performed using IP databases from [ip2location.com][ip2location.com].

While it can't be openly redistributed, you can still download a
free "LITE" version from their website. See the [``get-ip2location.sh``][get-ip2loc]
script.

# Tests
There are two types of tests:

  1. Per-go function tests: [``iplocate_test.go``][iplocate-test],
  [``tweak_test.go``][tweak-test];
  2. Global tests, in [``tests/``][tests], launched by [``tests.sh``][tests-sh].

All tests are written in a peculiar style, see [this blog post][tales-ftests]
for more.

# Cross-compilation
The following will create amd64 OpenBSD executables ``logtag``,
``logtweak`` and ``iploc``:

    (local)$ GOOS=openbsd GOENV=amd64 make all

# History
Originally, the code was meant to be a bit more generic, and to be
coupled with [qsplit(1)][qsplit-1]. However, it turns out that quote
injection in user-agent is a thing; a big regexp avoids most of the
related issues.

A older prototype in Perl (see [``old/perl/``][perl-proto]) demonstrates a more
generic approach; it suffers from a major performance hit
that I haven't bothered to investigate though.

[httpd-8]:         https://man.openbsd.org/httpd.8
[qsplit-1]:        https://github.com/mbivert/qsplit/blob/master/qsplit.1
[ip2location.com]: https://www.ip2location.com
[tales-ftests]:    https://tales.mbivert.com/on-a-function-based-test-framework/
[perl-proto]:      https://github.com/mbivert/log-tools/tree/master/old/perl
[logtweak]:        https://github.com/mbivert/log-tools/blob/master/logtweak.go
[logtag]:          https://github.com/mbivert/log-tools/blob/master/logtag.go
[iploc]:           https://github.com/mbivert/log-tools/blob/master/iploc.go
[get-ip2loc]:      https://github.com/mbivert/log-tools/blob/master/get-ip2location.sh
[iplocate-test]:   https://github.com/mbivert/log-tools/blob/master/iplocate_test.go
[tweak-test]:      https://github.com/mbivert/log-tools/blob/master/tweak_test.go
[tests]:           https://github.com/mbivert/log-tools/tree/master/tests
[tests-sh]:        https://github.com/mbivert/log-tools/blob/master/tests.sh
