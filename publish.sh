#!/usr/bin/env bash

set -o nounset
set -o errexit

: ${TARGET_REPO_BRANCH:?}
: ${TARGET_REPO_DIR:?}
: ${TRAVIS_BUILD_DIR:?}

cd "${TARGET_REPO_DIR}"

echo "Overwriting content of ${TARGET_REPO_BRANCH}..."
rsync --archive --delete --exclude='.git' "${TRAVIS_BUILD_DIR}/_site/" "${TARGET_REPO_DIR}/"
git add --all .
git commit -m "Automatic build by Travis CI"
git push
