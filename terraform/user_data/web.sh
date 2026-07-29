#!/usr/bin/env bash
set -euo pipefail

HOSTNAME_VALUE="${hostname}"

hostnamectl set-hostname "$HOSTNAME_VALUE"
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends apache2 ca-certificates curl jq

cat > /var/www/html/index.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Authorized Security Lab</title>
</head>
<body>
  <h1>Authorized Security Lab</h1>
  <p>Host: $HOSTNAME_VALUE</p>
  <p>The infrastructure is ready. Install DVWA manually only in an isolated and authorized lab.</p>
</body>
</html>
HTML

systemctl enable apache2
systemctl restart apache2
