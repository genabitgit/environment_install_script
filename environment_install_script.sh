
#region1
#First, manually create teamcity user
sudo adduser teamcity
sudo usermod -aG sudo teamcity
#endregion1

#!/bin/bash
#region2
echo					"Install_&_Configure_Nginx"
sudo apt-get update
sudo apt-get install nginx -y

echo					"Enable_UFW"

sudo ufw allow "Nginx Full"
sudo ufw allow 5000/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8111/tcp
sudo ufw allow ssh
sudo ufw --force enable
sudo ufw reload
sleep 2s

echo					"Server_Configuration"

sudo truncate -s 0 ../../etc/nginx/sites-available/default
sleep 1s
echo "server {
listen 80;
location / {
proxy_pass http://localhost:5000;
proxy_http_version 1.1;
proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection keep-alive;
proxy_set_header Host \$http_host;
proxy_cache_bypass \$http_upgrade;
}
} " >  ../../etc/nginx/sites-available/default

echo					"Server_Configuration_for_TeamCity"

sudo truncate -s 0 ../../etc/nginx/sites-available/teamcity
sleep 1s
echo "
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''   '';
}

server {

    listen       80;
    server_name  localhost teamcitypecia.ddns.net;

    proxy_read_timeout     1200;
    proxy_connect_timeout  240;
    client_max_body_size   0;

    location / {

        proxy_pass          http://localhost:8111/;
        proxy_http_version  1.1;
        proxy_set_header    X-Forwarded-For \$remote_addr;
        proxy_set_header    Host \$server_name:\$server_port;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection \$connection_upgrade;
    }
}
" >  ../../etc/nginx/sites-available/teamcity


echo					"Server_Configuration_for_TeamCity"

sudo truncate -s 0 ../../etc/nginx/sites-enabled/teamcity
sleep 1s
echo "
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''   '';
}

server {

    listen       80;
    server_name  localhost teamcitypecia.ddns.net;

    proxy_read_timeout     1200;
    proxy_connect_timeout  240;
    client_max_body_size   0;

    location / {

        proxy_pass          http://localhost:8111/;
        proxy_http_version  1.1;
        proxy_set_header    X-Forwarded-For \$remote_addr;
        proxy_set_header    Host \$server_name:\$server_port;
        proxy_set_header    Upgrade \$http_upgrade;
        proxy_set_header    Connection \$connection_upgrade;
    }
}
" >  ../../etc/nginx/sites-enabled/teamcity

echo					"Systemd_Script"

sudo touch ../../etc/systemd/system/Blog.Pecia.service
sleep 1s
echo "[Unit]
Description=.NET App on Ubuntu
[Service]
WorkingDirectory=/var/www
ExecStart=/usr/bin/dotnet /var/www/Blog.Pecia.dll
Restart=always
RestartSec=10
SyslogIdentifier=Blog.Pecia
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
[Install]
WantedBy=multi-user.target
" > ../../etc/systemd/system/Blog.Pecia.service

echo					"Start_Nginx"

sudo service nginx start

echo					"Test_Nginx_Configuration"

sudo nginx -t

echo					"Nginx_Reload"

sudo nginx -s reload

echo					"Register Microsoft key and feed:"

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget -q https://packages.microsoft.com/config/ubuntu/18.04/prod.list 
sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list

echo					"Install_.NET_SDK"

sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-2.1 -y

sleep 1s

echo					".Net_Core_App_Create"

#dotnet new mvc -n Blog.Pecia
#cd Madina.Pecia.Blog
#dotnet restore
#dotnet build -c release
cd ../../var/www
sudo rm -rf html
#sudo mkdir Madina.Pecia.Blog
#cd ~/
#cd Madina.Pecia.Blog/
#sudo dotnet publish -c release -o ../../../var/www/
cd ~/
sudo chown -R teamcity:teamcity ../../var/www/

echo					"Enable_Systemctl"

sudo systemctl enable Blog.Pecia
sleep 1s
sudo systemctl start Blog.Pecia
sleep 1s
sudo systemctl reload nginx.service
sleep 1s

echo					"Install_Oracle_JDK_8"

