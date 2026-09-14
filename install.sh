#!/bin/bash
set -euo pipefail

TOMCAT_VERSION="9.0.113"
TOMCAT_USER="tomcat"
TOMCAT_DIR="/opt/tomcat"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "Run this script as root or with sudo."
	exit 1
fi

yum update -y
yum install -y java-17-amazon-corretto wget tar
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"

id "${TOMCAT_USER}" >/dev/null 2>&1 || useradd --system --home-dir "${TOMCAT_DIR}" --shell /sbin/nologin "${TOMCAT_USER}"

mkdir -p "${TOMCAT_DIR}"
wget -q "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" -O /tmp/tomcat.tar.gz
tar -xzf /tmp/tomcat.tar.gz --strip-components=1 -C "${TOMCAT_DIR}"
rm -f /tmp/tomcat.tar.gz

chown -R "${TOMCAT_USER}:${TOMCAT_USER}" "${TOMCAT_DIR}"
chmod +x "${TOMCAT_DIR}/bin"/*.sh

cat > /etc/systemd/system/tomcat.service <<EOF
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_USER}
Environment="JAVA_HOME=${JAVA_HOME}"
Environment="CATALINA_HOME=${TOMCAT_DIR}"
Environment="CATALINA_BASE=${TOMCAT_DIR}"
ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tomcat

echo "Java version:"
java -version
echo "Tomcat status:"
systemctl --no-pager --full status tomcat
