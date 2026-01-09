// This script is embedded in the Flutter web app (the iframe content).
// It sends the content height to the parent window.

window.addEventListener('load', () => {
  // Use ResizeObserver to detect content height changes.
  const observer = new ResizeObserver(entries => {
    for (let entry of entries) {
      const height = entry.contentRect.height;
      if (height > 0) {
        window.parent.postMessage({
          type: 'resize',
          height: height
        }, '*');
      }
    }
  });

  // Observe the Flutter scene.
  const flutterScene = document.querySelector('flt-scene');
  if (flutterScene) {
    observer.observe(flutterScene);
  }
});
