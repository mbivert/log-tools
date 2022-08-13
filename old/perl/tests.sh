#!/bin/sh

set -e

d=`dirname $0`
#analogtweak="perl -I $HOME/perl5/lib/perl5/ -d:NYTProf $d/analogtweak"
#analogtag="perl -I $HOME/perl5/lib/perl5/ -d:NYTProf $d/analogtag"
analogtweak="perl $d/analogtweak"
analogtag="perl $d/analogtag"

export analogtweak analogtag

# Run "high-level" tests wrapping perl scripts
# execution. See all the ``tests/[0-9]-*/`` directories

ofn=`mktemp /tmp/analog.tests.XXXXXX`
efn=`mktemp /tmp/analog.tests.XXXXXX`

r=0
for x in tests/[0-9]*/; do
	if [ ! -d "$x" ]; then continue; fi
	y=`basename $x`

	echo -n "Running $y, $(cat $x/descr): "

	set +e
	cat $x/stdin | sh $x/cmd > $ofn 2> $efn
	e="$?"
	set -e

	f="$(cat $x/exit)"
	if [ "$e" != "$f" ]; then
		echo "error: unexpected error code: got $e, expected $f" 1>&2
		echo "stderr: "; cat $efn
		r=1; break
	fi
	if ! diff -u $x/stdout $ofn; then
		echo "error: unexpected stdout" 1>&2
		echo "stderr: "; cat $efn
		r=1; break
	fi
	if ! diff -u $x/stderr $efn; then
		echo "error: unexpected stderr" 1>&2
		echo "stdout: "; cat $ofn
		r=1; break
	fi

	echo OK
done

rm $ofn $efn
exit $r
