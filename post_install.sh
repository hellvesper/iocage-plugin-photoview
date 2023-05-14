#!/bin/sh

echo " - Install exiftool"
fetch https://exiftool.org/Image-ExifTool-12.62.tar.gz
tar -xf Image-ExifTool-12.62.tar.gz
cd Image-ExifTool-12.62
perl Makefile.PL
make && make install
cd ~
rm -rf Image-ExifTool-12.62 Image-ExifTool-12.62.tar.gz

# MariaDB
# Configure startup parameters:
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"

# Start mysql:
service mysql-server start

# Harden the MariaDB installation:
# Since mysql_secure_installation is interactive, we'll do the tasks performed by it manually
mysql --user=root <<_EOF_
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
_EOF_

# Generate some passwords
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/db_password
DB_PASSWORD=`cat /root/db_password`
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/admin_password
ADMIN_PASSWORD=`cat /root/admin_password`

# Configure the DB
# Create user and database for PhotoPrism
DB_USER="photoview"
DB="photoview"
# Save the config values
echo "$DB" > /root/db_name
echo "$DB_USER" > /root/db_user
echo "Database User: $DB_USER"
echo "Database Password: $DB_PASSWORD"
mysql --user=root <<_EOF_
CREATE DATABASE ${DB}
CHARACTER SET = 'utf8mb4'
COLLATE = 'utf8mb4_unicode_ci';
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;
_EOF_

#echo " -Install Photoview"
git clone https://github.com/photoview/photoview.git
cd photoview
git checkout 228f2cc1e7b2c9079fa81363c49c9c4d60a5cccd
#echo " -Build backend"
cd api
#echo " -Fetching dependencies"
go get .
#echo " -Applying patches"
sed -i -e 's|#include <dlib|#include </usr/local/include/dlib|g' ~/go/pkg/mod/github.com/\!kagami/go-face@v0.0.0-20210630145111-0c14797b4d0e/classify.cc
sed -i -e 's|#include <dlib|#include </usr/local/include/dlib|g' ~/go/pkg/mod/github.com/\!kagami/go-face@v0.0.0-20210630145111-0c14797b4d0e/facerec.cc
sed -i -e 's|#include <dlib|#include </usr/local/include/dlib|g' ~/go/pkg/mod/github.com/\!kagami/go-face@v0.0.0-20210630145111-0c14797b4d0e/jpeg_mem_loader.cc
sed -i -e 's|#include <jpeglib.h>|#include </usr/local/include/jpeglib.h>|g' ~/go/pkg/mod/github.com/\!kagami/go-face@v0.0.0-20210630145111-0c14797b4d0e/jpeg_mem_loader.cc
echo " -Compiling backend"
go build -v -o photoview .
#echo " -Build frontend"
cd ~/photoview/ui
#echo " -Fetching dependencies"
npm install
#echo " -Building frontend"
npm run build
#echo " -Installing photoview"
cd ~
# create app dir
mkdir photoview_app
# copy ui to app dir
cp -r photoview/ui/dist photoview_app/ui
# copy api to app dir
cp photoview/api/photoview photoview_app/
cp -r photoview/api/data photoview_app/
# copy config example
cp photoview/api/example.env photoview_app/.env

# configure photoview .env
IP4_ADDR=`/sbin/ifconfig epair0b | /usr/bin/awk '/inet /{print $2}'`
sed -i -e "s|user|$DB_USER|g" /root/photoview_app/.env
sed -i -e "s|password|$DB_PASSWORD|g" /root/photoview_app/.env
sed -i -e "s|dbname|$DB|g" /root/photoview_app/.env
sed -i -e "s|PHOTOVIEW_DEVELOPMENT_MODE=1|PHOTOVIEW_DEVELOPMENT_MODE=0|g" /root/photoview_app/.env
sed -i -e "s|PHOTOVIEW_SERVE_UI=0|PHOTOVIEW_SERVE_UI=1|g" /root/photoview_app/.env
sed -i -e "s|//localhost|//$IP4_ADDR|g" /root/photoview_app/.env
sed -i -e "s|=localhost|=$IP4_ADDR|g" /root/photoview_app/.env
sed -i -e "s|4001|80|g" /root/photoview_app/.env

# create photoview user
pw group add -n photoview -g 1000
pw user add -n photoview -u 1000 -g photoview
mkdir -p /usr/home/photoview
ln -s /usr/home /home

# move photoview dir to users home and grand permissions
mv /root/photoview_app /home/photoview/
chown -R photoview:photoview /home/photoview
mkdir /var/log/photoview
chown -R photoview:photoview /var/log/photoview

# Make rc.d script
tee photoview_rc <<_EOF_
#!/bin/sh

# PROVIDE: photoview
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name="photoview"
desc="Photoview image and video gallery"
rcvar="\${name}_enable"
photoview_chdir="/usr/home/photoview/photoview_app"
command="/usr/sbin/daemon"
command_args="-o /var/log/photoview/photoview.log -p /var/run/\${name}.pid /usr/home/photoview/photoview_app/photoview"
procname="/usr/home/photoview/photoview_app/photoview"
pidfile="/var/run/photoview.pid"

load_rc_config \$name
run_rc_command "\$1"
_EOF_

# move photoview_rc to rc.d dir and rename
mv photoview_rc /usr/local/etc/rc.d/photoview
chmod +x /usr/local/etc/rc.d/photoview

# enable photoview daemon
sysrc photoview_enable=YES
# enable dbus daemon
sysrc dbus_enable=YES
# enable avahi daemon
sysrc avahi_daemon_enable=YES
# start photoview
service photoview start
service dbus start
service avahi-daemon start
