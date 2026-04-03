#!/bin/bash
# Remove unnecessary dart:async imports
sed -i '/import '\''dart:async'\'';/d' lib/features/widget/presentation/providers/additional_services_provider.dart
# The double import
sed -i '2d' lib/features/widget/presentation/screens/booking_widget_screen.dart

# Move import below library directive in stub and web files
# Since we just added dart:async to the first line, we need to remove it and put it after the library statement
sed -i '1d' lib/features/widget/utils/ics_download_stub.dart
sed -i '/library /a import '\''dart:async'\'';' lib/features/widget/utils/ics_download_stub.dart

sed -i '1d' lib/features/widget/utils/ics_download_web.dart
sed -i '/library /a import '\''dart:async'\'';' lib/features/widget/utils/ics_download_web.dart

# Also need to run tests in functions
cd functions && npm test
