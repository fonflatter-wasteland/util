#!/usr/bin/env bash

set -o nounset
set -o errexit

: ${TARGET_REPO_DIR:?}
: ${TRAVIS_BUILD_DIR:?}
: ${TRAVIS_COMMIT:?}
: ${TRAVIS_REPO_SLUG:?}

cd "$TRAVIS_BUILD_DIR"
BRANCH_NAME=$TRAVIS_REPO_SLUG

echo "Transfering content to target repo..."
git branch "$BRANCH_NAME" "$TRAVIS_COMMIT"
git remote add target "$TARGET_REPO_DIR"
git push target "$BRANCH_NAME"
git branch -D "$BRANCH_NAME"
git remote rm target

cd "$TARGET_REPO_DIR"
COMMIT_MESSAGE=`git log -1 --pretty='%B' "$TRAVIS_COMMIT"`

echo "Merging content leaving out dotfiles and README..."
git merge --no-ff --no-commit --strategy=recursive --strategy-option=theirs "$BRANCH_NAME"
git branch -D "$BRANCH_NAME"
git reset HEAD -- .[!.]* README.md
# only commit if there is anything to commit
git diff-index --quiet --cached HEAD || git commit -m "${TRAVIS_REPO_SLUG}: $COMMIT_MESSAGE"

echo "Uploading result..."
git push
