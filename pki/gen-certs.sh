#!/bin/sh
set -eu

apk add --no-cache openssl

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

openssl genrsa -out server.key.pem 2048
openssl req -new -key server.key.pem \
  -subj "/CN=${SERVER_CN}" \
  -out server.csr.pem

openssl x509 -req -in server.csr.pem \
  -CA ca.cert.pem -CAkey ca.key.pem -CAcreateserial \
  -out server.cert.pem \
  -days 825 -sha256 -extfile server.ext

echo "Certificates generated in ./pki-data"
