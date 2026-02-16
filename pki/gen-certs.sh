#!/bin/sh
set -eu

echo "Starting certificate generation..."

# Ensure openssl is installed
if ! command -v openssl >/dev/null 2>&1; then
  echo "Installing openssl..."
  apk add --no-cache openssl
fi

cd /pki

SERVER_CN="${SERVER_CN:-jenkins.lab.local}"

if [ -f ca.cert.pem ] && [ -f server.cert.pem ]; then
  echo "PKI already exists, skipping generation."
  exit 0
fi

echo "Generating CA..."
openssl genrsa -out ca.key.pem 4096
openssl req -x509 -new -nodes -key ca.key.pem \
  -sha256 -days 3650 \
  -subj "/CN=Lab Private CA" \
  -out ca.cert.pem

echo "Creating server extension file..."
cat > server.ext <<EOF
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${SERVER_CN}
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

echo "Generating server key and CSR..."
openssl genrsa -out server.key.pem 2048
openssl req -new -key server.key.pem \
  -subj "/CN=${SERVER_CN}" \
  -out server.csr.pem

echo "Signing server certificate..."
openssl x509 -req -in server.csr.pem \
  -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
  -out server.cert.pem \
  -days 825 -sha256 -extfile server.ext

echo "Setting permissions..."
chmod 644 ca.cert.pem server.cert.pem server.key.pem

echo "Certificates generated successfully in /pki"
ls -l /pki
