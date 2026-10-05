# 🎓 SkillSwap — Complete Project Guide & Viva Preparation Master Manual

---

## 📌 1. Project Overview & Executive Summary

### 1.1 What is SkillSwap?
**SkillSwap** is a full-featured, cross-platform (Mobile & Web) **Peer-to-Peer (P2P) Skill Exchange Platform** built using **Flutter** and **Firebase**. The platform enables users to share their knowledge, learn from others, schedule 1-on-1 interactive learning sessions, communicate in real-time, and build peer trust through verified ratings and reviews.

### 1.2 Core Problem Solved
Traditional tutoring platforms are often monetarily transactional, expensive, and rigid. SkillSwap introduces a community-driven collaborative learning model where users can both **offer** skills they master (e.g., Flutter, UI Design, Guitar, Spanish, Fitness) and **learn** skills they desire, scheduling flexible sessions and interacting via real-time messaging.

### 1.3 High-Level Feature Highlights
1. **Authentication & Session Management**: Email/Password authentication with persistent session state and automatic router redirects.
2. **Dynamic Dashboard**: Hero highlights, interactive category filters, trending skills, and top-rated mentor spotlights.
3. **Skill Discovery & Exploration**: Instant search with debounce, multi-criteria filtering (category, tags, level), and detailed mentor profile pages.
4. **Booking & Calendar Scheduler**: Interactive calendar scheduling (using `table_calendar`), multi-slot time picker, confirmation flow, and session status lifecycle (Pending ➔ Confirmed ➔ Completed ➔ Cancelled).
5. **Real-time 1-on-1 Chat**: Low-latency direct messaging powered by Cloud Firestore reactive streams and real-time conversation threading.
6. **Peer Review & Rating Engine**: Multi-criteria star rating, detailed written review feedback, and automatic tutor rating aggregation.
7. **User Profile & Media Upload**: Customizable user bios, learning goals, skills offered, and profile image uploading to Firebase Storage with web/mobile cross-platform support.
8. **Dual Backend Mode (Resilient Architecture)**: Seamless automatic switching between **Cloud Firestore** and **Mock In-Memory Repositories** for offline testing and grading demonstrations.

---

## 🏗️ 2. System Architecture & Engineering Principles

### 2.1 Feature-First + Clean Architecture Structure
The application follows an enterprise-grade **Feature-First Layered Architecture**:

```
lib/
├── core/                  # Shared foundations, router, theme, global widgets
│   ├── constants/         # App constants, layout spacing, dimensions
│   ├── providers/         # Global dependency injection & auth providers
│   ├── router/            # Declarative GoRouter routing & navigation guards
│   ├── theme/             # Material 3 design system, colors, theme extensions
│   ├── utils/             # Cross-platform helpers (e.g. image picker/decoders)
│   └── widgets/           # Global reusable UI widgets (AppShell, Cards, Stars)
├── data/                  # Data access layer (Models, Repositories, Firebase)
│   ├── firebase/          # Cloud Firestore & Firebase Storage implementations
│   ├── mock_data/         # In-memory mock repositories & initial seed data
│   ├── models/            # Immutable domain entities with serialization
│   └── repositories/      # Abstract repository interfaces (Contracts)
└── features/              # Modular feature domains
    ├── auth/              # Login, Signup, Splash screens
    ├── booking/           # Calendar booking, session confirmation, booking history
    ├── chat/              # Chat conversations & message stream screens
    ├── dashboard/         # Home screen, categories, featured skills
    ├── profile/           # User profile viewing and profile editing
    ├── rating/            # Post-session review & star rating submission
    └── skills/            # Skill listings, search, and detailed skill pages
```

### 2.2 Core Design Patterns
* **Repository Pattern**: Abstract interfaces in `lib/data/repositories/` decouple business logic from data sources. Providers inject either `Firebase*Repository` or `Mock*Repository`.
* **Dependency Injection & Inversion of Control (IoC)**: Managed cleanly via **Riverpod** providers (`Provider`, `StateNotifierProvider`, `StreamProvider`).
* **Immutable State Management**: State classes and models use `Equatable` and the `copyWith()` pattern to ensure predictable state transitions.
* **Declarative Navigation**: Managed via `go_router` supporting nested sub-routes, route guards, and bottom navigation preservation via `ShellRoute`.

