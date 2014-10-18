#!/usr/bin/env bash

set -o nounset
set -o errexit

: ${TARGET_REPO_DIR:?}
: ${TRAVIS_BUILD_DIR:?}
: ${TRAVIS_COMMIT:?}
: ${TRAVIS_REPO_SLUG:?}

cd "$TRAVIS_BUILD_DIR"
BRANCH_NAME=$TRAVIS_REPO_SLUG

# transfer content to target repo
git branch "$BRANCH_NAME" "$TRAVIS_COMMIT"
git remote add target "$TARGET_REPO_DIR"
git push target "$BRANCH_NAME"
git branch -D "$BRANCH_NAME"
git remote rm target

cd "$TARGET_REPO_DIR"
COMMIT_MESSAGE=`git log -1 --pretty='%B' "$TRAVIS_COMMIT"`

# merge content leaving auch dotfiles and README
git merge --no-ff --no-commit --strategy=recursive --strategy-option=theirs "$BRANCH_NAME"
git branch -D "$BRANCH_NAME"
find . -maxdepth 1 \( -name '.[!.]*' -o -name 'README.md' \) -exec git checkout HEAD -- {} \;
git commit --allow-empty -m "${TRAVIS_REPO_SLUG}: $COMMIT_MESSAGE"

# upload the result
git push
