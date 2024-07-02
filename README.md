# User Creation Script: Detailed Explanation

Objective: This is a project to develop a bash script called create_users.sh, which automates the creation of users and groups on a Linux system. The script reads a file containing user details and processes each entry to create users and assign them to specified groups.

## Prerequisites:

Ensure you have root or sudo privileges to create users and groups.
Ensure the user file (userfile.txt) is formatted correctly, with each line containing a username and groups separated by a semicolon (;).

### PART 1:

## We will login to the root folder of our machine and create the file create_users.sh and a text file userfile.txt.  The text file will contain the usernames and the groups where the users will be assigned. 


### PART 2:

## Below we will dissect this bash script. This script as explained earlier will read the contents of the users file and create the groups as directed and assign users to the groups and create password for the users.We now delve in to explain how this script works and the different stages of its operation


# Script Stages



### STAGE 1:

## The log file is created as well as the file that will store the username and passwords


```bash

LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

```


### STAGE 2:

##  Argument Check : Checks if the script is run with exactly one argument (the user file). If not, it prints the usage message and exits.


```bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 userfile.txt"
  exit 1
fi


```


### STAGE 3:

##  User File Validation : USERFILE Stores the user file path provided as an argument. Validates occurs if the user file exists and is readable. If not, it prints an error message and exits.


```bash

USERFILE=$1

if [ ! -f "$USERFILE" ]; then
  echo "User file $USERFILE does not exist."
  exit 1
fi

if [ ! -r "$USERFILE" ]; then
  echo "User file $USERFILE is not readable."
  exit 1
fi



```


### STAGE 4:

##  Prepare Log and Password Files;
touch: Ensures the log file exists.
mkdir -p: Creates the directory for the password file if it does not exist.
touch: Ensures the password file exists.
chmod 600: Sets secure permissions on the password file to restrict access.


```bash

touch "$LOGFILE"
mkdir -p /var/secure
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"


```



### STAGE 5:

##  Process Each Line in User File : IFS=";": Sets the Internal Field Separator to semicolon to correctly parse the user file. while read -r: Reads each line from the user file into username and groups.


```bash

IFS=";"
while read -r username groups; do
  ...
done < "$USERFILE"

```


### STAGE 6:

##  Trim and Validate Fields; 
xargs: Trims whitespace from username and groups.
echo and tee: Logs the processing message.
if [ -z "$username" ] || [ -z "$groups" ]: Checks if username or groups is empty. If so, logs a message and skips to the next line.


```bash

username=$(echo "$username" | xargs)
groups=$(echo "$groups" | xargs)

echo "Processing: '$username' with groups '$groups'" | tee -a "$LOGFILE"

if [ -z "$username" ] || [ -z "$groups" ]; then
  echo "Username or groups field is empty. Skipping." | tee -a "$LOGFILE"
  continue
fi


```


### STAGE 7:

##  Check if User Already Exists : id "$username" &>/dev/null: Checks if the user already exists. If so, logs a message and skips to the next line.


```bash

if id "$username" &>/dev/null; then
  echo "User $username already exists. Skipping." | tee -a "$LOGFILE"
  continue
fi


```



### STAGE 8:

##  Create Primary Group for User : getent group "$username" &>/dev/null: Checks if the primary group exists. If not, creates the group and logs a message.


```bash

if ! getent group "$username" &>/dev/null; then
  groupadd "$username"
  echo "Group $username created for user $username." | tee -a "$LOGFILE"
fi


```



### STAGE 9:

##  Process and Create Additional Groups; 
IFS=',' read -ra group_array <<< "$groups": Splits the groups into an array.
for group in "${group_array[@]}": Iterates over each group.
group=$(echo "$group" | xargs): Trims whitespace from the group name.
getent group "$group" &>/dev/null: Checks if the group exists. If not, creates the group and logs a message.


```bash

IFS=',' read -ra group_array <<< "$groups"
for group in "${group_array[@]}"; do
  group=$(echo "$group" | xargs)
  if ! getent group "$group" &>/dev/null; then
    groupadd "$group"
    echo "Group $group created." | tee -a "$LOGFILE"
  fi
done


```



### STAGE 10:

##  Create User and Assign Password; 
PASSWORD: Generates a random password.
useradd: Creates the user with the primary group, additional groups, and home directory.
chpasswd: Sets the user's password.
echo "$username:$PASSWORD" >> "$PASSWORD_FILE": Stores the username and password in the password file.


```bash

PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)
useradd -m -g "$username" -G "$(echo "$groups" | tr -d ' ')" -s /bin/bash "$username"
echo "$username:$PASSWORD" | chpasswd
echo "$username:$PASSWORD" >> "$PASSWORD_FILE"


```



### STAGE 11:

##  Set Home Directory Permissions; 
if [ -d "/home/$username" ]: Checks if the home directory exists.
chmod 600 "/home/$username": Sets secure permissions on the home directory.
chown "$username:$username" "/home/$username": Sets ownership of the home directory.

```bash

if [ -d "/home/$username" ]; then
  chmod 600 "/home/$username"
  chown "$username:$username" "/home/$username"
fi

```




### STAGE 12:

##  Log User Creation : Logs the successful creation of the user and their groups.



```bash

echo "User $username created with groups $groups." | tee -a "$LOGFILE"


```




### STAGE 12:

##  Completion Message : Logs the completion of the user creation process.


```bash

echo "User creation process completed." | tee -a "$LOGFILE"


```


We pass the folloing user parameters inside the userfile.txt file

```bash

charles011; sudo,dev,www-data,
hagga-012; sudo
Enkky-013; dev,www-data, docker
Imoka-014; ikuku,hr-data
Kadari-015; dev,www-data, docker
Benna-016; dev,ikuku, production
Ringi-017; production,hr-data, docker
Anama-018; fin-data, collag


```