---

## 📁 3. Detailed File-by-File Breakdown

### 🔵 Root & Configuration Files
* **`pubspec.yaml`**: The project manifest specifying dependencies:
  * `flutter_riverpod` & `riverpod_annotation`: State management.
  * `go_router`: URL-based declarative navigation and deep linking.
  * `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`: Backend services.
  * `table_calendar`: Interactive calendar UI.
  * `google_fonts`, `cached_network_image`, `shimmer`: Polish and visual styling.
  * `intl`, `uuid`, `equatable`: Utilities and immutable model comparisons.
* **`firebase.json` & `firestore.indexes.json`**: Firebase CLI configurations and indexing definitions for complex Firestore queries.
* **`firestore.rules`**: Granular security rules enforcing read/write permissions per collection and subcollection.
* **`storage.rules`**: Storage security rules restricting file size (≤ 5MB) and mime types (images only).
* **`firebase_options.dart`**: Auto-generated Firebase configuration containing API keys and project IDs for Web, Android, iOS, and macOS.
* **`lib/main.dart`**:
  * Initializes Flutter bindings (`WidgetsFlutterBinding.ensureInitialized()`).
  * Initializes Firebase asynchronously with error fallback.
  * Triggers database seeding via `FirestoreSeedService().seedIfEmpty()` if Firestore is empty.
  * Wraps the application in `ProviderScope` and runs `SkillSwapApp`.

---

### 🟢 `lib/core/` (Core Layer)

#### 1. `lib/core/constants/app_constants.dart`
* Defines static app parameters: `appName`, `appVersion`.
* Runtime flags: `useMockRepo` and `isFirebaseAvailable`.
* Design system tokens: Spacings (`spaceXS` to `spaceXXL`), Radii (`radiusSM` to `radiusCircle`), Breakpoints (`tabletBreakpoint = 720.0`, `desktopBreakpoint = 1200.0`).
* Search debounce duration (`400ms`) and predefined categories list.

#### 2. `lib/core/providers/repository_providers.dart`
* **Dependency Injection Root**: Injects concrete repositories based on runtime flags:
  * `userRepositoryProvider`: Provides `FirebaseUserRepository` or `MockUserRepository`.
  * `skillRepositoryProvider`: Provides `FirebaseSkillRepository` or `MockSkillRepository`.
  * `chatRepositoryProvider`: Provides `FirebaseChatRepository` or `MockChatRepository`.
  * `bookingRepositoryProvider`: Provides `FirebaseBookingRepository` or `MockBookingRepository`.
  * `ratingRepositoryProvider`: Provides `FirebaseRatingRepository` or `MockRatingRepository`.
  * `firebaseStorageServiceProvider`: Provides `FirebaseStorageService`.
  * `currentUserProvider`: `StreamProvider` exposing the active authenticated `AppUser`.

#### 3. `lib/core/router/app_router.dart`
* Configures `GoRouter` with `AppRoutes` constants.
* **Navigation Guard / Redirect**: Checks authentication status from `currentUserProvider`. Unauthenticated users attempting to access protected routes are redirected to `/login`; authenticated users on `/login` or `/signup` are redirected to `/dashboard`.
* **`ShellRoute`**: Keeps the persistent `AppShell` (Bottom Navigation Bar) alive across `/dashboard`, `/skills`, `/bookings`, `/chats`, and `/profile`.

