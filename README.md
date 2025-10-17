# Rab Booking 🏖️

A comprehensive booking application for vacation rentals on the island of Rab, Croatia.

[![Flutter](https://img.shields.io/badge/Flutter-3.35.6-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev/)
[![Tests](https://img.shields.io/badge/tests-56%20passing-success.svg)](test/)

## ✨ Features

- 🔐 Authentication with Supabase
- 🔍 Property search with filters
- 📅 Interactive booking calendar
- 💳 Stripe payment integration
- 🏘️ Owner dashboard (CRUD)
- 📱 Responsive design (mobile/tablet/web)
- 🗺️ OpenStreetMap integration
- ⚡ Performance optimized
- 🧪 56+ tests (>50% coverage)

## 🛠️ Tech Stack

**Frontend:** Flutter 3.35.6, Riverpod 3.0.3, GoRouter 16.2.5
**Backend:** Supabase 2.9.1, Stripe 12.0.2
**Maps:** Flutter Map 8.2.2, Geolocator 14.0.2

## 🚀 Quick Start

```bash
# Clone & install
git clone https://github.com/your-org/rab_booking.git
cd rab_booking
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Configure environment
cp .env.example .env.development
# Edit .env.development with your credentials

# Run app
flutter run
```

## 📁 Project Structure

```
lib/
├── core/        # Config, errors, services, utils
├── features/    # Auth, booking, payment, search, etc.
├── shared/      # Models, widgets, repositories
└── main.dart
```

## 📚 Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Architecture patterns
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Deployment guide
- **[TESTING.md](docs/TESTING.md)** - Testing guide
- **[PERFORMANCE_GUIDE.md](docs/PERFORMANCE_GUIDE.md)** - Performance tips
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues

## 🧪 Testing

```bash
flutter test                    # Run all tests
flutter test --coverage         # With coverage
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/name`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/name`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file for details.

---

**Built with ❤️ using Flutter**
