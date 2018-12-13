#!/bin/bash

curl --silent https://www.cpan.org/modules/01modules.mtime.rss > /tmp/01modules.mtime.rss
rc=$?
if [[ $rc -ne 0 ]]; then exit 1; fi

for disturl in $(cat /tmp/01modules.mtime.rss | grep -o -E '(http://www.cpan.org/modules/by-authors/[^<]+)' | head)
do
    distname=$(basename $disturl)
    dist_locallib=$(echo $distname | sed -e 's/\.tar\.gz//')
    cpanm -L $dist_locallib $disturl 2>&1 > $dist_locallib.log
    rc=$?

    if [[ $rc -eq 0 ]]
    then
        echo 'ok -' $disturl
    else
        echo 'not ok -' $disturl
    fi
done
