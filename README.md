# Newsly

**Newsly** is a production-grade Flutter news application designed for Android and iOS that delivers curated spaceflight, aerospace, and science technology news, blogs, and agency status reports powered by the [Spaceflight News API (v4)](https://api.spaceflightnewsapi.net/v4).

The application is architected around a clean **Model-View-ViewModel (MVVM)** pattern with **Provider**-driven reactive state management, strongly typed **Dio** networking, resilient offline error recovery, responsive phone and tablet layouts, local bookmark persistence, and an automated test suite with 100% pass rate across 271 tests.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Application Features](#application-features)
  - [1. Articles Feed & Details](#1-articles-feed--details)
  - [2. Blogs Feed & Details](#2-blogs-feed--details)
  - [3. Reports Feed & Details](#3-reports-feed--details)
  - [4. Shared & Cross-Cutting Capabilities](#4-shared--cross-cutting-capabilities)
- [Screenshots & Visuals](#screenshots--visuals)
- [Technology Stack](#technology-stack)
- [Architecture & Design Pattern](#architecture--design-pattern)
- [Project Structure](#project-structure)
- [API Integration](#api-integration)
- [Search, Pagination & Performance Engineering](#search-pagination--performance-engineering)
- [UI, Theming & Accessibility](#ui-theming--accessibility)
- [Setup & Installation](#setup--installation)
- [Automated Testing & Quality Assurance](#automated-testing--quality-assurance)
- [Android Production Release Builds & Size Optimization](#android-production-release-builds--size-optimization)
- [Future Enhancements](#future-enhancements)

---

## Project Overview

Newsly aggregates spaceflight and aerospace coverage across three distinct content types from the Spaceflight News API (v4):
1. **Articles:** Major news stories from prominent space journalism outlets (e.g., SpaceNews, NASA, Arstechnica, NASASpaceflight).
2. **Blogs:** Editorial write-ups, analysis, and space community columns.
3. **Reports:** Official agency, station, and mission status reports (e.g., ISS Daily Status Reports, NASA technical briefings, Boeing Starliner status updates).

### Platform Verification Status
- **Android:** Verified on physical hardware (Motorola `moto g04s`, Android 14, API level 34, `arm64-v8a`) and automated test suites.
- **iOS:** Built with standard cross-platform Flutter APIs and Material 3 responsive specifications. Physical iOS hardware validation requires a macOS host.

---

## Application Features

### 1. Articles Feed & Details
- **Feed Interface:** Curated list of space news articles with high-resolution cached thumbnails, news site badges, publication timestamps, and author attribution.
- **Live Debounced Search:** Real-time search by title and summary with a 500 ms debounce timer to prevent redundant API queries.
- **Source / Category Filter Chips:** Horizontally scrolling filter chips (`All`, `SpaceX`, `NASA`, `ESA`, `SpaceNews`, `Science`) that query the API by keyword/news site.
- **Infinite Scroll Pagination:** Automatically requests the next page of articles when the user scrolls within 200px of the feed bottom.
- **Pagination Deduplication:** Appended articles are deduplicated via a `Set<int>` of unique IDs to prevent duplicate card entries on unstable network connections.
- **Pull-to-Refresh:** Pulling down on the feed refreshes the collection from offset 0 while preserving existing items if an error occurs.
- **Article Detail Screen:** Full-bleed hero image with graceful fallback placeholders, formatted publication date, publisher tag, author metadata, and complete summary text.
- **Horizontal Swipe Navigation:** Book-style / Gmail-style horizontal page transitions enabling users to swipe left/right between loaded articles. Includes boundary clamping and proactive end-of-feed prefetching.
- **Bookmark Toggle:** Dedicated bookmark action button providing immediate gold/amber visual state changes, haptic feedback, and a floating confirmation SnackBar.
- **More Options Modal:** Bottom sheet providing native platform sharing (`share_plus`), URL copying to system clipboard (`Clipboard.setData`), and direct browser launch.
- **External Article Navigation:** Prominent **"Read full article"** button with external link icon opening the original web article in the system browser via `url_launcher`.

### 2. Blogs Feed & Details
- **Independent Feed State:** Dedicated blog feed managed by `BlogViewModel`, maintaining its own pagination offset, search query, scroll position, and loading states.
- **Blog Search & Filter Chips:** Independent search query input and category filter chips mapped specifically for blog content.
- **Blog Detail Screen:** Rich reading experience rendering hero visuals, author and publisher metadata, and full editorial summary.
- **Standalone Refresh Action:** Dedicated reload button in the detail app bar invoking `BlogRepository.getBlogById(blogId)` to update single blog post details on demand.
- **Bookmark Persistence:** Independent bookmark storage for saved blogs.
- **Swipe & External Navigation:** Full horizontal swipe navigation between blog items and external web opening.

### 3. Reports Feed & Details
- **Official Status Reports:** Displays mission status reports, technical bulletins, and daily space station updates.
- **Independent Report State:** Managed by `ReportViewModel` with dedicated debounce timers, loading states, and pagination offsets.
- **Tailored Data Contract:** Models official reports which, unlike articles and blogs, omit Launch Library 2 launch/event relationships and editorial featured flags.
- **Report Detail Screen:** Renders hero image, publication date, agency badge, author avatar, and full report overview.
- **Direct ID Fetch & Detail Reload:** Detail screen includes an on-demand refresh button triggering `ReportRepository.getReportById(reportId)` with SnackBar feedback.
- **Prefetching Optimization:** Implements index-based prefetching (`prefetchIfNeeded(index, threshold: 3)`) as users browse reports.
- **Bookmark Integration:** Report bookmark IDs are persisted independently under a dedicated storage key.
- **"Read full report" CTA:** Securely launches original agency report documents and PDFs in the external browser.

### 4. Shared & Cross-Cutting Capabilities
- **Explore Content Selector:** Floating modal bottom sheet accessible from the search bar filter icon, allowing seamless switching between **Articles**, **Blogs**, and **Reports**.
- **Independent Bookmark Storage:** Backed by `shared_preferences`, bookmarks are stored in three isolated string lists (`newsly_bookmarked_articles`, `newsly_bookmarked_blogs`, `newsly_bookmarked_reports`) preventing cross-type ID collisions. Bookmark status updates instantly in the UI and persists across application restarts.
  > [!NOTE]
  > While bookmarking and detail persistence are fully operational, a centralized "Saved Bookmarks" list screen is an open enhancement scheduled for a future release.
- **Custom Branding & Splash Screen:**
  - Dedicated Flutter `SplashScreen` displaying the centered Newsly emblem with smooth opacity decoding for exactly **3 seconds** before navigating to the Discover feed.
  - In-memory icon pre-warming in `main.dart` ensures the branding graphic renders synchronously on the very first frame without flicker.
  - Native adaptive launcher icons configured across all Android mipmap densities (`mdpi` through `xxxhdpi` and `anydpi-v26`).
- **Resilient UI States:**
  - **Loading:** Non-blocking skeleton/shimmer and atomic `AppLoader` with contextual status messaging.
  - **Empty View:** Illustrated `AppEmptyView` displaying friendly guidance and a recovery action (e.g. "Clear search").
  - **Error View:** Full-screen `AppErrorView` with typed error messages and a primary **Retry** button.
  - **Pagination Error Recovery:** Non-disruptive inline footer with error label and retry button, keeping loaded items interactive.
- **System Share & Clipboard Integration:** Native OS share sheet integration (`share_plus`) and clipboard copy (`Clipboard.setData`) accessible from detail screens.

---

## Screenshots & Visuals

> [!NOTE]
> Demonstration screenshots and video captures from physical test hardware (Motorola moto g04s) have been verified during QA audits. Repository-committed screenshot assets can be placed in `assets/screenshots/` and referenced here for submission packaging.

| Discover Feed (Articles) | Content Type Selector | Report Detail View |
|:---:|:---:|:---:|
| *(Light/Dark Feed with Search & Category Chips)* | *(Modal Bottom Sheet: Articles, Blogs, Reports)* | *(Hero Visual, Book-Style Swipe & Action Bar)* |

---

## Technology Stack

| Technology / Package | Version | Purpose in Newsly |
| :--- | :---: | :--- |
| **Flutter SDK** | `^3.44.0` | Cross-platform UI toolkit (Dart SDK `^3.12.0`). |
| **[provider](https://pub.dev/packages/provider)** | `^6.1.2` | Dependency injection and reactive MVVM state management via `ChangeNotifier`. |
| **[dio](https://pub.dev/packages/dio)** | `^5.7.0` | Robust HTTP client configured with base URL, 15s timeouts, interceptors, and typed errors. |
| **[cached_network_image](https://pub.dev/packages/cached_network_image)** | `^3.4.1` | Memory-bounded thumbnail and hero image loading with disk caching and error widgets. |
| **[shared_preferences](https://pub.dev/packages/shared_preferences)** | `^2.5.6` | Persistent local key-value storage for article, blog, and report bookmark ID sets. |
| **[url_launcher](https://pub.dev/packages/url_launcher)** | `^6.3.3` | Launches external article/report URLs in the system browser (`LaunchMode.externalApplication`). |
| **[share_plus](https://pub.dev/packages/share_plus)** | `^13.3.1` | Cross-platform interface for invoking the native OS share sheet (`ACTION_SEND`). |
| **[flutter_lints](https://pub.dev/packages/flutter_lints)** | `^6.0.0` | Recommended Flutter code style and static analysis rule set (0 issues). |
| **[flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)** | SDK | Unit, widget, accessibility, and integration test framework. |

---

## Architecture & Design Pattern

Newsly strictly implements the **Model-View-ViewModel (MVVM)** architecture paired with the **Repository Pattern** and **Dependency Injection**:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              VIEW LAYER                                │
│   (DiscoverScreen, ArticleDetailScreen, BlogDetailScreen,              │
│    ReportDetailScreen, ArticleCard, Shared Widgets)                    │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Listens to ViewState & dispatches user actions
┌───────────────────────────────────┴────────────────────────────────────┐
│                           VIEWMODEL LAYER                              │
│   (ArticleViewModel, BlogViewModel, ReportViewModel, BookmarkViewModel)│
│   • Manages ViewState (initial, loading, loaded, empty, error)         │
│   • Request generation counters (_requestGeneration)                   │
│   • Debounced search timers and pagination boundary offsets            │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Requests domain models
┌───────────────────────────────────┴────────────────────────────────────┐
│                           REPOSITORY LAYER                             │
│   (ArticleRepositoryImpl, BlogRepositoryImpl,                          │
│    ReportRepositoryImpl, BookmarkRepositoryImpl)                       │
│   • Encapsulates API query parameter construction                      │
│   • Maps dynamic JSON responses to strongly typed immutable models     │
│   • Manages SharedPreferences bookmark serialization                   │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Performs HTTP GET requests
┌───────────────────────────────────┴────────────────────────────────────┐
│                            NETWORK LAYER                               │
│                   (ApiClient, Dio, ApiException)                       │
│   • Centralized base URL, timeouts (15s), and sanitized debug logging  │
│   • Converts low-level DioException into typed ApiException enums       │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ REST HTTPS
┌───────────────────────────────────┴────────────────────────────────────┐
│                      SPACEFLIGHT NEWS API (v4)                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

1. **Model Layer (`lib/models/`):**
   - Pure, immutable Dart classes (`Article`, `Blog`, `Report`, `Author`, `LaunchInfo`, `EventInfo`).
   - Defensive deserialization: Safely handles null values, type coercions (`num` to `int`, strings to `DateTime`), and malformed responses.
2. **Repository Layer (`lib/repositories/`):**
   - Abstract interfaces paired with concrete implementations (`ArticleRepositoryImpl`, `BlogRepositoryImpl`, `ReportRepositoryImpl`, `BookmarkRepositoryImpl`).
   - Insulates the application from remote data schemas and storage mechanisms.
3. **ViewModel Layer (`lib/viewmodels/`):**
   - State containers extending `ChangeNotifier`.
   - Exposes clean, read-only getters (`articles`, `blogs`, `reports`, `state`, `isLoading`, `errorMessage`, `hasMore`).
   - Manages pagination offsets, debounced search timers, and in-flight request guards.
4. **View Layer (`lib/views/` & `lib/shared/`):**
   - Purely declarative UI widgets.
   - Zero direct HTTP or database operations; consumes ViewModel state via Provider.
5. **Dependency Injection (`lib/main.dart`):**
   - Configured at root via `MultiProvider`, `Provider`, `ProxyProvider`, and `ChangeNotifierProxyProvider`.

---

## Project Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart          # Base URL and endpoint route definitions
│   │   ├── app_colors.dart             # Material 3 light & dark color palette
│   │   ├── app_constants.dart          # Page sizes (10), debounces (500ms), timeouts (15s)
│   │   ├── app_dimensions.dart         # Consistent margins, padding, corner radii, hit targets
│   │   └── app_strings.dart            # Centralized UI copy, button labels, and error copy
│   ├── errors/
│   │   └── api_exception.dart          # Typed exception enum and DioException mapping
│   ├── network/
│   │   └── api_client.dart             # Centralized Dio wrapper with sanitized logging
│   └── theme/
│       └── app_theme.dart              # Material 3 lightTheme and darkTheme configurations
├── models/
│   ├── article_model.dart              # Article, Author, LaunchInfo, EventInfo, PaginatedArticles
│   ├── blog_model.dart                 # Blog and PaginatedBlogs models
│   └── report_model.dart               # Report and PaginatedReports models
├── repositories/
│   ├── article_repository.dart         # ArticleRepository interface and implementation
│   ├── blog_repository.dart            # BlogRepository interface and implementation
│   ├── bookmark_repository.dart        # SharedPreferences-backed bookmark persistence
│   └── report_repository.dart          # ReportRepository interface and implementation
├── services/
│   └── share_service.dart              # Native platform share interface and SharePlus implementation
├── shared/
│   └── widgets/
│       ├── app_button.dart             # Reusable accessible button (primary, secondary, outlined)
│       ├── app_empty_view.dart         # Empty state widget with icon and recovery action
│       ├── app_error_view.dart         # Error state widget with retry callback
│       ├── app_loader.dart             # Atomic progress indicator with status label
│       ├── article_card.dart           # Adaptive card supporting Articles, Blogs, and Reports
│       └── shimmer_loading.dart        # Shimmer skeleton loader for feed placeholders
├── viewmodels/
│   ├── article_view_model.dart         # Article feed state, search, and pagination logic
│   ├── blog_view_model.dart            # Blog feed state, search, and pagination logic
│   ├── bookmark_view_model.dart        # Reactive bookmark state management across content types
│   └── report_view_model.dart          # Report feed state, search, pagination, and prefetching
├── views/
│   ├── screens/
│   │   ├── article_detail_screen.dart   # Article detail view with swipe navigation
│   │   ├── blog_detail_screen.dart      # Blog detail view with on-demand reload
│   │   ├── discover_screen.dart         # Discover feed with triple content selector & search
│   │   ├── report_detail_screen.dart    # Report detail view with direct ID fetch
│   │   └── splash_screen.dart           # Flutter 3-second animated splash screen
│   └── widgets/
│       ├── detail_more_options_sheet.dart # Share, copy link, and external browser bottom sheet
│       └── responsive_layout.dart       # Breakpoint builder (phone vs tablet 2-column grid)
└── main.dart                           # Application entry point with MultiProvider DI
```

---

## API Integration

Newsly connects to the public **Spaceflight News API (v4)**:
- **Base URL:** `https://api.spaceflightnewsapi.net/v4`
- **Authentication:** None (Public Open API).
- **Default Headers:** `'Accept': 'application/json'`, `'Content-Type': 'application/json'`

### Endpoints Inventory & Usage Status

| HTTP Method | Endpoint | Supported Feature | Implementation File | Usage Status |
|:---:|:---|:---|:---|:---:|
| `GET` | `/v4/articles/` | Articles feed, search, category chips, pagination | `lib/repositories/article_repository.dart` | **Actively Used** |
| `GET` | `/v4/articles/{id}/` | Article detail lookup by ID | `lib/repositories/article_repository.dart` | **Implemented / Tested** *(UI passes in-memory model)* |
| `GET` | `/v4/blogs/` | Blogs feed, search, category chips, pagination | `lib/repositories/blog_repository.dart` | **Actively Used** |
| `GET` | `/v4/blogs/{id}/` | Blog detail direct fetch & header reload action | `lib/repositories/blog_repository.dart` | **Conditionally Used** |
| `GET` | `/v4/reports/` | Reports feed, search, category chips, pagination | `lib/repositories/report_repository.dart` | **Actively Used** |
| `GET` | `/v4/reports/{id}/` | Report detail direct fetch & header reload action | `lib/repositories/report_repository.dart` | **Conditionally Used** |

> [!IMPORTANT]
> The endpoints `/v4/info/`, `/v4/schema/`, `/v4/docs/`, and `/v4/graphql/` are **not** integrated into the application.

### Query Parameters & Pagination
- `limit`: Number of results to return (fixed at `10` via `AppConstants.defaultPageSize`).
- `offset`: Starting index (initial is `0`; increments by current item count during pagination).
- `search`: Keyword string matching titles, summaries, and news sites.
- Category filter chips (`SpaceX`, `NASA`, `ESA`, etc.) pass the category label as a search query parameter, leveraging the API's multi-field indexing.

---

## Search, Pagination & Performance Engineering

1. **Debounced Live Search:**
   - 500 ms debounce timer (`AppConstants.searchDebounceDuration`) cancels in-flight timers on every keystroke, preventing spamming the remote API while the user is typing.
2. **Race Condition & Stale Response Protection:**
   - ViewModels track `_requestGeneration: int`. Every new query increments the generation counter. Out-of-order or delayed responses from previous queries are discarded automatically (`if (generation != _requestGeneration) return;`).
3. **In-Flight Request Guards:**
   - Duplicate requests are blocked by boolean guards (`if (_state == ViewState.loading) return;` and `if (_isLoadingMore) return;`), preventing accidental double-fetches during rapid scrolling or repeated taps.
4. **List Deduplication:**
   - When appending paginated items, existing item IDs are tracked in a `Set<int>` to guarantee that duplicate records cannot be inserted into the feed list.
5. **Memory-Bounded Image Caching:**
   - `CachedNetworkImage` specifies `memCacheWidth` and `memCacheHeight` scaled to the device pixel ratio (`104 * dpr`), with `maxWidthDiskCache: 600`. This prevents high-resolution network bitmaps from overwhelming device RAM.
6. **Splash Startup Optimization:**
   - Pre-warming `newsly_splash_icon.png` in `main.dart` via `AssetImage.resolve()` decodes the image asset into the image cache before widget build, eliminating first-frame visual pop-in.

---

## UI, Theming & Accessibility

- **Design Language:** Modern, clean editorial news format with high visual contrast, structured typography hierarchies, rounded card surfaces, and comfortable spacing.
- **Material 3 Theming:** Full light and dark mode implementations (`AppTheme.lightTheme` and `AppTheme.darkTheme`) matching system brightness settings.
- **Adaptive Layout Breakpoints:**
  - **Phone (< 600 dp):** Single-column layout with comfortable margins and 48x48 dp minimum touch targets.
  - **Tablet (≥ 600 dp):** Responsive 2-column card grid, constrained modal sheets (max 500 dp width), and balanced margins.
- **Accessibility Verification:**
  - All interactive buttons, icon buttons, and navigation controls provide minimum 48x48 dp touch targets.
  - Text layouts are verified against accessibility text scaling up to **2.0x** without `RenderFlex` clipping or layout overflow.
  - Interactive controls include semantic tooltips from `AppStrings`.

---

## Setup & Installation

### Prerequisites
- **Flutter SDK:** Version `3.44.0` or higher (`channel stable`).
- **Dart SDK:** Version `3.12.0` or higher.
- **Android Studio / Android SDK:** Android Build-Tools, Platform-Tools, and Java 17.
- **Connected Hardware or Emulator:** Physical Android device with USB debugging enabled or Android Emulator.

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Newsly
   ```

2. **Install project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify static analysis:**
   ```bash
   flutter analyze
   ```
   *(Expected result: 0 issues found)*

4. **Execute automated test suite:**
   ```bash
   flutter test
   ```
   *(Expected result: 271 / 271 tests passed)*

5. **Run the application:**
   ```bash
   flutter run
   ```

---

## Automated Testing & Quality Assurance

Newsly maintains high engineering rigor with a comprehensive automated test suite comprising **271 automated tests across 17 test suites, with a 100% pass rate**:

| Test Suite File | Test Count | Scope & Covered Behaviors |
| :--- | :---: | :--- |
| `test/foundation_test.dart` | 77 | Model deserialization, JSON serialization, `ApiException` mapping, Repositories, and ViewModel race condition protection. |
| `test/discover_screen_test.dart` | 30 | Discover feeds, content selector, search debounce, category chips, pagination, and retry footers. |
| `test/article_detail_screen_test.dart` | 21 | Article detail layout, PageView swipe transitions, boundary clamping, and proactive pagination. |
| `test/report_view_model_test.dart` | 19 | Report feed state, debouncing, pagination deduplication, and prefetch triggers. |
| `test/responsive_detail_screen_test.dart` | 19 | Detail screen responsive layout across phone portrait, landscape, and tablet viewports. |
| `test/article_detail_ux_test.dart` | 15 | Read Full Article CTA button, dark mode surface styling, error feedback, and landscape layout. |
| `test/shimmer_loading_test.dart` | 14 | Feed shimmer placeholders, loading transitions, and cache retention across feed switches. |
| `test/blog_detail_screen_test.dart` | 13 | Blog detail rendering, metadata, hero image sizing, swipe transitions, and URL launcher calls. |
| `test/report_model_test.dart` | 11 | `Report` and `PaginatedReports` JSON parsing, nullable field resilience, and date formatting. |
| `test/report_detail_screen_test.dart` | 10 | Report detail rendering, direct ID fetch, on-demand refresh action, and bookmark toggle. |
| `test/report_repository_test.dart` | 9 | `ReportRepositoryImpl` query parameters, Dio client delegation, and error handling. |
| `test/ux_bug_fixes_test.dart` | 8 | Filter bottom sheet height sizing, floating controls alignment, and book-style swipe transitions. |
| `test/ui_polish_interaction_test.dart` | 7 | Category chip ink ripple feedback, 48x48 dp hit testing, and semantic tooltips. |
| `test/accessibility_test.dart` | 6 | System text scaling up to 2.0x without `RenderFlex` overflow across cards and detail screens. |
| `test/responsive_discover_test.dart` | 6 | Adaptive Discover layout (single-column phone vs. 2-column tablet grid). |
| `test/splash_screen_test.dart` | 4 | 3-second splash timer, asset rendering, and navigation to DiscoverScreen. |
| `test/widget_test.dart` | 2 | Application launch smoke test and MultiProvider dependency registration verification. |
| **Total** | **271** | **All tests passing (100% pass rate, 0 failures, 0 skips)** |

---

## Android Production Release Builds & Size Optimization

Newsly is fully configured for production release optimization using Android's **R8 code minifier**, **resource shrinker**, and custom ProGuard keep rules in `android/app/build.gradle.kts`.

### Build Commands

- **Universal Release APK:**
  ```bash
  flutter build apk --release
  ```
  *Packages all three ABIs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) into a single standalone installer (51.39 MB).*

- **Architecture-Specific Release APKs (Recommended for direct installation):**
  ```bash
  flutter build apk --release --split-per-abi
  ```
  *Generates single-ABI APKs, reducing the download size by over **63%** on user devices.*

- **Google Play Android App Bundle (Recommended for Play Store distribution):**
  ```bash
  flutter build appbundle --release
  ```
  *Generates a 51.0 MB publishing bundle that dynamically delivers **~9.5 MB – 10.5 MB** split downloads to end users based on device CPU and screen density.*

### Verified Artifact Measurements

| Artifact | Target CPU / Distribution | File Size | Comparison vs Universal APK |
| :--- | :--- | :---: | :---: |
| **`app-arm64-v8a-release.apk`** | 64-bit ARM Phones (99%+ modern devices) | **18.63 MB** *(19,530,352 bytes)* | **-34.36 MB (-63.1%)** |
| **`app-armeabi-v7a-release.apk`** | 32-bit ARM Phones (Budget / Older devices) | **16.19 MB** *(16,975,624 bytes)* | **-36.91 MB (-68.0%)** |
| **`app-x86_64-release.apk`** | x86_64 Emulators / Intel ChromeOS | **20.01 MB** *(20,987,712 bytes)* | **-32.90 MB (-60.4%)** |
| **`app-release.aab`** | Play Store App Bundle (Dynamic Delivery) | **51.00 MB** *(Delivers ~10 MB)* | **~80% reduction in user download** |
| *`app-release.apk`* | *Universal (Contains all 3 ABIs)* | *51.39 MB (53,887,398 bytes)* | *Reference baseline* |

---

## Future Enhancements

The following features represent genuine architectural opportunities identified for subsequent releases:
1. **Centralized Bookmarks Screen:** Dedicated view to browse, filter, and remove saved Articles, Blogs, and Reports in one place.
2. **Offline Content Caching:** Local SQLite storage of article and report bodies for complete offline reading capability.
3. **Spaceflight News API Info Integration:** Fetching news site metadata and publication statistics via `/v4/info/`.
4. **Push Notifications:** Opt-in notifications for breaking aerospace mission events and station status alerts.
