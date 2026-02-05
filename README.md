# 🧠 GymBrain - Smart AI Training Partner

**GymBrain** is a next-generation, **offline-first** workout tracker designed for serious lifters. It helps you progress faster by combining **Rule-Based AI** for weight recommendations with deep data analytics.

Unlike simple loggers, GymBrain acts as a "Digital Coach," analyzing your RPE (Rate of Perceived Exertion) and set performance to suggest optimal weight adjustments (Increase, Hold, Deload).

---

## ✨ Key Features

### 🏋️‍♂️ Smart Workout Tracking
* **AI Auto-Regulation:** The system analyzes every set and suggests weight changes based on RPE and Reps.
* **Hybrid Units:** Seamless support for both **KG** and **LB**, with automatic conversion and normalization.
* **Drop Sets:** Native support for tracking high-intensity drop sets.
* **Rest Timer:** Built-in timer with background notifications.

### 📊 Deep Analytics
* **Interactive Charts:** Visualize Volume, 1RM, and Max Weight trends over 1M, 3M, and 1Y.
* **InBody Tracking:** Monitor body composition changes (Muscle Mass, Fat %, Weight) over time.

### 🛠️ Power Tools
* **1RM Calculator:** Estimate your One-Rep Max using the Epley formula.
* **Plate Calculator:** Visual guide for loading the bar (supports 45/35/25/10/5/2.5 logic).

### ⚡ Technical Excellence
* **Offline-First:** Built on **Hive NoSQL**, ensuring zero latency and 100% functionality without internet.
* **Single Active Workout policy:** Prevents data corruption by enforcing a single active session state.
* **Universal Backup:** Secure JSON-based backup system compatible with both Web and Mobile.

---

## 🎨 UI/UX Design

* **Theme:** "Cyberpunk Dark" - Optimized for gym environments (OLED Black + Neon Green accents).
* **Font:** **Cairo** (Google Fonts) for modern, readable typography.
* **Animations:** Smooth transitions and micro-interactions for a premium feel.

---

## 🛠️ Technology Stack

| Component | Tech |
|-----------|------|
| **Framework** | Flutter (Dart) |
| **State Management** | `Provider` + `ValueNotifier` |
| **Database** | `Hive` (NoSQL, fast key-value store) |
| **Charts** | `fl_chart` |
| **Notifications** | `flutter_local_notifications` |
| **Deployment** | Vercel (Web), APK (Android) |

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.9.2+)
* Dart SDK

### Installation

1. **Clone the Repo**
   ```bash
   git clone https://github.com/yourusername/gymbrain.git
   cd gymbrain
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   # For Mobile
   flutter run

   # For Web
   flutter run -d chrome --web-renderer html
   ```

### 🌍 One-Click Web Deployment

We include a specialized batch script for automated Vercel deployment on Windows.

1. **Run `deploy_vercel.bat`**:
   ```cmd
   ./deploy_vercel.bat
   ```
   
   *This script:*
   1. Cleans the project.
   2. Builds the web app (`--web-renderer html`).
   3. Copies files to the distribution folder.
   4. Pushes to GitHub to trigger Vercel CI/CD.

---

## 📂 Project Structure

```
lib/
├── main.dart                 # App Entry & Provider Setup
├── models/                   # Hive Models (WorkoutSession, Exercise, etc.)
├── providers/                # State Management (ActiveWorkoutProvider)
├── screens/                  # UI Layers
│   ├── active_workout_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   └── ...
├── services/                 # Logic Layer (Database, Notifications)
└── utils/                    # Helpers (Calculations, Formatters)
```

---

## 🤝 Contributing

Contributions are welcome! Please follow the **"Offline-First"** architecture rules:
* Always use `GymDatabase` accessors.
* Do not use `dart:io` directly (use `universal_html` or abstraction layers).
* Ensure all database writes are awaited.

---

## 📄 License

This project is licensed under the MIT License.

---

*Built with ❤️ (and lots of caffeine) by Mohamed Naser*
