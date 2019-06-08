#! /bin/bash
# version=`git diff HEAD^..HEAD -- "$(git rev-parse --show-toplevel)"/package.json | grep '^\+.*version' | sed -s 's/[^0-9\.]//g'`

# if [ "$version" != "" ]; 
# then
#     git tag -a "$version" -m "`git log -1 --format=%s`"
#     echo "New Version, $version"
# else
#     version=$(cat package.json \
#         | grep version \
#         | head -1 \
#         | awk -F: '{ print $2 }' \
#         | sed 's/[",]//g' \
#         | tr -d '[[:space:]]')
#     echo "Current Version, $version"
# fi



# if rollback
# check exist ROLLBACK_VERSION in env/build.env

# override TAG_NO from build.env
version=$(cat package.json \
    | grep version \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g' \
    | tr -d '[[:space:]]')
echo "Current Version, $version" #variable
echo -n "${version}" > .tags