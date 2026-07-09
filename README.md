# Phantom — Accountability & Skill-Development Tracker

Phantom is a serious, data-forward personal accountability tracker designed for developers, students, and professionals working on skill acquisition (e.g., studying for certifications, mastering data structures, or practicing lab environments). 

It intentionally avoids gamified habits (no streaks, fire emojis, badges, or confetti). Instead, it mirrors a fitness or financial dashboard, tracking practices against **weekly targets** and computing pacing metrics.

---

## 🎨 Visual Design Philosophy

Phantom uses a precise, minimal, and opinionated visual language inspired by **Linear**, **Arc**, and **Things 3**:
- **Palette**: A rich graphite-charcoal base (`#0B0C0E`), slate-dark surfaces (`#121316`), and thin geometric borders (`#202226`).
- **Accent**: A single ice-blue accent (`#38BDF8`) used sparingly for focused interaction points.
- **Typography**: Uses the Inter font with clean weighting. Numerical indicators (like percentages and counts) render with **tabular figures** to align digits properly.
- **Status Indicators**: Tracks standing using distinct shapes and colors, rather than just red/green traffic lights:
  - **On Track**: Green upward pointers `▲`
  - **Behind**: Orange rightward steady pointer `▶`
  - **Falling Off**: Coral red downward alert pointer `▼`

---

## 🧩 Core Concepts

### 1. Goals
Goals are overall targets with a specific completion date (e.g., *"Finish HTB CWES path by Sept 30"*, *"Solve 150 DSA questions"*).
- **Why Statement**: A required statement explaining the serious reasoning behind the goal.
- **Milestones**: Optional checkpoints that act as the primary progress indicators.
- **Target Count**: An optional numeric count (e.g., `150`) to track cumulative logs.
- **Time Elapsed**: Used as a fallback indicator labeled as "time elapsed" if no milestones or counts are set.

### 2. Practices
Recurring actions linked to a goal (e.g., *"DSA Tree Problem"*, *"VAPT Lab Practice"*).
- Target is defined **weekly** (e.g., `4x / week`) rather than daily.

### 3. Check-Ins
Logs entered against practices.
- **Note**: A mandatory explanation of what was completed (no empty checkboxes).
- **Effort Level**: Shaded into **Light** (reading/review), **Moderate** (active work), and **Deep Focus** (challenging work).
- **Duration**: Optional log duration in minutes.

### 4. Weekly Review
A Sunday reflection flow:
- Prompts you to log what worked, what friction points you faced, and adjust next week's practice targets.

---

## ⚙️ Pacing & Pacing Standing Algorithm

Each goal displays its standing based on a rolling consistency window:
- **Required Pace**: Remaining milestones or counts divided by weeks remaining.
- **Actual Pace**: The rolling average of check-ins per week over the **last 2 weeks** (ensures a strong start doesn't hide recent slacking).
- **Status Thresholds**:
  - `actualPace >= requiredPace` ➔ **On Track** `▲`
  - `actualPace >= 0.7 * requiredPace` ➔ **Behind** `▶`
  - `actualPace < 0.7 * requiredPace` ➔ **Falling Off** `▼`

---

## 🚀 Running the Project

Ensure you have [Flutter](https://flutter.dev/docs/get-started/install) installed.

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
To compile and run the application on your default device/simulator:
```bash
flutter run
```

### 3. Static Analysis
Run the analyzer to ensure the codebase remains clean:
```bash
flutter analyze
```

---

## 📂 Codebase Architecture

The project is structured according to a clean separation of concerns:
```
lib/
├── main.dart                          # App Entry point & Hive Initialization
├── app.dart                           # MaterialApp wrapper config
├── models/                            # Plain Dart classes (toMap / fromMap serialization)
│   ├── goal.dart
│   ├── practice.dart
│   ├── check_in.dart
│   ├── milestone.dart
│   └── weekly_review.dart
├── repositories/                      # The ONLY layer that touches Hive APIs directly
│   ├── goal_repository.dart
│   ├── practice_repository.dart
│   ├── check_in_repository.dart
│   └── weekly_review_repository.dart
├── providers/                         # Reactive state management (Provider)
│   ├── goal_provider.dart
│   ├── practice_provider.dart
│   ├── check_in_provider.dart
│   ├── stats_provider.dart            # Contains pure, testable calculatePace() functions
│   └── weekly_review_provider.dart
├── screens/                           # Thin UI Screens
│   ├── home_screen.dart               # Tab shell with center FAB (Home, Goals, Grid, Logs)
│   ├── dashboard_screen.dart          # Standing Dashboard
│   ├── goal_form_screen.dart          # Goal creation & edit form
│   ├── goal_detail_screen.dart        # Goal detailed view & practice manager
│   ├── check_in_screen.dart           # Logging bottom-sheet
│   ├── heatmap_screen.dart            # Heatmap grid & Analytics
│   ├── history_screen.dart            # Filterable & searchable logs
│   └── weekly_review_screen.dart      # Guided reflection screen
└── widgets/                           # Reusable widgets
    ├── goal_card.dart
    ├── practice_tile.dart
    ├── check_in_tile.dart
    ├── empty_state.dart
    └── heatmap_grid.dart              # GitHub-style grid with details on tap
```
