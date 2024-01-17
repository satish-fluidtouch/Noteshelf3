#!/bin/sh

#  myscript_download.sh
#  Noteshelf3
#
#  Created by Akshay on 18/12/23.
#  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
#!/bin/bash

version="2.3.2"

echo "Started running..........."

# Destination directory for the unzipped files
destination_directory="$1/MyScriptInteractiveInk-Runtime"
echo "destination_directory $destination_directory"

checksum_file="$1/checksums.md5"
compare_checksums="$1/compare_checksums.md5"


#download only if something gets changed.
find "$destination_directory" -type f -not -name '.DS_Store' -exec md5 {} + > "$compare_checksums"

diff "$checksum_file" "$compare_checksums" > /dev/null
if [ $? == 0 ] ; then
    # print error to STDERR
    echo "There's no change"
    rm -f "$compare_checksums"
    exit 0
fi

rm -f "$compare_checksums"

#--------------------

# URL of the file to download
download_url="https://download.myscript.com/iink/runtime/2.3.0/MyScriptInteractiveInk-Runtime-iOS-$version.zip"

# Zip file name
zip_file_name="MyScriptInteractiveInk-Runtime-iOS-$version.zip"


# Clean up the destination directory and the zip file if they exist
echo "Cleaning up existing My Script files..."
rm -rf "$destination_directory"
rm -f "$zip_file_name"

# Create the destination directory
mkdir -p "$destination_directory"

# Download the file using curl
echo "Downloading file from $download_url..."
curl -LJO "$download_url"

# Check if the download was successful
if [ $? -eq 0 ]; then
    # Unzip the file to the destination directory
    echo "Unzipping to $destination_directory..."
    unzip -q "$zip_file_name" -d "$destination_directory"

    echo "Download and unzip completed successfully."
    find "$destination_directory" -type f -exec md5 {} + > "$checksum_file"
    echo "Check sum generated."

else
    echo "Error: Unable to download the file from $download_url."
fi

# Clean up the downloaded zip file, whether successful or failed
rm -f "$zip_file_name"
