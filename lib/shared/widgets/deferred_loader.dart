import 'package:flutter/material.dart';
import 'loading_overlay.dart';

/// A widget that handles the loading of deferred libraries.
///
/// Usage:
/// ```dart
/// import 'my_heavy_widget.dart' deferred as heavy;
///
/// DeferredLoader(
///   loadLibrary: heavy.loadLibrary,
///   builder: () => heavy.MyHeavyWidget(),
/// )
/// ```
class DeferredLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? placeholder;

  const DeferredLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.placeholder,
  });

  @override
  State<DeferredLoader> createState() => _DeferredLoaderState();
}

class _DeferredLoaderState extends State<DeferredLoader> {
  // Use a future that handles the loading state
  late Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load module: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _libraryFuture = widget.loadLibrary();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return widget.builder();
        }

        // Show loading state while fetching the JS chunk
        return widget.placeholder ??
            const Scaffold(body: LoadingOverlay(message: 'Loading module...'));
      },
    );
  }
}
