#!/bin/bash

curl --silent 'https://metacpan.org/feed/recent?f=' > /tmp/recent.rss
rc=$?
if [[ $rc -ne 0 ]]; then exit 1; fi

fail=0
for url in $(cat /tmp/recent.rss | grep about= | grep metacpan | head -10 | cut -d '"' -f 2 | sed 's/metacpan.org/fastapi.metacpan.org\/v1/')
do
    disturl=$(curl --silent $url | grep download_url | cut -f 4 -d '"' )
    distname=$(basename $disturl)
    dist_locallib=$(echo $distname | sed -e 's/\.tar\.gz//')

    echo
    echo "## $disturl"

    cpanm --notest --verbose -L $dist_locallib $disturl 1>$dist_locallib.log 2>&1
    rc=$?

    tail -10 ${dist_locallib}.log > ${dist_locallib}.logtail

    if [[ $rc -eq 0 ]]
    then
        echo ok '#' cpanm $disturl

        echo '##' Sent to Feedro
        curl --silent https://gugod.org/feed/CPAN-installation-with-cpanm-notest/items -X POST -H "Authentication: Bearer ${FEEDRO_TOKEN_CPANM_NOTEST}" -F id="$disturl" -F title="SUCCESS $distname" -F content_text='@'${dist_locallib}.logtail -F "author.name=$FEEDRO_AUTHOR_NAME"
        echo
    else
        fail=1
        echo not ok '#' cpanm $disturl

        echo '##' Sent to Feedro
        curl --silent https://gugod.org/feed/CPAN-installation-with-cpanm-notest/items -X POST -H "Authentication: Bearer ${FEEDRO_TOKEN_CPANM_NOTEST}" -F id="$disturl" -F title="FAIL $distname" -F content_text='@'${dist_locallib}.logtail -F "author.name=$FEEDRO_AUTHOR_NAME"
        echo
    fi

    echo '###' __LOG_BEGIN__
    cat ${dist_locallib}.logtail
    echo '###' __LOG_END__

done

exit $fail
