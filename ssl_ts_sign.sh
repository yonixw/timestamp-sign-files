
#### Sign Generation Script

# MIT
# Source https://github.com/yonixw/timestamp-sign-files
# Based On https://weisser-zwerg.dev/posts/trusted_timestamping/ (https://archive.is/gPxbR)

set -e

source ssl_ts.ENV

echo "[*] Filename=$FILENAME"

echo ""
echo "[*] Openssl version"
openssl version

export HASH_SHA3_256=$(openssl dgst -sha3-256 $FILENAME | sed 's|^.*= ||')
echo ""
echo "[*] Got hash (SHA3_256): $HASH_SHA3_256."

echo ""
echo "[*] Creating request with our hash"
openssl ts -query -digest "$HASH_SHA3_256" \
    -sha256 -cert -out ts_req.tsq

echo ""
echo "[*] Getting signed response from apple ts server"
curl http://timestamp.apple.com/ts01 \
    -H 'Content-Type: application/timestamp-query' -s -S \
    --data-binary "@ts_req.tsq" -o "$TS_FILENAME"

echo ""
echo "[*] Checking signed date"
openssl ts -reply -in "$TS_FILENAME" -text

echo ""
echo "[*] Removing certificate artifacts"
[[ ! -z "$CLEAN_CERS" ]] && rm ts_req.tsq

echo ""
echo "[*] DONE!"