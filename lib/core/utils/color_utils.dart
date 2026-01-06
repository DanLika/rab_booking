import 'package:flutter/material.dart';

/// A utility class for color-related operations.
class ColorUtils {
  /// Determines the best contrasting text color (black or white) for a given background color.
  ///
  /// This method calculates the luminance of the [backgroundColor] and returns
  /// [Colors.white] if the background is dark, and [Colors.black] if the background is light.
  /// This ensures high contrast and readability for text on colored backgrounds.
  ///
  /// The luminance threshold is set to 0.5, which is a common value for this calculation.
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate the luminance of the color.
    // The formula for relative luminance is L = 0.2126*R + 0.7152*G + 0.0722*B
    // where R, G, and B are the linear RGB components.
    // For sRGB, a simpler and effective approach is to use computeLuminance().
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}
