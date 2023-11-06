#### Verify Script

# MIT
# Source https://github.com/yonixw/timestamp-sign-files
# Based On https://weisser-zwerg.dev/posts/trusted_timestamping/ (https://archive.is/gPxbR)

##################

set -e

source ssl_ts.ENV

export VERIFY_HASH=$(openssl dgst -sha3-256 tha_rami.zip | sed 's|^.*= ||')
echo "[*] Got hash (SHA3_256): $VERIFY_HASH."

echo ""
echo "[*] Download Apple chain to verify"
curl -q --remote-name https://www.apple.com/certificateauthority/AppleTimestampCA.cer
openssl x509 -in AppleTimestampCA.cer -noout -issuer

curl -q --remote-name https://www.apple.com/appleca/AppleIncRootCertificate.cer
openssl x509 -inform der -in AppleIncRootCertificate.cer -out AppleIncRootCertificate.pem
openssl x509 -in AppleIncRootCertificate.pem -noout -issuer

echo ""
echo "[*] Export verification chain and token"
openssl ts -reply -in $TS_FILENAME -token_out -out token.tk
openssl pkcs7 -inform DER -in token.tk -print_certs -outform PEM -out certificatechain.pem

echo ""
echo "[*] Verify even if cert expired"
openssl ts -verify -no_check_time -digest $VERIFY_HASH \
    -in $TS_FILENAME -CAfile AppleIncRootCertificate.pem -untrusted certificatechain.pem
  
echo ""
echo "[*] Verify chain from response, given we trust apple CA"
openssl ts -verify -digest $VERIFY_HASH -in $TS_FILENAME \
    -CAfile AppleIncRootCertificate.pem -untrusted certificatechain.pem

echo ""
echo "[*] Verify with our own downloaded chain"
openssl ts -verify -digest $VERIFY_HASH -in $TS_FILENAME \
    -CAfile AppleTimestampCA.cer -partial_chain
openssl ts -verify -digest $VERIFY_HASH -in $TS_FILENAME \
    -CAfile AppleIncRootCertificate.pem -untrusted AppleTimestampCA.cer

echo ""
echo "[*]  Print verified time info"
openssl ts -reply -in $TS_FILENAME -text | grep -iE 'Time|Accuracy'
echo "SHA3-256: $VERIFY_HASH"

echo ""
echo "[*] Removing artifacts"
[[ ! -z "$CLEAN_CERS" ]] && rm token.tk AppleTimestampCA.cer \
    AppleIncRootCertificate.cer \
    certificatechain.pem AppleIncRootCertificate.pem

echo ""
echo "[*] DONE!"