#!/bin/bash

LOGFILE=/var/log/user_management.log
PASSWORD_FILE=/var/secure/user_passwords.txt

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <userfile>"
  exit 1
fi

USERFILE="$1"

# Check if the user file exists and is readable
if [ ! -f "$USERFILE" ] || [ ! -r "$USERFILE" ]; then
  echo "User file does not exist or is not readable: $USERFILE"
  exit 1
fi

# Create log and password files
touch "$LOGFILE"
mkdir -p /var/secure
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Read the user file and process each line
while IFS=';' read -r username groups; do
  username=$(echo "$username" | xargs)  # Trim whitespace
  groups=$(echo "$groups" | xargs)      # Trim whitespace

  echo "Processing: '$username' with groups '$groups'" | tee -a "$LOGFILE"

  if [ -z "$username" ] || [ -z "$groups" ]; then
    echo "Skipping invalid entry: '$username' '$groups'" | tee -a "$LOGFILE"
    continue
  fi

  # Check if the user already exists
  if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping." | tee -a "$LOGFILE"
    continue
  fi

  # Create the primary group for the user
  if ! getent group "$username" &>/dev/null; then
    if groupadd "$username"; then
      echo "Group $username created for user $username." | tee -a "$LOGFILE"
    else
      echo "Failed to create group $username. Skipping user $username." | tee -a "$LOGFILE"
      continue
    fi
  fi

  # Process additional groups
  IFS=',' read -ra group_array <<< "$groups"
  group_list=""
  for group in "${group_array[@]}"; do
    group=$(echo "$group" | xargs)  # Trim whitespace
    if [ -z "$group" ]; then
      continue
    fi

    # Create the group if it does not exist
    if ! getent group "$group" &>/dev/null; then
      if groupadd "$group"; then
        echo "Group $group created." | tee -a "$LOGFILE"
      else
        echo "Failed to create group $group. Skipping group addition for $group." | tee -a "$LOGFILE"
        continue
      fi
    fi
    group_list+="$group,"
  done

  # Generate a random password
  PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)

  # Create the user with the primary group and additional groups
  if useradd -m -g "$username" -G "${group_list%,}" -s /bin/bash "$username"; then
    echo "$username:$PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
      echo "User $username created with groups ${group_list%,}." | tee -a "$LOGFILE"
      echo "$username:$PASSWORD" >> "$PASSWORD_FILE"
      chmod 600 "/home/$username"
      chown "$username:$username" "/home/$username"
    else
      echo "Failed to set password for $username." | tee -a "$LOGFILE"
    fi
  else
    echo "Failed to create user $username." | tee -a "$LOGFILE"
  fi

done < "$USERFILE"

echo "User creation process completed." | tee -a "$LOGFILE"
