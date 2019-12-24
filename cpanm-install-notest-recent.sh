#!/bin/bash

curl --silent https://cpan.metacpan.org/modules/01modules.mtime.rss > /tmp/01modules.mtime.rss
rc=$?
if [[ $rc -ne 0 ]]; then exit 1; fi

fail=0
for disturl in $(cat /tmp/01modules.mtime.rss | grep -o -E '(http://www.cpan.org/modules/by-authors/[^<]+)' | head -30 | sed 's/www.cpan/cpan.metacpan/')
do
    distname=$(basename $disturl)
    dist_locallib=$(echo $distname | sed -e 's/\.tar\.gz//')

    echo
    echo "## $disturl"

    cpanm --notest --verbose -L $dist_locallib $disturl 1>$dist_locallib.log 2>&1
    rc=$?

    if [[ $rc -eq 0 ]]
    then
        echo ok '#' cpanm $disturl

        echo '##' Sent to Feedro
        curl --silent https://gugod.org/feed/CPAN-installation-with-cpanm-notest/items -X POST -H "Authentication: Bearer ${FEEDRO_TOKEN_CPANM_NOTEST}" -F id="$disturl" -F title="SUCCESS $distname" -F content_text='<'<(tail -25 ${dist_locallib}.log)
        echo
    else
        fail=1
        echo not ok '#' cpanm $disturl
        echo '#' __LOG_BEGIN__
        tail -25 $dist_locallib.log
        echo '#' __LOG_END__

        echo '##' Sent to Feedro
        curl --silent https://gugod.org/feed/CPAN-installation-with-cpanm-notest/items -X POST -H "Authentication: Bearer ${FEEDRO_TOKEN_CPANM_NOTEST}" -F id="$disturl" -F title="FAIL $distname" -F content_text='<'<(tail -25 ${dist_locallib}.log)
        echo
    fi
done

exit $fail
