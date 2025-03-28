#!/bin/bash
set -euo pipefail

# Load environment variables from test.env file
load_env() {
    if [ -f "../test.env" ]; then
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^# && "$line" =~ = ]]; then
                export "$line"
            fi
        done < "../test.env"
        echo "✅ Loaded environment variables"
    else
        echo "⚠️  test.env file not found. Skipping environment loading."
    fi
}

# Convert bytes to human-readable format in MB or GB
humanize_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1073741824 ]; then
         # 1024 * 1024 = 1048576
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    else
        # 1024 * 1024 * 1024 = 1073741824                              
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB" 
    fi
}

# Fetch list of objects from an S3 bucket
get_s3_objects() {
    local bucket=$1
    local prefix=$2
    aws s3api list-objects-v2 \
        --bucket "$bucket" \
        --prefix "$prefix" \
        --output json \
        --query "Contents[*].{Key: Key, Size: Size, LastModified: LastModified}"
}

# Print top N largest objects greater than 1MB
print_top_largest_objects() {
    local objects_json=$1
    local count=${2:-20}

    echo "📊 Top $count largest objects (≥ 1MB):"
    echo "$objects_json" | jq -r '.[] | "\(.Size)\t\(.Key)\t\(.LastModified)"' \
        | awk -F'\t' '$1 >= 1048576 { print }' \
        | sort -nr -k1,1 \
        | head -n "$count" \
        | awk -F'\t' 'BEGIN {
            printf "  %-12s %-60s %s\n", "Size", "Name", "Last Modified"
        } {
            size = $1;
            key = $2;
            mod = $3;
            if (size < 1073741824) {
                human = sprintf("%.2f MB", size/1048576);
            } else {
                human = sprintf("%.2f GB", size/1073741824);
            }
            printf "  %-12s %-60s %s\n", human, key, mod;
        }'
}

# Main logic
main() {
    re_encrypt_env() {
        if [ -f "../test.env" ]; then
            sops -e -i ../test.env
        fi
    }
    trap re_encrypt_env EXIT

    if [ -f "../test.env" ]; then
        sops -d -i ../test.env
    fi
    
    load_env

    # Read arguments from CLI
    local bucket_name=${1:-"iijvn-thanos"}
    local top_n=${2:-20}
    local prefix=""

    echo "🔍 Checking bucket: $bucket_name"
    echo

    OBJECTS=$(get_s3_objects "$bucket_name" "$prefix")
    TOTAL_OBJECTS=$(echo "$OBJECTS" | jq 'length')
    TOTAL_SIZE=$(echo "$OBJECTS" | jq '[.[].Size] | add // 0')

    echo "📦 Total objects : $TOTAL_OBJECTS"
    echo "📏 Total size    : $(humanize_bytes "$TOTAL_SIZE")"
    echo

    print_top_largest_objects "$OBJECTS" "$top_n"
}

main "$@"
