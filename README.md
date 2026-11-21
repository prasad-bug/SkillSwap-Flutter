<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Cross--Platform-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-005CFF?style=for-the-badge&logo=riverpod&logoColor=white" />
</p>

# 🔄 SkillSwap — Peer-to-Peer Skill Exchange Platform

> **A cross-platform mobile & web app where people trade skills without money.** Users share their expertise (e.g., coding, guitar, languages), earn Swap Credits, and book 1-on-1 learning sessions with peers.

---

## 🏗️ Architecture & Tech Stack

### High-Level Architecture
SkillSwap is built with a **Feature-First Clean Architecture**, ensuring modularity, scalability, and testability:

```
lib/
├── features/       # Independent business modules (Auth, Dashboard, Skills, Bookings, Chat, Profile)
├── core/           # Shared foundations (Theme, Navigation/Routing, Reusable UI Components)
└── data/           # Repositories, Data Models, and Backend Integrations (Firebase + Offline Mock)
```

- **Separation of Concerns:** UI screens are decoupled from business logic and database queries using the **Repository Pattern**.
- **Offline / Demo Resilience:** Dual backend architecture — seamlessly switches between real Firebase services and mock in-memory data with a single setting.

### Tech Stack Overview

| Category | Technology | Why It Was Chosen |
|---|---|---|
| **Frontend Framework** | **Flutter & Dart** | Cross-platform performance (iOS, Android, and Web from one codebase) |
| **State Management** | **Flutter Riverpod** | Reactive, robust, and testable app state management |
| **Backend & Database** | **Cloud Firestore** | Real-time data sync for live bookings, chats, and profiles |
| **Authentication** | **Firebase Auth** | Secure session management and route protection |
| **Navigation** | **GoRouter** | Clean, declarative URL routing with built-in auth redirects |
| **Design System** | **Material 3** | Modern, accessible UI with dark and light mode support |

---

## 📸 App Screens & Walkthrough

### 1. 🏠 Smart Dashboard
<p align="center">
  <img src="public/dashboard.png" width="280" alt="Dashboard Screen" />
</p>

- **Personalized Home:** Displays user greeting, live Swap Credits balance, and quick search.
- **Next Session Alert:** Shows upcoming booked classes with instant **Join Call** and **Reschedule** options.
- **Skill Discovery:** Horizontal category pills (Tech, Music, Fitness, Languages) and trending mentor cards.

---

### 2. 🔍 Skill Marketplace & Smart Filters
<p align="center">
  <img src="public/explore.png" width="280" alt="Explore Screen" />
</p>

- **Instant Search & Filtering:** Filter skills by skill level, rating (4.5+), or availability.
- **Bilateral Matching Matrix:** Clearly shows what each user is **Offering** vs. what they are **Seeking**, making skill exchanges quick and intuitive.
- **Trust Badges:** Verified icons for top-rated community mentors.

---

### 3. 📅 Interactive Session Booking
<p align="center">
  <img src="public/booking.png" width="280" alt="Booking Calendar Screen" />
</p>

- **Calendar View:** Monthly and 2-week calendar views displaying open and booked dates.
- **Frictionless Scheduling:** Select date, session duration (30 to 120 mins), and available time slots.
- **Double-Booking Prevention:** Automatically detects schedule conflicts before booking confirmation.

---

### 4. 👤 User Profile & Reputation Dashboard
<p align="center">
  <img src="public/profile.png" width="280" alt="Profile Screen" />
</p>

- **Reputation Metrics:** Real-time stats showing completed swaps, star ratings, and community reviews.
- **Teaching Portfolio:** Easily add and manage the skills you teach to earn more credits.
- **Learning Wishlist:** Add topics you want to learn so other members can reach out.

---

## 💡 Project Description

### The Problem
Hiring tutors or enrolling in courses is expensive and strictly transactional. Meanwhile, millions of people have skills they can share and skills they want to learn, but lack a trustworthy platform to exchange them.

### The Solution: SkillSwap
SkillSwap turns skill learning into a **collaborative economy**:
1. **Teach What You Know:** List your skill (e.g., Python, Guitar, Spanish) and conduct 1-on-1 sessions.
2. **Earn Credits:** Complete sessions to earn **Swap Credits** and community reputation.
3. **Learn Anything:** Spend your credits to book sessions with other talented creators and professionals.
4. **Build Trust:** Real-time chat, session confirmation, and peer ratings ensure high-quality exchanges.

### 🌟 Key Engineering Highlights
- **56 Dart files** (~15,700 lines of clean, structured code).
- **Responsive & adaptive:** Runs cleanly on Desktop Web and Mobile.
- **Production-ready patterns:** Full error handling, skeleton loading states, and secure Firebase rules.

---

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/prasad-bug/SkillSwap-Flutter.git
cd SkillSwap-Flutter

# 2. Get dependencies
flutter pub get

# 3. Run in Chrome (or on a mobile device)
flutter run -d chrome
```

*Runs out-of-the-box with realistic mock demo data.*

---

<p align="center">
  Built with ❤️ by <strong>Prasad Bhad</strong>
</p>
