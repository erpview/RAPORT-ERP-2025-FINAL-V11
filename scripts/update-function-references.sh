#!/bin/bash

# Script to update function references in SQL files
# Replaces:
# - auth.is_admin with app_functions.is_admin
# - auth.is_editor with app_functions.is_editor
# - auth.is_admin_by_metadata with app_functions.is_admin_by_metadata

echo "Starting to update function references in SQL files..."

# Find all SQL files in the project
SQL_FILES=$(find /Users/erpview/Downloads/RAPORT-ERP-V10/project -name "*.sql")

# Counter for modified files
MODIFIED_COUNT=0

for file in $SQL_FILES; do
  # Create a backup of the original file
  cp "$file" "${file}.bak"
  
  # Replace function references
  sed -i '' 's/auth\.is_admin/app_functions.is_admin/g' "$file"
  sed -i '' 's/auth\.is_editor/app_functions.is_editor/g' "$file"
  sed -i '' 's/auth\.is_admin_by_metadata/app_functions.is_admin_by_metadata/g' "$file"
  
  # Check if file was modified
  if ! cmp -s "$file" "${file}.bak"; then
    echo "Updated: $file"
    MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
  else
    # If not modified, remove the backup
    rm "${file}.bak"
  fi
done

echo "Completed updating function references in $MODIFIED_COUNT SQL files."
