#!/bin/sh

# Write a line to a file, but only if the line does not already exist.
safe_write() {
  if ! grep -sFxq "$1" "$2"; then
    echo "$1" >> "$2"
  fi
}

if [ -n "$SSH_PASSWORD" ]; then
  echo "Setting SSH password..."
  echo "root:$SSH_PASSWORD" | chpasswd
  sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' \
    /etc/ssh/sshd_config
fi

if [ -n "$SSH_AUTHORIZED_KEY" ]; then
  echo "Setting SSH authorized_keys..."
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  echo "$SSH_AUTHORIZED_KEY" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

if [ -n "$IRSSI_REPO" ]; then
  echo "Fetching irssi configuration from git repo..."
  keyfile=/root/repo_key

  if [ -n "$IRSSI_REPO_KEY" ]; then
    echo "$IRSSI_REPO_KEY" > $keyfile
    chmod 600 $keyfile
  fi

  apk --no-cache add git

  GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null \
                       -o StrictHostKeyChecking=no \
                       -o IdentityFile=$keyfile" \
                       git clone $IRSSI_REPO /root/.irssi

  [ -f "$keyfile" ] && rm $keyfile
fi

if [ -n "$ENABLE_MOSH" ]; then
  echo "Enabling mosh support..."
  apk --no-cache add mosh
fi

if [ -n "$ENABLE_SCRIPTS" ]; then
  echo "Enabling irssi script support..."
  apk --no-cache add irssi-perl
  safe_write "load perl" /root/.irssi/startup
fi

echo "READY!"

exec "$@"