#### 4. `lib/core/theme/app_theme.dart` & `app_colors.dart`
* Implements cohesive Light and Dark themes conforming to Material 3.
* Primary palette: Deep Violet/Indigo (`#6366F1`), Emerald accents (`#10B981`), Amber (`#F59E0B`), Slate neutrals.
* Configures custom `CardTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, and typography using Google Fonts (Inter / Plus Jakarta Sans).

#### 5. `lib/core/theme/category_theme_extension.dart`
* Custom `ThemeExtension` mapping each `SkillCategory` to distinctive category colors, light background tints, and specific icons for UI badge rendering.

#### 6. `lib/core/utils/image_utils.dart`
* Cross-platform image picker and binary decoder for web and mobile platforms. Handles base64 conversion and MIME-type deduction for profile picture uploads.

#### 7. `lib/core/widgets/`
* **`app_shell.dart`**: Scaffold wrapper containing the persistent `NavigationBar` (Dashboard, Explore, Bookings, Messages, Profile) with badge counters for unread messages and pending bookings.
* **`skill_card.dart`**: Modular card widget rendering skill thumbnail, category badge, tutor avatar, title, rating stars, and session duration.
* **`skill_card_skeleton.dart`**: Shimmer placeholder skeleton displayed while data is loading.
* **`rating_stars.dart`**: Custom star rating indicator supporting interactive touch inputs or read-only fractional display.
* **`empty_error_states.dart`**: Standardized widgets for Empty States (e.g., "No Bookings Found") and Error States with a Retry button.

---

### 🟡 `lib/data/` (Data Layer)

#### 1. Models (`lib/data/models/`)
* **`app_user.dart` (`AppUser`)**:
  * Fields: `id`, `name`, `email`, `avatarUrl`, `bio`, `location`, `offeredSkillIds`, `wantedSkills`, `avgRating`, `ratingCount`.
  * Methods: `fromMap`, `toMap`, `fromFirestore`, `toFirestore`, `copyWith`, `initials`.
* **`skill.dart` (`Skill`, `SkillCategory`, `SkillLevel`)**:
  * Fields: `id`, `providerId`, `providerName`, `providerAvatar`, `title`, `description`, `category`, `level`, `tags`, `rating`, `ratingCount`, `sessionDurationMinutes`, `imageUrl`.
  * Enums: `SkillCategory` (technology, music, language, art, fitness, cooking, business), `SkillLevel` (beginner, intermediate, advanced, allLevels).
* **`booking.dart` (`Booking`, `BookingStatus`)**:
  * Fields: `id`, `skillId`, `skillTitle`, `learnerId`, `learnerName`, `providerId`, `providerName`, `scheduledAt`, `durationMinutes`, `status`, `notes`.
  * Enum `BookingStatus`: `pending`, `confirmed`, `completed`, `cancelled`.
* **`chat.dart` (`ChatThread`, `ChatMessage`, `MessageType`)**:
  * `ChatThread`: Conversation summary with `id`, `participants`, `lastMessage`, `lastMessageTime`, `unreadCount`.
  * `ChatMessage`: Individual message with `id`, `senderId`, `senderName`, `text`, `timestamp`, `isRead`.
* **`rating.dart` (`Rating`)**:
  * Fields: `id`, `bookingId`, `skillId`, `fromUserId`, `fromUserName`, `toUserId`, `score`, `review`, `createdAt`.

#### 2. Abstract Repository Interfaces (`lib/data/repositories/`)
* Defines pure Dart contracts ensuring loose coupling:
  * `UserRepository`: Auth state, user profile CRUD, session streams.
  * `SkillRepository`: Fetching, searching, filtering, adding, updating, and deleting skills.
  * `BookingRepository`: Booking creation, status updates, user booking streams.
  * `ChatRepository`: Conversation threads, real-time message streaming, sending messages.
  * `RatingRepository`: Rating submission, tutor reviews fetch, average calculation.

#### 3. Firebase Implementation (`lib/data/firebase/`)
* **`firebase_user_repository.dart`**: Interacts with `FirebaseAuth` and Firestore `/users` collection. Supports email/password sign-in, registration, profile updating, and real-time auth stream listening.
* **`firebase_skill_repository.dart`**: Queries the `/skills` Firestore collection. Supports Firestore queries filtered by category, search keywords, and provider IDs.
* **`firebase_booking_repository.dart`**: Manages `/bookings` collection with real-time stream subscriptions filtered by `learnerId` or `providerId`.
* **`firebase_chat_repository.dart`**: Implements real-time messaging using `/chats` parent documents and `/chats/{chatId}/messages` subcollections ordered by `timestamp ascending`.
* **`firebase_rating_repository.dart`**: Writes reviews to `/ratings` and recalculates the tutor's `avgRating` and `ratingCount` in their `/users` document.
* **`firebase_storage_service.dart`**: Uploads user avatars and skill images to Firebase Storage buckets under `avatars/{userId}` and `skills/{skillId}`.
* **`firestore_seed_service.dart`**: Automatically populates Firestore with realistic demo users, skills, bookings, reviews, and chats on first launch.

#### 4. Mock Data Layer (`lib/data/mock_data/`)
* Contains `MockUserRepository`, `MockSkillRepository`, `MockBookingRepository`, `MockChatRepository`, `MockRatingRepository`, and `mock_data.dart` with rich pre-configured dummy datasets for automated testing, offline demos, and grading.

---

### 🟣 `lib/features/` (Presentation & Feature Layer)

#### 1. Authentication (`lib/features/auth/`)
* **`splash_screen.dart`**: Displays animated branding while verifying auth token and Firebase connection.
* **`login_screen.dart`**: Form with email/password validation, demo account autofill buttons, and integration with `authControllerProvider`.
* **`signup_screen.dart`**: New user registration capturing Full Name, Email, Password, and initial learning interests.

#### 2. Dashboard (`lib/features/dashboard/`)
* **`dashboard_screen.dart`**: Home hub displaying:
  * Personalized greeting header with user avatar.
  * Quick Stats counter (Completed sessions, Active skills, Star rating).
  * Category Pills selector with instant filter navigation.
  * Horizontal carousel of "Featured & Trending Skills".
  * "Top Rated Mentors" showcase cards.
* **`dashboard_providers.dart`**: Computes dashboard metrics and exposes featured skills and trending mentors.

#### 3. Skills Discovery (`lib/features/skills/`)
* **`skill_listing_screen.dart`**: Complete search & filter screen:
  * Search bar with debounced input.
  * Category filter chips (All, Technology, Music, Language, Art, etc.).
  * Difficulty level dropdown (Beginner, Intermediate, Advanced).
  * Responsive Grid/List view with pull-to-refresh and Shimmer loading states.
* **`skill_detail_screen.dart`**:
  * Skill banner image, category tag, and difficulty indicator.
  * Tutor biography, credentials, and direct "Chat with Tutor" action.
  * Detailed "What you'll learn" bullet points.
  * Real-time list of student reviews with star breakdown.
  * Sticky bottom action bar with "Book a Session" button.
* **`skill_providers.dart`**: Manages search queries, category filters, skill detail caching, and provider skill management.

#### 4. Booking & Scheduling (`lib/features/booking/`)
* **`booking_calendar_screen.dart`**:
  * Interactive month/week calendar view (`table_calendar`).
  * Available time-slot chips (e.g. 10:00 AM, 02:00 PM, 04:30 PM).
  * Duration selector (30 min, 45 min, 60 min).
* **`confirm_session_screen.dart`**: Summary view displaying selected date, time, mentor details, and an optional notes input field before final confirmation.
* **`my_bookings_screen.dart`**:
  * Tabbed interface: **Upcoming**, **Completed**, and **Cancelled** sessions.
  * Status-based action buttons: "Join / Chat", "Cancel Session", and "Leave a Review" (when completed).
* **`booking_providers.dart`**: `StateNotifier` managing booking state mutations, date/slot selections, and cancellation handlers.

#### 5. Real-Time Chat (`lib/features/chat/`)
* **`chat_list_screen.dart`**: Displays all active conversation threads with last message snippet, timestamp, unread badge, and mentor avatar.
* **`chat_screen.dart`**:
  * Real-time conversation view powered by Firestore stream listeners.
  * Message bubbles distinguishing sent vs. received messages with timestamps.
  * Quick contextual header displaying the skill being discussed.
  * Message input bar with auto-scroll to bottom on new messages.
* **`chat_providers.dart`**: Stream providers listening to thread lists and individual conversation message streams.

#### 6. Profile & Settings (`lib/features/profile/`)
* **`profile_screen.dart`**:
  * Displays user profile header, avatar, average rating, location, and bio.
  * "Skills I Offer" section with quick add/edit triggers.
  * "Skills I Want to Learn" interest tags.
  * Session history counter and Logout action.
* **`edit_profile_screen.dart`**:
  * Edit Name, Bio, Location, and Learning Goals.
  * Profile picture upload with preview using `image_picker` and `FirebaseStorageService`.

#### 7. Rating & Reviews (`lib/features/rating/`)
* **`rating_screen.dart`**:
  * Interactive 5-star rating selector (`RatingBar`).
  * Multi-line review text input with minimum character validation.
  * Submits review to Firestore and updates the mentor's aggregated rating score.

---

## 🗄️ 4. Database Architecture & Firestore Schema

SkillSwap utilizes a NoSQL document model in Cloud Firestore designed for high read performance, real-time sync, and security.

```
                    ┌─────────────────────────┐
                    │      /users/{uid}       │
                    │  name, email, rating... │
                    └───────────┬─────────────┘
                                │
               ┌────────────────┼────────────────┐
               │ 1:N            │ 1:N            │ 1:N
               ▼                ▼                ▼
     ┌──────────────────┐ ┌───────────────┐ ┌──────────────────┐
     │  /skills/{id}    │ │/bookings/{id} │ │  /ratings/{id}   │
     │ title, category, │ │ learnerId,    │ │ bookingId, score,│
     │ providerId...    │ │ providerId... │ │ review...        │
     └──────────────────┘ └───────────────┘ └──────────────────┘
                                │
                                │ 1:N
                                ▼
                      ┌──────────────────┐
                      │   /chats/{id}    │
                      │ participants...  │
                      └────────┬─────────┘
                               │
                               │ 1:N (Subcollection)
                               ▼
                      ┌──────────────────┐
                      │ /messages/{msgId}│
                      │ senderId, text...│
                      └──────────────────┘
