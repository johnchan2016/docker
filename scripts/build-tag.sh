#! /bin/bash
version=`git diff HEAD^..HEAD -- "$(git rev-parse --show-toplevel)"/package.json | grep '^\+.*version' | sed -s 's/[^0-9\.]//g'`

if [ "$version" != "" ]; 
then
    git tag -a "$version" -m "`git log -1 --format=%s`"
    EXPORT TAG_NO="$version"
    echo "Created a new tag, $version"
else
    EXPORT TAG_NO=node -p "require('./package.json').version"
    exit 1
fi