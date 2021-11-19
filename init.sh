#!/bin/bash

chmod +x /bin/press_to_exit.sh
useradd -s /bin/press_to_exit.sh -p $(date +%s | sha256sum | base64 | head -c 32) $BASTION_USER

rm -rf /etc/ssh/ssh_host_*

echo -e "$BASTION_SSH_HOST_ED25519_KEY" > /etc/ssh/ssh_host_ed25519_key
chmod 600 /etc/ssh/ssh_host*

TRUSTED_PUBKEY=$(curl $TP_URL)

sed -i '/^TrustedUserCAKeys/d' /etc/ssh/sshd_config
sed -i '/^AuthorizedPrincipalsFile/d' /etc/ssh/sshd_config
rm -rf /etc/ssh/sshd_config
tee -a /etc/ssh/sshd_config << EOF
AllowAgentForwarding no
AllowTcpForwarding yes
AllowUsers $BASTION_USER
AuthorizedPrincipalsFile /etc/ssh/principals
ChallengeResponseAuthentication no
ClientAliveCountMax 240
ClientAliveInterval 120
HostKey /etc/ssh/ssh_host_ed25519_key
PasswordAuthentication no
TrustedUserCAKeys /etc/ssh/trusted
#UsePAM no
X11Forwarding no
EOF
tee /etc/ssh/principals << EOF
emergency
$PTZ_ROLE
EOF

tee /etc/ssh/trusted << EOF
$TRUSTED_PUBKEY
EOF

echo starting health check server
python3 -m http.server -d web > /dev/null 2>&1 &

/usr/sbin/sshd -e -D -f /etc/ssh/sshd_config