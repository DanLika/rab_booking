#!/bin/bash
for file in $(find lib -type f -name "*.dart"); do
  if grep -q "await LoggingService.logError" "$file"; then
    echo "Fixing await in $file"
    # Replace await with unawaited for the specific lines that were added
    sed -i "s/} catch (e, stackTrace) { await LoggingService.logError/} catch (e, stackTrace) { unawaited(LoggingService.logError/g" "$file"
    sed -i "s/stackTrace); }/stackTrace)); }/g" "$file"

    # We also need to add 'import "dart:async";' if we use unawaited
    if ! grep -q "import 'dart:async';" "$file"; then
      sed -i '1i import '\''dart:async'\'';' "$file"
    fi
  fi
done
