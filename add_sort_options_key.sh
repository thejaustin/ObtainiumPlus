#!/bin/bash

# Script to add "sortOptions" key to all translation files
TRANSLATION_DIR="/data/data/com.termux/files/home/Obtainium+/Obtainium/assets/translations"

for file in "$TRANSLATION_DIR"/*.json; do
    if [[ $(basename "$file") != "package-lock.json" && $(basename "$file") != "package.json" ]]; then
        echo "Updating $file"
        
        # Add the sortOptions key before the settings key
        sed -i.bak 's/"defaultSort": "[^"]*"/&,\n    "sortOptions": "Sort Options"/' "$file"
        
        # Clean up backup file
        rm "${file}.bak"
    fi
done

echo "All translation files updated!"