#!/bin/bash
for file in $(find lib functions/src -type f -name "*.dart" -o -name "*.ts"); do
  if grep -q -E 'catch[[:space:]]*\([a-zA-Z_]+\)[[:space:]]*\{[[:space:]]*\}' "$file"; then
    echo "Processing $file"
    if [[ "$file" == *.dart ]]; then
      # Need to make sure LoggingService is imported if we add it
      if ! grep -q "LoggingService" "$file"; then
        sed -i '1i import '\''package:bookbed/core/services/logging_service.dart'\'';' "$file"
      fi
      # Then replace
      sed -i -E 's/catch[[:space:]]*\(([a-zA-Z_]+)\)[[:space:]]*\{[[:space:]]*\}/catch (\1, stackTrace) { LoggingService.logError("Error suppressed", \1, stackTrace); }/g' "$file"
    elif [[ "$file" == *.ts ]]; then
      # Need to make sure logError is imported from logger.ts
      if ! grep -q "logError" "$file"; then
        # This is trickier to add to TS reliably, let's just do it manually if found
        echo "Needs manual update in TS: $file"
      fi
      sed -i -E 's/catch[[:space:]]*\(([a-zA-Z_]+)\)[[:space:]]*\{[[:space:]]*\}/catch (\1) { logError("Error suppressed", \1); }/g' "$file"
    fi
  fi
done
