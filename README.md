# 👻 Phantom
> **Phantom** is a premium, developer-centric accountability and consistency tracker. Instead of using basic checklist tallies, it models habit strength as a physical system of **coupled ordinary differential equations (ODEs)** to project exact goal completion dates based on historical effort, streak momentum, and habit resilience.

Designed with a sleek, minimal, dark **Notion/Linear aesthetic**, Phantom demonstrates how advanced mathematical modeling, clean architecture, and rigorous software engineering can elevate a simple utility into a high-performance productivity tool.

---

## 🚀 Key Features

* **Non-Linear Habit Forecasting**: Phantom uses check-in history to project the exact calendar date you will complete your goal, rating the prediction with a **Confidence Level** (Low, Medium, High).
* **Diminishing-Returns Consistency**: Logging 10 sessions in a day shouldn't let you cheat the system. Consistency scales logarithmically with session effort, meaning a single high-effort session is highly rewarded, but spamming logs saturates progress.
* **Streak Momentum Multiplier**: Consecutive check-in days build momentum, increasing the growth rate of your habit strength.
* **Missed-Day Resilience (Inertia)**: Early on, missing a day causes a sharp drop in habit focus. Once a habit is well-established, accumulated momentum acts as a buffer, making your focus decay slower.
* **Mastery Curve Display Transform**: The progress bar doesn't move linearly. It uses a **logistic S-curve** (slow start, rapid middle, slow finish) to mirror how acquiring a new skill actually feels.
* **Dynamic Habit Profiles**:
  - 🧘 **Single Session**: One check-in gives full credit; extra logs add nothing.
  - 📖 **Duration**: Progress scales steadily with the time you invest.
  - 🏋️ **Intensity**: Higher ceiling for workouts where extra effort pays off.
  - 🔁 **Frequency**: For drinking water or taking breaks where small tasks add up fast.

---

## 🛠️ Tech Stack & Architecture

Phantom is built with a focus on **testability**, **maintainability**, and **performance**:

* **Core**: Flutter / Dart
* **State Management**: Reactive State using the `provider` package (Model-View-ViewModel pattern)
* **Local Persistence**: High-performance NoSQL database (Hive)
* **Testing**: 65+ Unit and Integration tests verifying ODE boundary conditions, cache watermarks, and UI contracts.

### System Architecture
The codebase strictly adheres to **Clean Architecture** boundaries:

$$\text{UI Layer (Provider VM)} \longleftrightarrow \text{Computational Repositories (Pure Dart)} \longleftrightarrow \text{Mathematical Models (ODE Solver)}$$

* **Decoupled Business Logic**: The repository layer does not directly interact with state storage. It replays check-ins computational-style, making it completely decoupled and mock-free during testing.
* **Memoised History Replays**: To avoid replaying check-ins from Day 0 on every request, the `HabitRepository` maintains an in-memory watermark cache. It checks the latest check-in timestamp and returns cached `HabitState` identity objects instantly if no new logs are present.

---

## 🧮 The Mathematics: Modeling Habit Strength with ODEs

Instead of recording simple tallies, Phantom simulates habit strength as a continuous dynamic system stepped daily.

```
       +------------------+
       |   Check-In Note  |
       +------------------+
                |
                v  (Weight E)
       +------------------+
       | Diminishing-     |  C = maxDailyConsistency * (1 - e^(-E/scale))
       | Returns Saturation|
       +------------------+
                |
                v  (Consistency C)
       +------------------+
       |  Focus (F) ODE   |  dF/dt = a * C * StreakMultiplier - effectiveB * F
       +------------------+
                |
                v  (Focus F)
       +------------------+
       |  Progress (P)    |  dP/dt = F
       +------------------+
```

### 1. Coupled ODE Equations
We track two main variables over time $t$ (stepped daily, where $dt = 1\text{ day}$):
- **Focus ($F$)**: The momentum or strength of your habit.
- **Progress ($P$)**: Cumulative goal completion.

$$\frac{dF}{dt} = a \cdot \text{consistency}(t) \cdot \text{streakMultiplier}(\text{streakDays}) - b_{\text{effective}}(F) \cdot F$$

$$\frac{dP}{dt} = F$$

### 2. Diminishing-Returns Consistency Formula
Daily consistency ($C$) is derived from the sum of check-in weights ($E$) on that day using an exponential saturation curve:

$$\text{consistency}(E) = \text{maxDailyConsistency} \cdot \left(1 - e^{-E / \text{effortScale}}\right)$$

For the default **Duration** profile, $\text{maxDailyConsistency} = 3.0$ and $\text{effortScale} = 2.47$. This means:
- $E = 1.0$ (standard session) $\rightarrow$ consistency $\approx 1.0$.
- $E = 3.0$ (heavy session) $\rightarrow$ consistency $\approx 2.1$.
- $E \to \infty$ (spam logs) $\rightarrow$ consistency asymptotes safely at $3.0$.

### 3. Missed-Day Resilience (Inertia)
When consistency is zero, Focus decays. To reward long-term habits, the effective decay rate ($b_{\text{effective}}$) shrinks as Focus ($F$) grows, meaning a missed day has a lower penalty on a mature habit:

$$b_{\text{effective}}(F) = \frac{b}{1 + \text{resilienceFactor} \cdot F}$$

*(where $\text{resilienceFactor} = 0.02$, making the system highly stable and resilient to occasional missed days).*

### 4. S-Curve progress display (Mastery Curve)
A cosmetic logistic function shapes raw progress fraction ($x = P / \text{Goal}$) for the visual progress bar:

$$f(x) = \frac{1}{1 + e^{-k(x - 0.5)}}$$

Mapped and scaled between $[0, 1]$ with $k = 8.0$. This ensures the progress bar moves slowly at the start, rises quickly in the middle (representing the learning breakthrough phase), and slows down near completion.

---

## 💼 Why This Project Stands Out (For Hiring Managers)

Phantom isn't just another checklist app; it represents standard **Production-Grade Engineering**:

1. **Complex Problem Solving**: Translates continuous physical systems (differential equations) into discrete, highly stable algorithms inside a mobile application environment.
2. **Extreme Cache Performance**: Solves $O(N)$ historical replay constraints by implementing a watermark-based caching system ($O(1)$ on cache hits) with guaranteed object identity safety.
3. **Rigorous Quality Assurance**: Backed by a full test suite with boundary value verification, monotonicity invariants, standard deviation calculations, and serialization integrity checks.
4. **Exceptional UI/UX Architecture**: Implements non-blocking overlay loops for celebrations, asynchronous synchronization channels, and responsive animated components.

---

## 🚀 Getting Started & Running

### Running the App
Ensure you have a simulator running or a device connected:
```bash
flutter run
```

### Running the Tests
Execute the full unit test suite to verify the mathematical invariants:
```bash
flutter test
```

### CLI Sanity-Check Simulator
Inspect the daily mathematical outputs for any goal directly from the console:
```bash
dart run tool/habit_model_sanity_check.dart <goalId> [goalProgressTarget] [trailingWindowDays]
```
Example:
```bash
dart run tool/habit_model_sanity_check.dart study-goal-123 150.0 30
```
This prints an aligned table detailing: Date | Effort (E) | Consistency (C) | Focus (F) | Progress (P) alongside completion dates and confidence ratings.
