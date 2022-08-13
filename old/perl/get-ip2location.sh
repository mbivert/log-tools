#!/bin/sh

# See also: https://github.com/mbivert/sugard-openbsd/blob/master/bin/get-ip2location

if ! which unzip >/dev/null; then
	echo 'error: unzip not found in $PATH' 1>&2
	exit 1
fi

if ! which curl >/dev/null; then
	echo 'error: curl not found in $PATH' 1>&2
	exit 1
fi

if [ -z "$1" ]; then
	echo `basename $0`: '<key>' 1>&2
	exit 1
fi

url='https://www.ip2location.com/download'
tmpz=/tmp/db.$$.zip

echo Downloading database...
curl -s $url'/?token='$key'&file=DB1LITE' > $tmpz

echo Extracting database...
unzip -q -c $tmpz IP2LOCATION-LITE-DB1.CSV > `dirname $0`/ip2location.csv

rm $tmpz
