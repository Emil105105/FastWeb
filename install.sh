#!/usr/bin/env bash

if [ "$USER" != "root" ]; then
    echo "Please run this script as root or with sudo"
    exit 2
fi

read -rp "Please enter a name for your first project: " project_name

project_path="/var/FastWeb/$project_name"

app_path="/opt/FastWeb"

admin_path="/var/FastWeb/_admin"

echo "The following dependencies have to be installed with apt:"
echo "python3, python3-pip, python3-venv, nginx, ufw, supervisor"

while true; do

    read -rp "Do you want to proceed? (y/n) " yn
    case $yn in
    	[yY] ) echo "proceeding (this may take a while)...";
    	    break;;
    	[nN] ) echo "exiting...";
    		exit;;
    	* ) echo invalid response;;
    esac

done

echo -n "installing dependencies (#1 of 4) (This may take a while)... "
apt-get update
apt-get install -y python3 python3-pip python3-venv nginx ufw supervisor
echo "done"


echo -n "creating directories (#1 of 6)... "
mkdir -p "$app_path/venv"
echo "done"

echo -n "creating python virtual environment (#1 of 3) (This may take a while)... "
python3 -m venv "$app_path/venv"
echo "done"

echo -n "loading python virtual environment (#1 of 3)..."
source "$app_path/venv/bin/activate"
echo "done"

echo -n "installing dependencies (#2 of 4) (This may take a while)... "
pip install -r "$(pwd)/requirements.txt"
echo "done"

echo -n "deactivating python virtual environment (#1 of 3)..."
deactivate
echo "done"


echo -n "creating directories (#2 of 6)... "
mkdir -p "$project_path/venv"
echo "done"

echo -n "creating python virtual environment (#2 of 3) (This may take a while)... "
python3 -m venv "$project_path/venv"
echo "done"

echo -n "loading python virtual environment (#2 of 3)..."
source "$project_path/venv/bin/activate"
echo "done"

echo -n "installing dependencies (#3 of 4) (This may take a while)... "
pip install -r "$(pwd)/template_requirements.txt"
echo "done"

echo -n "deactivating python virtual environment (#2 of 3)..."
deactivate
echo "done"


echo -n "creating directories (#3 of 6)... "
mkdir -p "$admin_path/venv"
echo "done"

echo -n "creating python virtual environment (#3 of 3) (This may take a while)... "
python3 -m venv "$admin_path/venv"
echo "done"

echo -n "loading python virtual environment (#3 of 3)..."
source "$admin_path/venv/bin/activate"
echo "done"

echo -n "installing dependencies (#4 of 4) (This may take a while)... "
pip install -r "$(pwd)/admin/requirements.txt"
echo "done"

echo -n "deactivating python virtual environment (#3 of 3)..."
deactivate
echo "done"

echo "WARNING: FastWeb will modify nginx, ufw, and supervisor config files as well as /var/log. If you have made changes to any of them, please create a backup."

while true; do

    read -rp "Do you want to proceed? (y/n) " yn
    case $yn in
    	[yY] ) echo proceeding...;
    	    break;;
    	[nN] ) echo exiting...;
    		exit;;
    	* ) echo invalid response;;
    esac

done

echo "We recommend to delete the nginx default config."

while true; do

    read -rp "Do you want to delete the nginx default config? (y/n) " yn
    case $yn in
    	[yY] ) echo deleting...;
    	    rm /etc/nginx/sites-enabled/default
    	    break;;
    	[nN] ) echo skipping...;
    		break;;
    	* ) echo invalid response;;
    esac

done

read -rp "Please enter your IP-address or your domain-name: " ip_or_domain

echo "WARNING: You are going to enter port numbers. Please ensure that each port number is only used ONCE on the entire system. You can use 'sudo ss -ltnp' to check for used ports."

read -rp "Please enter the public port number you want to use (80 for http): " public_port

read -rp "Please enter an unused port number for internal use: " internal_port

read -rp "Please enter an another unused port number for internal use: " internal_port_two

read -rp "Please enter the public port number you want to use for the admin control panel: " admin_port

echo -n "writing nginx config (#1 of 2)... "
printf "server{\n    listen %s;\n    server_name %s;\n    allow all;\n    location / {\n        proxy_pass http://localhost:%s;\n        include /etc/nginx/proxy_params;\n        proxy_redirect off;\n    }\n}" "$public_port" "$ip_or_domain" "$internal_port" > "/etc/nginx/sites-enabled/FastWeb_$project_name"
echo "done"

echo -n "writing nginx config (#2 of 2)... "
printf "server{\n    listen %s;\n    server_name %s;\n    allow all;\n    location / {\n        proxy_pass http://localhost:%s;\n        include /etc/nginx/proxy_params;\n        proxy_redirect off;\n    }\n}" "$admin_port" "$ip_or_domain" "$internal_port_two" > "/etc/nginx/sites-enabled/FastWeb__admin"
echo "done"

