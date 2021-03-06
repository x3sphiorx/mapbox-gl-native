#!/usr/bin/env bash

set -e
set -o pipefail
set -u

if [ -z `which jazzy` ]; then
    echo "Installing jazzy…"
    gem install jazzy
    if [ -z `which jazzy` ]; then
        echo "Unable to install jazzy. See https://github.com/mapbox/mapbox-gl-native/blob/master/platform/ios/INSTALL.md"
        exit 1
    fi
fi

OUTPUT=${OUTPUT:-documentation}

BRANCH=$( git describe --tags --match=ios-v*.*.* --abbrev=0 )
SHORT_VERSION=$( echo ${BRANCH} | sed 's/^ios-v//' )
RELEASE_VERSION=$( echo ${SHORT_VERSION} | sed -e 's/^ios-v//' -e 's/-.*//' )

rm -rf /tmp/mbgl
mkdir -p /tmp/mbgl/
README=/tmp/mbgl/README.md
cp platform/ios/docs/doc-README.md "${README}"
# http://stackoverflow.com/a/4858011/4585461
echo "## Changes in version ${RELEASE_VERSION}" >> "${README}"
sed -n -e '/^## /{' -e ':a' -e 'n' -e '/^## /q' -e 'p' -e 'ba' -e '}' platform/ios/CHANGELOG.md >> "${README}"

rm -rf ${OUTPUT}
mkdir -p ${OUTPUT}

cp -r platform/ios/docs/img "${OUTPUT}/img"

DEFAULT_THEME="platform/darwin/docs/theme"
THEME=${JAZZY_THEME:-$DEFAULT_THEME}

jazzy \
    --config platform/ios/jazzy.yml \
    --sdk iphonesimulator \
    --github-file-prefix https://github.com/mapbox/mapbox-gl-native/tree/${BRANCH} \
    --module-version ${SHORT_VERSION} \
    --readme ${README} \
    --documentation="platform/{darwin,ios}/docs/guides/*.md" \
    --root-url https://www.mapbox.com/ios-sdk/api/${RELEASE_VERSION}/ \
    --theme ${THEME} \
    --output ${OUTPUT}
# https://github.com/realm/jazzy/issues/411
find ${OUTPUT} -name *.html -exec \
    perl -pi -e 's/BRANDLESS_DOCSET_TITLE/iOS SDK $1/, s/Mapbox\s+(Docs|Reference)/Mapbox iOS SDK $1/' {} \;
