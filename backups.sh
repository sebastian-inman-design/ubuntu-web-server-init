#!/bin/bash

# move into the website directory
cd /home/temp_user/temp_siteurl/public

# backup and compress the content of the "wp-content" folder
tar -zcf ../backups/`date +%Y%m%d`_content.tar.gz wp-content