echo -n "restarting nginx... "
systemctl restart nginx
echo "done"

echo -n "configuring firewall (#1 of 4)... "
ufw allow "$public_port"
echo "done"

echo -n "configuring firewall (#2 of 4)... "
ufw allow "$admin_port"
echo "done"

echo -n "configuring firewall (#3 of 4)... "
ufw deny "$internal_port"
echo "done"

echo -n "configuring firewall (#4 of 4)... "
ufw deny "$internal_port_two"
echo "done"

echo "WARNING: You may have to enable the firewall with 'sudo ufw enable'. Please make sure you won't get locked out of SSH if you are using it!"

echo -n "creating directories (#4 of 6)... "
mkdir -p "/var/log/FastWeb"
echo "done"

echo -n "creating directories (#5 of 6)... "
mkdir -p "$app_path/installer"
echo "done"

echo -n "copying files (#1 of 6)... "
cp -r "$(pwd)"/* "$app_path"
echo "done"

echo -n "copying files (#2 of 6)... "
cp -r "$(pwd)/admin"/* "$admin_path"
echo "done"

echo -n "writing supervisor config (#1 of 2)... "
supervisor_name="FastWeb_$project_name"
printf "[program:%s]\ndirectory=%s\ncommand=%s/venv/bin/gunicorn -w 4 -b :%s main:app\nuser=%s\nautostart=true\nautorestart=true\nstopasgroup=true\nkillasgroup=true\nstderr_logfile=/var/log/FastWeb/%s.err.log\nstdout_logfile=/var/log/FastWeb/%s.out.log" "$supervisor_name" "$project_path" "$project_path" "$internal_port" "root" "$project_name" "$project_name" > "/etc/supervisor/conf.d/$supervisor_name.conf"
echo "done"

echo -n "writing supervisor config (#2 of 2)... "
supervisor_name="FastWeb__admin"
printf "[program:%s]\ndirectory=%s\ncommand=%s/venv/bin/gunicorn -w 4 -b :%s main:app\nuser=%s\nautostart=true\nautorestart=true\nstopasgroup=true\nkillasgroup=true\nstderr_logfile=/var/log/FastWeb/%s.err.log\nstdout_logfile=/var/log/FastWeb/%s.out.log" "$supervisor_name" "$admin_path" "$admin_path" "$internal_port_two" "root" "_admin" "_admin" > "/etc/supervisor/conf.d/$supervisor_name.conf"
echo "done"

echo -n "reloading supervisor... "
supervisorctl reread
supervisorctl update
echo "done"

read -rp "Please enter a path for your project (We recommend using '/home/$(logname)/Documents/$project_name'): " project_root

echo -n "creating directories (#5 of 6)... "
mkdir -p "$project_root"
echo "done"

echo -n "copying files (#3 of 6)... "
cp -r "$(pwd)/template"/* "$project_root"
echo "done"

echo -n "copying files (#4 of 6)... "
printf "#!/usr/bin/env bash\n\nsource \"%s/venv/bin/activate\"\n" "$project_path"> "$project_root/venv_activate.sh"
echo "done"

echo -n "copying files (#5 of 6)... "
printf "{\n    \"name\": \"%s\",\n    \"hash_ips\": \"False\",\n    \"cookie_max_age\": \"31\"\n}" "$project_name"> "$project_root/config.json"
echo "done"

echo -n "copying files (#6 of 6)... "
printf "#!/usr/bin/env bash\n\nif [ \"\$USER\" != \"root\" ]; then\n    echo \"Please run this script as root or with sudo\"\n    exit 2\nfi\nsource \"%s/venv/bin/activate\"\npython3 \"%s/fw_compiler.py\" \"%s\"\ncase $? in\n    1) echo \"an error occurred while restarting\" ;;\n    4) echo \"illegal file name\" ;;\n    5) echo \"_ or _.* file alongside site.py\" ;;\n    6) echo \"directory alongside path.py\" ;;\n    7) echo \"static file alongside path.py\" ;;\n    8) echo \"multiple _ or _.* files\" ;;\n    9) echo \"syntax error\" ;;\n    0) echo Success ;;\nesac\n\ndeactivate\nsupervisorctl stop FastWeb_%s\nsupervisorctl start FastWeb_%s\n" "$app_path" "$app_path" "$project_root" "$project_name" "$project_name"> "$project_root/restart_app.sh"
echo "done"

echo "WARNING: You may have to change the permissions for your project to edit files. You can use the following commands to achieve this: 'sudo chmod -R 664 $project_root' and 'sudo chown -R $(logname) $project_root'"
