#!/bin/bash

curl --silent https://www.cpan.org/modules/01modules.mtime.rss > /tmp/01modules.mtime.rss
rc=$?
if [[ $rc -ne 0 ]]; then exit 1; fi

fail=0
for disturl in $(cat /tmp/01modules.mtime.rss | grep -o -E '(http://www.cpan.org/modules/by-authors/[^<]+)' | head -5)
do
    distname=$(basename $disturl)
    dist_locallib=$(echo $distname | sed -e 's/\.tar\.gz//')

    cpanm --notest -L $dist_locallib $disturl 2>&1 > $dist_locallib.log
    rc=$?

    if [[ $rc -eq 0 ]]
    then
        echo ok '#' cpanm $disturl

        curl --silent https://gugod.org/feed/cpan-install-notest-recent-SUCCESS/items -X POST -F id="$disturl" -F title="$distname" -F content_text='<'${dist_locallib}.log
    else
        fail=1
        echo not ok '#' cpanm $disturl
        echo '#' __LOG_BEGIN__
        cat $dist_locallib.log
        echo '#' __LOG_END__

        curl --silent https://gugod.org/feed/cpan-install-notest-recent-FAIL/items -X POST -F id="$disturl" -F title="$distname" -F content_text='<'${dist_locallib}.log
    fi
done

exit $fail
