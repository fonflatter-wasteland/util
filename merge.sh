#!/usr/bin/env bash

set -e

: ${OUTPUT_DIR:?}

INPUT_REPO=`git config --get remote.github.url | sed -r 's,^(https://github\.com/|git@github\.com:),,' | sed -r 's,\.git$,,'`
INPUT_BRANCH=`git symbolic-ref HEAD | sed 's,^refs/heads/,,'`

# transfer content from input to output
git remote add tmp $OUTPUT_DIR
git push tmp $INPUT_BRANCH:input
git remote rm tmp

# merge content and upload output
cd $OUTPUT_DIR
MESSAGE=`git log -1 --pretty='%B' input`
git merge --no-ff -m "$INPUT_REPO: $MESSAGE" input
git branch -d input
git push
