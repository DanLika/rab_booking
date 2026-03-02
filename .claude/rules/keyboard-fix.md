---
paths:
  - "lib/**/presentation/screens/**"
  - "web/index.html"
  - "lib/core/utils/keyboard_dismiss*"
---

# Android Chrome Keyboard Fix (Flutter #175074)

**Problem**: Na Android Chrome, kada korisnik zatvori tastaturu BACK tipkom, Flutter Web (CanvasKit) ne recalculate-a layout i ostavlja bijeli prostor.

## Rješenje (3 komponente)

### 1. JavaScript fix u `web/index.html`

```javascript
// "Jiggle" method - force Flutter to recalculate
function forceFlutterRecalc() {
  var glassPane = document.querySelector('flt-glass-pane');
  glassPane.style.width = 'calc(100% - 1px)';
  glassPane.style.height = 'calc(100% - 1px)';
  void glassPane.offsetHeight; // Force reflow
  window.dispatchEvent(new Event('resize'));
  requestAnimationFrame(function() {
    glassPane.style.width = '100%';
    glassPane.style.height = '100%';
    window.dispatchEvent(new Event('resize'));
  });
}
```

### 2. Dart mixin za svaki screen sa input poljima

```dart
import '../../../../core/utils/keyboard_dismiss_fix_mixin.dart';

class _MyScreenState extends State<MyScreen> with AndroidKeyboardDismissFix {

@override
Widget build(BuildContext context) {
  return KeyedSubtree(
    key: ValueKey('my_screen_$keyboardFixRebuildKey'),
    child: Scaffold(
      resizeToAvoidBottomInset: true, // NAMJERNO true - mixin radi ZAJEDNO sa Flutter native ponašanjem
    ),
  );
}
```

### 3. Meta tag u `web/index.html`

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, interactive-widget=resizes-content">
```

**NAPOMENA**: `resizeToAvoidBottomInset: true` — mixin NE zamjenjuje Flutter-ovo native ponašanje, već ga DOPUNJUJE.

## Fajlovi

| Fajl | Svrha |
|------|-------|
| `web/index.html` | JavaScript "jiggle" fix + visualViewport listener |
| `keyboard_dismiss_fix_mixin.dart` | Dart mixin sa `keyboardFixRebuildKey` |
| `keyboard_dismiss_fix_web.dart` | Web implementacija (JS interop) |
| `keyboard_dismiss_fix_stub.dart` | Stub za non-web platforme |

## KADA KREIRAŠ NOVI SCREEN SA INPUT POLJIMA

1. Dodaj `with AndroidKeyboardDismissFix` mixinu
2. Wrap `Scaffold` u `KeyedSubtree(key: ValueKey('screen_name_$keyboardFixRebuildKey'), ...)`
3. Postavi `resizeToAvoidBottomInset: true` na Scaffold

## Screens sa mixinom (referenca)

- `enhanced_login_screen.dart`, `enhanced_register_screen.dart`
- `forgot_password_screen.dart`, `change_password_screen.dart`
- `edit_profile_screen.dart`, `bank_account_screen.dart`
- `property_form_screen.dart`, `unit_form_screen.dart`
- `step_1_basic_info.dart`, `step_2_capacity.dart`, `step_3_pricing.dart`
