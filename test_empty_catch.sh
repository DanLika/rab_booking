#!/bin/bash
for file in $(find lib functions/src -type f -name "*.dart" -o -name "*.ts"); do
  if grep -q -E 'catch[[:space:]]*\([a-zA-Z_]+\)[[:space:]]*\{[[:space:]]*\}' "$file"; then
    echo "Found empty catch block in $file"
    grep -n -E 'catch[[:space:]]*\([a-zA-Z_]+\)[[:space:]]*\{[[:space:]]*\}' "$file"
  fi
done
