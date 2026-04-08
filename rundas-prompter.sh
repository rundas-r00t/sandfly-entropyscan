###entropy script written by Michael Mullins (aka Rundas) 2026
###this tool scans a given path for entropy of X or greater and output the results to a file

#!/bin/bash

cat << "EOF"
 ___      ___  __   __   __          __   __                  ___  __  
|__  |\ |  |  |__) /  \ |__) \ /    /__` /  `  /\  |\ | |\ | |__  |__) 
|___ | \|  |  |  \ \__/ |     |     .__/ \__, /~~\ | \| | \| |___ |  \ 

Entropy scan wrapper for sandfly-entropyscan
EOF

read -rp "Enter path to scan: " SCAN_PATH
read -rp "Enter output directory: " OUTPUT_DIR
read -rp "Enter output filename: " OUTPUT_FILE
read -rp "Enter entropy level [default: 6]: " ENTROPY_LEVEL

ENTROPY_LEVEL=${ENTROPY_LEVEL:-6}
mkdir -p "$OUTPUT_DIR"

echo "[*] Scanning: $SCAN_PATH"
echo "[*] Entropy: $ENTROPY_LEVEL"
echo "[*] Output: $OUTPUT_DIR/$OUTPUT_FILE"
echo "[*] Running..."

./sandfly-entropyscan -dir "$SCAN_PATH" -entropy "$ENTROPY_LEVEL" \
| awk '
BEGIN { RS=""; FS="\n" }
{
    path=""
    for (i=1; i<=NF; i++) {
        if ($i ~ /^path:/) {
            split($i, a, " ")
            path=a[2]
        }
    }

    if (path != "") {
        cmd = "file -b \"" path "\""
        cmd | getline type
        close(cmd)

        if (type !~ /PNG image|Web Open Font|JPEG image|Zip archive|gzip compressed|bzip2 compressed|ELF|shared object|archive|certificate/) {
            print $0 "\n"
        }
    }
}
' > "$OUTPUT_DIR/$OUTPUT_FILE"

# ===== Change ownership to the user who invoked sudo =====
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_GROUP=$(id -gn "$SUDO_USER")
else
    TARGET_USER=$(id -un)
    TARGET_GROUP=$(id -gn)
fi

# Only attempt chown if running as root
if [ "$(id -u)" -eq 0 ]; then
    chown "$TARGET_USER":"$TARGET_GROUP" "$OUTPUT_DIR/$OUTPUT_FILE"
fi

echo "[+] Done."
echo "[+] Results saved to: $OUTPUT_DIR/$OUTPUT_FILE"
