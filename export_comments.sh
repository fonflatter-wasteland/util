#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

OUTPUT_DIR=${HOME}/export/comments-de
COMMENTS_DIR=_data/comments

if ! test -d "${OUTPUT_DIR}"
then
    echo 'Missing output directory!'
    exit $(false)
fi

cd "${OUTPUT_DIR}"

# remove comments from last export
git rm -rf --quiet "${COMMENTS_DIR}"

# recreate comments directory
mkdir -p "${COMMENTS_DIR}"
cd "${COMMENTS_DIR}"

# loop over every comment of every comic
mysql --defaults-extra-file=~/mysql-export.conf <<EOF | while read COMMENT_ID FILE_PATH FILE_NAME
    SELECT
        comment_ID                         AS COMMENT_ID,
        DATE_FORMAT(post_date, '%Y/%m/%d') AS FILE_PATH,
        CONCAT(post_name, '.yml')          AS FILE_NAME
    FROM ff_posts
    INNER JOIN ff_comments
    ON (comment_post_ID = ID)
    WHERE (post_status = 'publish') AND (post_title LIKE '#%')
    AND (comment_approved = 1) AND (comment_type = '')
    ORDER BY post_date ASC;
EOF
do
    echo "Exporting comment ${COMMENT_ID} of comic ${FILE_PATH}/${FILE_NAME} ..."

    # create directory for export file
    mkdir -p "${FILE_PATH}"

    # append date, author, URL, and content of every comment to the export file
    mysql --defaults-extra-file=~/mysql-export.conf <<EOF >> "${FILE_PATH}/${FILE_NAME}"
    SET @indent='  ';
    SELECT
        CONCAT(
            '- date: ', DATE_FORMAT(comment_date_gmt, '%Y-%m-%d %H:%i:%S'), '\n',
            @indent, 'author: ', comment_author, '\n',
            @indent, 'url: ', comment_author_url, '\n',
            @indent, 'content: | ', '\n',
            @indent, @indent, REPLACE(comment_content, '\n', CONCAT('\n', @indent, @indent))
        )
    FROM ff_comments
    WHERE (comment_ID = ${COMMENT_ID});
EOF

done

# loop over all exported comments
find . -name '*.yml' | while read FILE_NAME
do
    # use Unix line endings
    dos2unix --quiet "${FILE_NAME}"

    "${SCRIPT_DIR}"/convert_html_entities.py "${FILE_NAME}"

    # add newline to end of file
    sed --in-place '$a\\' "${FILE_NAME}" #' Workaround for BashSupport plugin [Issue 88]
done

# store exported posts
git add --all .

# only commit if there is anything to commit
if ! git diff-index --cached --quiet HEAD --
then
    git commit -m 'Export of fonflatter.de comments'
else
    echo 'Nothing to commit.'
fi

# upload changes
git push

exit $(true)
