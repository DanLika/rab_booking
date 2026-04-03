#!/bin/bash
for file in $(find lib -type f -name "*.dart"); do
  if grep -q "LoggingService.logError(\"Error suppressed\"" "$file"; then
    echo "Fixing $file"
    # Replace catch (_, stackTrace) with catch (e, stackTrace)
    sed -i 's/catch (_, stackTrace)/catch (e, stackTrace)/g' "$file"
    # Replace logError("Error suppressed", _) with logError('Error suppressed', e, stackTrace)
    sed -i "s/LoggingService.logError(\"Error suppressed\", _, stackTrace)/LoggingService.logError('Error suppressed', e, stackTrace)/g" "$file"

    # We also need to add 'import "dart:async";' if we use unawaited, but it's easier to just await the logError
    sed -i "s/} catch (e, stackTrace) { LoggingService.logError/} catch (e, stackTrace) { await LoggingService.logError/g" "$file"
    # Fix the cases where await isn't allowed (sync contexts) by checking if we have unawaited_futures errors
  fi
done
