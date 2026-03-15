# 🚲 Campus Bike Rental – IITGN

A complete Flutter application for renting and listing bikes on the IIT Gandhinagar campus. Built with eco-friendly green Material Design 3 and clean architecture.

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, theme configuration
├── models/
│   ├── bike.dart               # Bike data model + sample data
│   └── ride.dart               # Ride data model + sample history
├── services/
│   ├── api_service.dart        # Bike, ride and payment API calls
│   └── auth_service.dart       # Login, OTP, registration logic
├── screens/
│   ├── login_screen.dart       # Email login/register (IITGN only)
│   ├── otp_screen.dart         # 6-digit OTP verification
│   ├── home_screen.dart        # Main tab screen + bike list
│   ├── bike_details_screen.dart# Bike info + Start Ride
│   ├── unlock_pin_screen.dart  # 4-digit PIN + countdown timer
│   ├── active_ride_screen.dart # Live ride tracker
│   ├── payment_screen.dart     # Ride summary + payment
│   ├── ride_history_screen.dart# Past ride list
│   ├── map_screen.dart         # Campus map with bike stands
│   ├── list_your_bike_screen.dart # Submit personal bike
│   └── profile_screen.dart    # User stats + settings
└── widgets/
    └── bike_card.dart          # Reusable bike list tile
```

---

## ✨ Features

| Screen | Features |
|--------|----------|
| **Login** | Email field, IITGN domain validation, Login/Register toggle |
| **OTP** | 6-box digit input, auto-advance, resend timer, verification |
| **Home** | Greeting, search bar, live bike list, availability badges, bottom nav |
| **Bike Details** | Bike icon, battery indicator, stats, Start Ride button |
| **Unlock PIN** | Random 4-digit PIN, 60s countdown, animated pulse, regenerate |
| **Active Ride** | Live timer, distance + cost counter, CO₂ saved, End Ride |
| **Payment** | Ride summary, UPI/Wallet/Card selection, processing flow |
| **History** | Rides with date, duration, distance, cost; summary stats |
| **Map** | Custom painted campus map, station markers, bottom station chips |
| **List Bike** | Bike ID, station dropdown, image picker, submit flow |
| **Profile** | Avatar, ride stats, account menu, logout confirm |

---

## 🎨 Theme

- **Primary**: `#2E7D32` (Deep Green)
- **Secondary**: `#66BB6A` (Light Green)
- **Surface**: `#F1F8E9` (Pale Green)
- **Font**: Google Fonts – Poppins
- **Design**: Material Design 3 with `useMaterial3: true`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### Installation

```bash
# Clone / copy the project
cd campus_bike_rental

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### Demo Credentials
- **Email**: any `@iitgn.ac.in` address (e.g. `devraj@iitgn.ac.in`)
- **OTP**: any 6-digit number (e.g. `123456`)

---

## 📦 Dependencies

```yaml
google_fonts: ^6.1.0        # Poppins font
flutter_animate: ^4.3.0     # Smooth animations
percent_indicator: ^4.2.3   # Battery/progress bars
image_picker: ^1.0.7        # Bike photo upload
intl: ^0.19.0               # Date formatting
```

---

## 🏗️ Architecture

- **Models**: Plain Dart classes with static sample data factories
- **Services**: Async methods simulating REST API calls with `Future.delayed`
- **Screens**: Stateful widgets with local state management
- **Widgets**: Reusable `BikeCard` and shared UI components

> In production, replace `ApiService` and `AuthService` mock methods with real HTTP calls using `http` or `dio`.

---

## 🗺️ Navigation Flow

```
Login → OTP → Home
                ├── Home Tab → Bike Details → Unlock PIN → Active Ride → Payment
                ├── Map Tab
                ├── History Tab
                └── Profile Tab → List Bike / Settings / Logout
```

---

*Built with 💚 for sustainable campus mobility at IITGN*
