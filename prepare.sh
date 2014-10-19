#!/usr/bin/env bash

set -o nounset
set -o errexit

: ${TARGET_REPO_BRANCH:?}
: ${TARGET_REPO_DIR:?}
: ${TARGET_REPO_SLUG:?}
: ${TRAVIS_BUILD_DIR:?}

echo "Decrypting private SSH key..."
openssl aes-256-cbc -K $encrypted_key -iv $encrypted_iv -in "${TRAVIS_BUILD_DIR}/.ssh/id_rsa.enc" -out ~/.ssh/id_rsa -d
chmod og-rw ~/.ssh/id_rsa

echo "Setting default git config..."
cp ~/util/.gitconfig ~/.gitconfig

echo "Cloning target repository..."
git clone -o github -b "${TARGET_REPO_BRANCH}" "git@github.com:${TARGET_REPO_SLUG}.git" "${TARGET_REPO_DIR}"