```

### Collection Details

| Collection | Path | Key Fields | Purpose |
|---|---|---|---|
| **Users** | `/users/{userId}` | `uid`, `name`, `email`, `profileImage`, `bio`, `location`, `skillsOffered`, `skillsLearning`, `rating`, `totalRatings` | Stores user profiles and aggregated mentor ratings. |
| **Skills** | `/skills/{skillId}` | `id`, `providerId`, `title`, `description`, `category`, `level`, `tags`, `rating`, `sessionDurationMinutes`, `imageUrl` | Published skills catalog. |
| **Bookings** | `/bookings/{bookingId}` | `id`, `skillId`, `learnerId`, `providerId`, `scheduledAt`, `durationMinutes`, `status`, `notes` | Scheduled learning sessions. |
| **Chats** | `/chats/{chatId}` | `id`, `participants`, `lastMessage`, `lastMessageTime`, `skillId` | 1-on-1 conversation thread metadata. |
| **Messages** | `/chats/{chatId}/messages/{messageId}` | `id`, `senderId`, `senderName`, `text`, `timestamp`, `isRead` | Individual messages within a chat. |
| **Ratings** | `/ratings/{ratingId}` | `id`, `bookingId`, `skillId`, `fromUserId`, `toUserId`, `score`, `review`, `createdAt` | Verified post-session reviews. |

---

## 🔒 5. Security Rules (Firestore & Storage)

### 5.1 Firestore Security Rules Logic (`firestore.rules`)
* **Authentication Check**: Any read/write operation requires `request.auth != null`.
* **Users Collection**: Any authenticated user can read public profiles; only the profile owner (`request.auth.uid == userId`) can modify their own record.
* **Skills Collection**: Authenticated users can browse skills; only the author (`providerId == auth.uid`) can update or delete their skill listing.
* **Chats & Messages**:
  * Chat documents are only accessible if `auth.uid in resource.data.participants`.
  * Message subcollections can only be read/written by verified chat participants. Messages are immutable (no edits/deletions allowed).
* **Bookings**: Accessible only by the student (`learnerId == auth.uid`) or the tutor (`providerId == auth.uid`).
* **Ratings**: Any authenticated user can read reviews; users can only submit reviews authored by themselves (`fromUserId == auth.uid`).

### 5.2 Storage Security Rules Logic (`storage.rules`)
* Uploads must be authenticated (`request.auth != null`).
* Avatars path: `/avatars/{userId}/{fileName}` allows write only if `request.auth.uid == userId`.
* File validation: Maximum file size is capped at 5MB (`request.resource.size < 5 * 1024 * 1024`) and content type must be an image (`request.resource.contentType.matches('image/.*')`).

---

## ⚡ 6. State Management Architecture (Riverpod)

### Why Riverpod over other State Management solutions?
1. **Compile-time Safety**: No `ProviderNotFoundException` runtime crashes.
2. **No BuildContext Dependency**: State can be read and listened to in controllers, repositories, and logic classes without requiring a `BuildContext`.
3. **Automatic Lifecycle & Cleanup**: `.autoDispose` releases memory when a screen or widget is no longer in the widget tree.
4. **First-class Asynchronous Handling**: `AsyncValue` (`AsyncData`, `AsyncLoading`, `AsyncError`) gracefully models async operations with built-in pattern matching (`when()`).
5. **Stream Support**: `StreamProvider` enables direct bindings to Firestore real-time snapshots.

### Summary of Riverpod Providers in SkillSwap:

```dart
// 1. Dependency Injection Provider (Repository)
final userRepositoryProvider = Provider<UserRepository>((ref) => FirebaseUserRepository());

