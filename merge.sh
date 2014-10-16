#!/usr/bin/env bash

set -e

: ${OUTPUT_DIR:?}

REMOTE_NAME=`git remote | head -n 1`
INPUT_REPO=`git config --get remote.$REMOTE_NAME.url | sed -r 's,^(https://github\.com/|git@github\.com:),,' | sed -r 's,\.git$,,'`
COMMIT_HASH=`git log -1 --pretty='%H'`
COMMIT_MESSAGE=`git log -1 --pretty='%B'`

# transfer content from input to output
git remote add output $OUTPUT_DIR
git branch input $COMMIT_HASH
git push output input
git branch -d input
git remote rm output

# merge content and upload output
cd $OUTPUT_DIR
git merge --no-ff -m "$INPUT_REPO: $COMMIT_MESSAGE" input
git branch -d input
git push
