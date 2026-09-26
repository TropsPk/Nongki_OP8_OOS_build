#!/usr/bin/env bash

if [ -f have_error ]; then
    echo "Error detected by check_error.sh，Extracting relevant files..."

    grep -iE "error:|undefined reference to" error.log > error_lines.txt

    files=$(awk -F: '{print $1}' error_lines.txt | sort | uniq)

    tmp_dir="error_files"
    mkdir -p "$tmp_dir"

    for file in $files; do
        clean_path=$(echo "$file" | sed 's#^\.\./##')

        src_file="$clean_path"

        if [ -f "$src_file" ]; then
            mkdir -p "$tmp_dir/$(dirname "$clean_path")"
            cp "$src_file" "$tmp_dir/$clean_path"
        else
            echo "Warning：File $src_file not exist，Skipped."
        fi
    done

    zip_file="error_files.zip"
    zip -r "$zip_file" "$tmp_dir"

    echo "Related files have been packaged into $zip_file"

    rm -rf "$tmp_dir" error_lines.txt
else
    echo "No error detected by check_error.sh，compile successfully or not have the error."
fi
