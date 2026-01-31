# 🧠 GymBrain - Your AI Training Partner

**GymBrain** is a smart, offline-first workout tracking application designed to help lifters progress faster using data-driven insights. Unlike simple loggers, GymBrain uses a Rule-Based AI engine to suggest weight adjustments based on RPE (Rate of Perceived Exertion) and performance.

---

## ✨ Key Features

* **🤖 Smart AI Recommendations:** Analyzes your sets (RPE, Reps) and suggests whether to increase weight, hold, or deload.
* **📊 Interactive Progress Charts:** Visualize your strength gains over 1M, 3M, and 1Y periods. Supports dynamic KG/LB switching.
* **💾 Offline-First Architecture:** Built with **Hive** (NoSQL Database) for lightning-fast performance without internet.
* **🧮 Power Tools:**
    * **1RM Calculator:** Estimate your One-Rep Max using the Epley formula.
    * **Plate Calculator:** Visual guide for loading the bar (supports custom inventory).
* **🎨 Cyberpunk UI:** A sleek, Dark Mode design with Neon Green accents for high focus.
* **🔒 Secure Backup:** JSON-based Backup & Restore system to keep your data safe.

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter (Dart) |
| **State Management** | Provider / ValueNotifier |
| **Local Database** | Hive (NoSQL) |
| **Charting** | fl_chart |
| **Typography** | Google Fonts (Cairo) |
| **Notifications** | flutter_local_notifications |
| **Logic** | Rule-Based Expert System (Algorithmic AI) |

---

## 📸 Screenshots

*(Add your screenshots here)*

| Home Screen | Active Workout | Progress Charts |
|-------------|----------------|-----------------|
| ![Home](screenshots/home.png) | ![Workout](screenshots/workout.png) | ![Progress](screenshots/progress.png) |

---

## 🚀 How to Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/gymbrain.git
   cd gymbrain
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models (Exercise, Routine, Session, etc.)
├── screens/               # UI screens (Home, Workout, Progress, Tools)
├── services/              # Database & Notification services
└── utils/                 # Utility functions & helpers
```

---

## 🎯 Roadmap

- [x] Core workout tracking
- [x] AI-powered recommendations
- [x] Progress visualization
- [x] 1RM & Plate calculators
- [x] Backup & Restore
- [ ] Rest timer notifications
- [ ] Workout streaks
- [ ] Cloud sync (optional)

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Built with ❤️ by Mohamed Naser*