// 2. Real-time Stream Provider (Auth State)
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(userRepositoryProvider).currentUserStream;
});

// 3. Computed / Filtered Future Provider (Skills Catalog)
final filteredSkillsProvider = FutureProvider<List<Skill>>((ref) async {
  final repo = ref.watch(skillRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.getSkills(category: category, searchQuery: query);
});

// 4. StateNotifier Provider (Booking Flow State Management)
final bookingControllerProvider = StateNotifierProvider<BookingController, BookingState>((ref) {
  return BookingController(ref.watch(bookingRepositoryProvider));
});
```

---

## 🎯 7. Comprehensive Viva Questions & Expert Answers

### Section A: Flutter & Dart Fundamentals

#### Q1: What is the difference between `StatelessWidget`, `StatefulWidget`, `ConsumerWidget`, and `ConsumerStatefulWidget`?
* **Answer**:
  * `StatelessWidget`: Immutable UI widget whose appearance depends entirely on configuration info passed at instantiation. Does not maintain mutable state across rebuilds.
  * `StatefulWidget`: Maintains a separate `State` object that persists across widget rebuilds and triggers re-rendering via `setState()`.
  * `ConsumerWidget` (Riverpod): Replaces `StatelessWidget` when using Riverpod. Provides a `WidgetRef` in its `build(BuildContext context, WidgetRef ref)` method, enabling reactive provider watching (`ref.watch`) and one-time reading (`ref.read`).
  * `ConsumerStatefulWidget` (Riverpod): Replaces `StatefulWidget` when local widget state (like `AnimationController`, `TextEditingController`, or `TabController`) is needed alongside global Riverpod providers. Provides access to `ref` globally inside the `ConsumerState` lifecycle.

#### Q2: What is `BuildContext` in Flutter and why is it important?
* **Answer**:
  * `BuildContext` is a handle to the location of a widget within the **Element Tree**.
  * It allows widgets to look up inherited widgets higher in the tree (such as `Theme.of(context)`, `MediaQuery.of(context)`, or `Navigator.of(context)`).

#### Q3: Explain the Flutter Widget, Element, and RenderObject Trees.
* **Answer**:
  * **Widget Tree**: Lightweight, immutable blueprints of the UI that are created and destroyed rapidly.
  * **Element Tree**: Manages the lifecycle, holding references to both the Widget and RenderObject. It determines whether a RenderObject needs updating or recreating when widgets rebuild.
  * **RenderObject Tree**: The heavy, mutable tree that handles layout constraints, sizing, painting, and hit-testing on the physical screen.

---

### Section B: Architecture & Design Patterns

#### Q4: Why did you choose Feature-First architecture over Layer-First architecture?
* **Answer**:
  * In **Layer-First** architecture (`controllers/`, `views/`, `models/`), related files for a single feature are scattered across different folders, making navigation and scaling cumbersome.
  * In **Feature-First** architecture (`features/booking/`, `features/chat/`), all domain models, UI screens, and providers for a specific feature live together. This improves code cohesion, makes the codebase modular, simplifies feature isolation, and facilitates teamwork.

#### Q5: What is the Repository Pattern and what benefit did it bring to this project?
* **Answer**:
  * The **Repository Pattern** creates an abstraction layer between domain business logic and data access sources (Firestore, REST API, SQLite, or in-memory mock data).
  * In SkillSwap, defining abstract repository contracts (`UserRepository`, `SkillRepository`, etc.) allowed us to implement both `FirebaseSkillRepository` and `MockSkillRepository`. The app can switch between real Firebase and mock datasets seamlessly without changing a single line of UI code.

---

### Section C: Navigation & GoRouter

#### Q6: How does declarative routing in `go_router` work and how are protected routes guarded?
* **Answer**:
  * `go_router` uses a declarative configuration where URLs map directly to widget trees.
  * Route protection is handled through the top-level `redirect` callback in `GoRouter`. The router observes `currentUserProvider`. If the user is unauthenticated and tries to open a protected route like `/dashboard` or `/bookings`, the router automatically redirects them to `/login`. If an authenticated user lands on `/login`, it automatically routes them to `/dashboard`.
  * We use `ShellRoute` to maintain the bottom navigation bar (`AppShell`) across primary tabs without re-instantiating the navigation bar on tab changes.

---

### Section D: Backend & Cloud Firestore

#### Q7: Why Cloud Firestore instead of a traditional SQL database?
* **Answer**:
  * **Real-time Synchronization**: Firestore provides native snapshot streams (`snapshots()`), enabling real-time chat and instantaneous booking status updates.
  * **Offline Support & Latency Compensation**: Built-in client-side caching ensures the app remains interactive even with intermittent connectivity.
  * **Flexible Document Model**: Complex nested data like user learning goals and skill tags can be stored naturally without complex join tables.

#### Q8: How do Firestore Security Rules protect the Chat feature?
* **Answer**:
  * Security rules enforce that a user can only read or write to a `/chats/{chatId}` document if their authenticated UID exists within the document's `participants` array (`request.auth.uid in resource.data.participants`).
  * For message creation under `/chats/{chatId}/messages/{messageId}`, the rule verifies that `request.resource.data.senderId == request.auth.uid` and that message records are immutable (preventing unauthorized edits or deletions).

#### Q9: How is the mentor's average rating calculated and updated?
* **Answer**:
  * When a student submits a review via `RatingScreen`, `FirebaseRatingRepository` performs a two-step operation:
    1. Writes the new review document into the `/ratings` collection.
    2. Queries all existing ratings for the target tutor (`toUserId`), computes the new arithmetic mean (`avgRating = totalScore / ratingCount`), and updates the tutor's record in the `/users` collection atomically.

---

### Section E: Edge Cases, Optimization & Testing

#### Q10: How does the application prevent unnecessary Firestore queries during search?
* **Answer**:
  * We implemented **Search Debouncing** with a `400ms` delay using a timer in `searchQueryProvider`.
  * As the user types in the search field, queries are not dispatched on every keystroke. The app waits until the user pauses typing for 400ms before triggering the database filter, saving database read quotas and reducing network overhead.

#### Q11: How are image uploads handled across both Mobile and Web platforms?
* **Answer**:
  * Mobile and Web have different file abstractions (Web cannot access direct POSIX file paths like `/data/user/0/...`).
  * In `image_utils.dart`, we read picked images as raw byte arrays (`Uint8List`) or base64 streams, passing them directly to `FirebaseStorageService.uploadData()`. This ensures consistent image uploading across Chrome, Android, and iOS.

#### Q12: How are loading and error states handled in the UI?
* **Answer**:
  * Riverpod's `AsyncValue` provides a `.when()` pattern:
    * `data: (items) => ...` (Renders content).
    * `loading: () => const SkillCardSkeletonList()` (Renders animated Shimmer placeholders).
    * `error: (err, stack) => ErrorStateWidget(onRetry: () => ...)` (Renders user-friendly error with retry).

---

## 📋 8. Quick Viva Checklist & Summary Cheat Sheet

| Topic | Key Terminology / Buzzwords to Use in Viva |
|---|---|
| **Language & Framework** | Dart 3.5+, Flutter Material 3, Cross-platform (iOS, Android, Web) |
| **Architecture** | Feature-First Architecture, Clean Architecture, Repository Pattern, Dependency Injection |
| **State Management** | Flutter Riverpod 2.5+, `ConsumerWidget`, `StreamProvider`, `StateNotifierProvider`, `AsyncValue` |
| **Navigation** | `go_router` 14+, Declarative routing, `ShellRoute`, Route Guards & Redirects |
| **Backend & Cloud** | Firebase Auth, Cloud Firestore (NoSQL, Streams), Firebase Storage, Security Rules |
| **UI / UX** | Responsive Design, Shimmer Loading Skeletons, Google Fonts, Theme Extensions, `table_calendar` |
| **Data Flow** | Reactive unidirectional data flow (Database ➔ Stream ➔ Provider ➔ Consumer UI ➔ Controller Action) |

---
*Created for SkillSwap Project Viva & Technical Defense.*
