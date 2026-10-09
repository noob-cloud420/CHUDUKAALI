#!/bin/bash
set -e

USER_NAME="noobster"
SSH_PASS="@noobsterrr"
VNC_PASS="noobster"
VNC_GEOM="1280x720"
HOME_DIR="/home/$USER_NAME"

echo "Creating user..."
id "$USER_NAME" >/dev/null 2>&1 || useradd -m -s /bin/bash "$USER_NAME"
echo "$USER_NAME:$SSH_PASS" | chpasswd
usermod -aG sudo "$USER_NAME"
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
chmod 440 "/etc/sudoers.d/$USER_NAME"

echo "Configuring SSH (port 2222)..."
mkdir -p /run/sshd /etc/ssh/sshd_config.d
ssh-keygen -A
cat > /etc/ssh/sshd_config.d/railway.conf <<CONF
Port 2222
ListenAddress 0.0.0.0
PasswordAuthentication yes
PermitRootLogin no
UsePAM yes
CONF
/usr/sbin/sshd -t

echo "Configuring VNC..."
mkdir -p "$HOME_DIR/.vnc"
cat > "$HOME_DIR/.vnc/xstartup" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x "$HOME_DIR/.vnc/xstartup"
printf '%s' "$VNC_PASS" | vncpasswd -f > "$HOME_DIR/.vnc/passwd"
chmod 600 "$HOME_DIR/.vnc/passwd"
chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR/.vnc"

mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

echo "Starting VNC on port 5901..."
su - "$USER_NAME" -c "vncserver :1 -localhost no -geometry $VNC_GEOM -depth 24 -SecurityTypes VncAuth" \
    || echo "WARNING: vncserver failed, check $HOME_DIR/.vnc/*.log"

echo "======================================"
echo " READY  SSH: 2222   VNC: 5901"
echo "======================================"

exec /usr/sbin/sshd -D -e
