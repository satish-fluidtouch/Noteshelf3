#!/bin/sh

#  myscript_download.sh
#  Noteshelf3
#
#  Created by Akshay on 18/12/23.
#  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.

#!/bin/bash

# URL of the file to download
download_url="https://download.myscript.com/iink/runtime/2.3.0/MyScriptInteractiveInk-Runtime-iOS-2.3.1.zip"

# Destination directory for the unzipped files
destination_directory="MyScriptInteractiveInk-Runtime"

# Remove if already exists
rmdir -f "$destination_directory"

# Create the destination directory if it doesn't exist
mkdir -p "$destination_directory"

# Download the file
echo "Downloading file from $download_url..."
curl -LJO "$download_url"

# Check if the download was successful
if [ $? -eq 0 ]; then
    # Unzip the file to the destination directory
    echo "Unzipping to $destination_directory..."
    unzip -q "*.zip" -d "$destination_directory"

    # Clean up the temporary zip file
    rm temp.zip

    echo "Download and unzip completed successfully."
else
    echo "Error: Unable to download the file."
fi
