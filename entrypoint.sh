#!/usr/bin/env bash
set -euxo pipefail

tok_provider=${TOK_PROVIDER:-}
drupal_root=${DRUPAL_ROOT:-docroot}


# Invoke the environment variables into this sshd process
while read -r line; do
  export $line 
done < /tokaido/config/.env

# If we're running on a local Tokaido platform, just set up one user SSH key
if [[ -z "$tok_provider" ]]; then
  echo "Adding your local SSH key to the 'tok' user"
  username="tok"
  cp /tokaido/site/.tok/local/ssh_key.pub /home/"$username"/.ssh/authorized_keys
  # Set up environment variables for the user
  echo "Setting up environment variables for $username"
  echo "PATH=$PATH:/usr/local/bin" > /home/"$username"/.ssh/environment
  cat /tokaido/config/.env >> /home/"$username"/.ssh/environment
  echo "APP_ENV=${APP_ENV:-unknown}" >> /home/"$username"/.ssh/environment
  echo "PROJECT_NAME=${PROJECT_NAME:-}" >> /home/"$username"/.ssh/environment
  echo "DRUPAL_ROOT=${drupal_root}" >> /home/"$username"/.ssh/environment
  echo "VARNISH_PURGE_KEY=${VARNISH_PURGE_KEY:-}" >> /home/"$username"/.ssh/environment
  chmod 600 /home/"$username"/.ssh/environment        
  chmod 600 /home/"$username"/.ssh/authorized_keys
  chown "$username":root /home/"$username"/.ssh -R 
# If we're running in a Tokaido production environment, we'll create multiple users
# and also set up some additional configuration that they'll need
else 
  # Copy the host's SSH key set if it exists
  if [[ -d "/tokaido/config/ssh_host_keys" ]]; then
    cp /tokaido/config/ssh_host_keys/* /etc/ssh/
  fi
  # Create user accounts based on the ssh keys present  
  for f in /tokaido/config/users/*; 
  do
    [[ -e $f ]] || { echo "ERROR: No ssh keys found. Can't create users"; exit 1; }
    username=${f##*/}
    useradd -s /bin/bash -g web -m -K UMASK=002 "$username"
    usermod -p '*' "$username"
    tee /home/"$username"/.ssh/authorized_keys < /tokaido/config/users/"$username"
    chmod 700 /home/"$username"
    chmod 700 /home/"$username"/.ssh
    chmod 600 /home/"$username"/.ssh/authorized_keys
    chown "$username":root /home/"$username"/ -R

    #Set up environment variables for the user
    echo "Setting up environment variables for $username"
    echo "PATH=$PATH:/usr/local/bin" > /home/"$username"/.ssh/environment
    cat /tokaido/config/.env >> /home/"$username"/.ssh/environment
    echo "APP_ENV=${APP_ENV:-unknown}" >> /home/"$username"/.ssh/environment
    echo "PROJECT_NAME=${PROJECT_NAME:-}" >> /home/"$username"/.ssh/environment
    echo "DRUPAL_ROOT=${drupal_root}" >> /home/"$username"/.ssh/environment
    echo "TOK_PROVIDER=${TOK_PROVIDER:-}" >> /home/"$username"/.ssh/environment
    echo "BACKUPS_BUCKET=${BACKUPS_BUCKET:-}" >> /home/"$username"/.ssh/environment
    echo "VARNISH_PURGE_KEY=${VARNISH_PURGE_KEY:-}" >> /home/"$username"/.ssh/environment

    # If a custom environment variable path exists, then inject those values
    if [[ -d "/tokaido/config/custom-env-vars" ]]; then
      for e in /tokaido/config/custom-env-vars/*; 
      do
        echo "${e##*/}"=$(cat $e) >> /home/"$username"/.ssh/environment
      done
    fi

    chmod 600 /home/"$username"/.ssh/environment
    chown "$username" /home/"$username"/.ssh/environment
    
    # Set up backups profile for this user to access (if relevant)
    if [ "$tok_provider" = "technocrat" ]; then
      echo "Setting up backups AWS profile for $username"
      mkdir /home/"$username"/.aws
      cat <<EOF > /home/"$username"/.aws/credentials
[backups]
aws_access_key_id = $BACKUPS_ACCESS_KEY
aws_secret_access_key = $BACKUPS_SECRET_KEY
region = $BACKUPS_AWS_REGION
EOF
    fi

    # Add json log viewer formatting options
    cat <<EOF > /home/"$username"/.json-log-viewer
[transform]
timestamp=time
level=status
message=path
extra=$
EOF

  done

  # Give users read access to the environment file
  chown tok:web /tokaido/config/.env
  chmod 0750 /tokaido/config/.env
fi

# Start SSH server
/usr/sbin/sshd -D -e
