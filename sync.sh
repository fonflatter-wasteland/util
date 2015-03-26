#!/usr/bin/env bash                                                                                                                                                                      

# This script synchronizes all Git repositories in subdirectories with upstream                                                                                                          

set -o nounset
set -o errexit

BASE_PATH=$1

find ${BASE_PATH} -name '.git' | sed 's|\.git$||' | while read REPOSITORY_PATH
do
    echo "Synchronizing ${REPOSITORY_PATH/${BASE_PATH}\//} ..."

    cd ${REPOSITORY_PATH}
    git add --all

    # only commit if there is anything to commit                                                                                                                                         
    git diff-index --quiet --cached HEAD || git commit -m 'Add new content'

    git pull --rebase
    git push

    echo "Done." && echo
done

exit 0