sudo apt-add-repository ppa:webupd8team/java -y
sudo apt-get update
sudo apt-get install oracle-java8-installer -y
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

echo					"TeamCity_Server_Install"

sudo wget -c http://download.jetbrains.com/teamcity/TeamCity-2018.1.tar.gz -O ../../tmp/TeamCity-2018.1.tar.gz 
cd ../../tmp/
sudo tar -xvf TeamCity-2018.1.tar.gz -C /srv
cd ~/
sudo mkdir ../../srv/.BuildServer
sudo touch ../../etc/init.d/teamcity
sleep 1s

echo					"Team_City_Auto_start_Script"

echo "#!/bin/sh
### BEGIN INIT INFO
# Provides:          teamcity
# Required-Start:
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      1 0 6
# Short-Description: simple description.
### END INIT INFO
# /etc/init.d/teamcity - startup script for teamcity
export TEAMCITY_DATA_PATH="/srv/.BuildServer"
case \$1 in
  start)
    start-stop-daemon --start  -c teamcity --exec /srv/TeamCity/bin/teamcity-server.sh start
    ;;
  stop)
    start-stop-daemon --start -c teamcity  --exec  /srv/TeamCity/bin/teamcity-server.sh stop
    ;;
  restart)   
    start-stop-daemon --start  -c teamcity --exec /srv/TeamCity/bin/teamcity-server.sh stop
    start-stop-daemon --start  -c teamcity --exec /srv/TeamCity/bin/teamcity-server.sh start
    ;;
  *)
    exit 1
    ;;
esac
exit 0" > ../../etc/init.d/teamcity 
sleep 1s

sudo chmod +x ../../etc/init.d/teamcity 
sleep 1s
sudo chown root:root ../../etc/init.d/teamcity
sudo update-rc.d teamcity defaults

cd ../../

sudo mkdir -p /srv/.BuildServer/lib/jdbc
sudo mkdir -p /srv/.BuildServer/config 
cd ~/

echo					"Change_ownership_of_files"

sudo chown -R teamcity ../../srv/TeamCity
sudo chown -R teamcity ../../srv/.BuildServer


echo					"Download_PostGres_ODBC_driver_for_TeamCity"

sudo wget http://jdbc.postgresql.org/download/postgresql-42.2.1.jar -O ../../srv/.BuildServer/lib/jdbc/postgresql-42.2.1.jar

echo					"Create_a_Database_Config_file_for_PostGres"

sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib 
sleep 1s
#endregion2

#region3
#####################################################################################
###############HeandsType############################################################
sudo su - postgres
psql
create role "teamcity" with login password 'MY$very53secure@password';
create database "teamcity" owner "teamcity";
\q
exit

sudo ../../etc/init.d/postgresql restart 
sleep 1s

sudo touch ../../srv/.BuildServer/config/database.properties
sleep 1s
echo "connectionUrl=jdbc:postgresql://127.0.0.1/teamcity
connectionProperties.user=teamcity
connectionProperties.password=MY$very53secure@password" > ../../srv/.BuildServer/config/database.properties
sleep 1s 
sudo chown teamcity:teamcity ../../srv/.BuildServer/config/database.properties

sudo ../../etc/init.d/postgresql start
sleep 1s
sudo reboot
##sudo ../../etc/init.d/teamcity start

echo				"Install Teamcity Build Agent Configuration"

#InstallBuildAgent
wget http://teamcitypecia.ddns.net/update/buildAgent.zip
sudo apt-get install unzip -y
unzip buildAgent.zip -d buildAgent
sudo chmod +x buildAgent/bin/agent.sh
cp buildAgent/conf/buildAgent.dist.properties buildAgent/conf/buildAgent.properties
#Autostart build agent:
sudo nano ../../etc/rc.local
adding string: sudo -u teamcity /home/teamcity/buildAgent/bin/agent.sh start
sudo nano buildAgent/conf/buildAgent.properties
#endregion3

#region4
#Download 2 ssh key on build machine
chmod 0400 id_rsa
mkdir .ssh
cat id_rsa.pub >> .ssh/authorized_keys
chmod 644 .ssh/authorized_keys
sudo chmod 775 buildAgent
sudo groupmod -g 1000 teamcity
#endregion4


