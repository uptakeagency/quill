#!/bin/bash
set -euo pipefail

# Creates a self-signed "Quill Development" certificate for stable code signing.
# This prevents TCC permissions (Accessibility, Screen Recording) from resetting on each rebuild.

CERT_NAME="Quill Development"

# Check if already exists
if security find-identity -v -p codesigning 2>/dev/null | grep -q "${CERT_NAME}"; then
    echo "Certificate '${CERT_NAME}' already exists and is trusted."
    exit 0
fi

echo "Creating self-signed code signing certificate: ${CERT_NAME}"

TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

# Generate certificate
openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "${TMPDIR}/key.pem" -out "${TMPDIR}/cert.pem" \
    -subj "/CN=${CERT_NAME}" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" 2>/dev/null

# Export as p12 (legacy format required for macOS Keychain)
openssl pkcs12 -export -out "${TMPDIR}/dev.p12" \
    -inkey "${TMPDIR}/key.pem" -in "${TMPDIR}/cert.pem" \
    -passout pass:quilldev -legacy 2>/dev/null

# Import to login keychain
security import "${TMPDIR}/dev.p12" \
    -k ~/Library/Keychains/login.keychain-db \
    -T /usr/bin/codesign -P "quilldev"

# Trust for code signing
security add-trusted-cert -d -r trustRoot -p codeSign \
    -k ~/Library/Keychains/login.keychain-db "${TMPDIR}/cert.pem"

echo ""
echo "Certificate '${CERT_NAME}' created and trusted."
echo "TCC permissions will now persist across rebuilds."
