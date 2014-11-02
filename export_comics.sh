#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o posix

if [[ ! -d ~/export/comics-de ]]
then
    echo 'Missing export directory!'
    exit 1
fi

cd ~/export/comics-de

# remove posts from last export
git rm -rf --quiet _posts

# recreate posts directory
mkdir _posts
cd _posts

# create subdirectories for each year since 2005
mkdir $(seq 2005 $(date +'%Y'))

mysql --defaults-extra-file=~/mysql-export.conf <<EOF | while read post_id file_name
SELECT
    id AS post_id,
    CONCAT(
        DATE_FORMAT(post_date, '%Y/%Y-%m-%d'),
        '-',
        post_name,
        '.md'
    ) AS file_name
FROM ff_posts
WHERE (post_status = 'publish') AND (post_title LIKE '#%')
ORDER BY post_date ASC;
EOF
do
    echo "Exporting comic ${file_name} ..."

    mysql --defaults-extra-file=~/mysql-export.conf <<EOF > ${file_name}
SELECT
    CONCAT(
      '---\n',
      'title: "', TRIM(REPLACE(post_title, '"', '\\\"')), '"\n',
      '---',
      post_content
    ) AS file_content
FROM ff_posts
WHERE (id = ${post_id});
EOF

    # use Unix line endings
    dos2unix --quiet ${file_name}

    # filter mouse over text
    mouseover=$(cut --delimiter=']' --fields=1 --only-delimited ${file_name} | head --lines=1 | grep -oP '(".*")?')
    if [[ ${mouseover} != '' ]]
    then
    # append mouseover after second line
    sed --in-place "2a\mouseover: ${mouseover}" ${file_name}
    fi

    # strip comic tags
    sed --in-place 's|\[comic[^]]*\]||' ${file_name}

    # ensure newline after YAML header
    sed --in-place '3,4s|^---<|---\n<|' ${file_name}

    # add newline to end of file
    sed --in-place '$a\\' ${file_name} #' Workaround for BashSupport plugin [Issue 88]
done

# store exported posts
git add --all .

# only commit if there is anything to commit
if ! git diff-index --cached --quiet HEAD --
then
    git commit --author='Bastian Melnyk <fonflatter[at]gmail.com>' -m 'Export of fonflatter.de'
else
    echo 'Nothing to commit.'
fi

# upload changes
git push

exit 0
