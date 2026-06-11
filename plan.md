# Sacred KG Flutter MVP — Codex Development Plan

## Project Goal
Build an MVP Flutter mobile app about sacred places and petroglyphs of Kyrgyzstan using **mock data only** for now, without a real backend. The app should look modern, be hackathon-friendly, and be structured in a way that later allows easy migration to a real API/backend.

This document is written as an execution plan for Codex and the development team.

---

## 1. Product Scope for This Phase

### Objective of current phase
Create a working Flutter prototype that demonstrates the main product idea and user flow using local/mock data.

### Important constraint
- **No real backend yet**
- **No real authentication provider yet**
- **No real booking integration yet**
- **No real AI backend yet**
- Everything should run from local/mock repositories and local JSON/Dart data models

### Main deliverable
A polished Flutter application prototype with the following sections:
1. Auth flow
2. Home menu
3. Regions map / region selection
4. Places catalog
5. Place detail screen
6. AI assistant UI with mock responses
7. Feed/news prototype
8. Booking form prototype
9. Settings
10. Profile/account

---

## 2. MVP Features for Mock Version

## 2.1 Auth
Implement UI + mock logic for:
- Splash screen
- Onboarding / welcome screen
- Login
- Register
- Guest mode (optional)
- Logout
- Delete account confirmation (mock only)

### Mock behavior
- Login succeeds if fields are non-empty
- Register succeeds locally
- User session is stored locally via shared preferences / local storage

---

## 2.2 Main Menu
After login, user lands on a main menu with 7 sections:
1. Map of Kyrgyzstan regions
2. All places catalog
3. AI assistant
4. Feed / community posts
5. Booking
6. Settings
7. Account

### Notes
- Make this screen attractive and presentation-ready
- Use cards, icons, subtle animation if possible
- Include a short app slogan / header

---

## 2.3 Regions Map
For MVP, do **not** implement a true 3D geographic map.

### Instead
Use one of these simplified approaches:
- stylized image map with tappable regions
- custom widget with 7 region cards
- pseudo-3D region selector UI

### Required behavior
- Show 7 regions of Kyrgyzstan
- On selecting a region, navigate to a filtered list of places for that region

### Regions
- Chuy
- Issyk-Kul
- Naryn
- Talas
- Osh
- Jalal-Abad
- Batken

---

## 2.4 Catalog of Places
Build a catalog screen that shows all places.

### Required features
- Search by title
- Filter by region
- Filter by type
- Sort by rating or popularity (mock)
- Open place details

### Place types
- Sacred place
- Petroglyph site
- Mausoleum
- Sacred spring
- Historical complex
- Archaeological site
- Natural sacred place

---

## 2.5 Place Details
Each place detail screen should include:
- title
- cover image
- gallery
- short description
- full description
- cultural / historical note
- visiting rules
- route / how to get there
- region
- type
- rating
- reviews
- CTA buttons:
  - Ask AI
  - Book visit
  - Add to favorites

### Mock requirement
- Reviews and rating are mock/local
- Favorite toggles locally

---

## 2.6 AI Assistant
Create an assistant screen with character selection.

### Characters
- Atashka
- Apashka

### MVP behavior
- Character selection UI
- Character avatar image or lightweight animation
- Chat interface
- Predefined quick prompts
- Mock response engine using local logic

### Mock response approach
Option 1:
- keyword-based mock replies

Option 2:
- place-context-aware responses stored in local mock repository

### Example questions
- What is special about this place?
- What rules should I follow?
- What traditions are connected to this site?
- When is the best time to visit?

### Important
Design the module so that later it can be swapped to a real LLM API without rewriting UI.

---

## 2.7 Feed / Community Section
Build a simple Threads-like community feed prototype.

### Required features
- List of posts
- Post card with user, text, optional image, timestamp
- Like button
- Comment count
- Post type badge:
  - Review
  - Issue
  - Tip
  - Experience
- Create post screen

### Mock behavior
- Local static feed list
- Creating a post adds it only in local app state during runtime

---

## 2.8 Booking Section
This should be presented as a **visit planning / booking request** prototype.

### Required fields
- Select place
- Select date
- Number of people
- Optional notes
- Required checkbox for rules confirmation
- Submit button

### Additional idea
- Decorative calendar treatment inspired by Kyrgyz calendar
- Simple moon phase indicators can be mocked visually

### Submission behavior
- Save booking locally in mock storage/state
- Show success message and add to “My bookings”

---

## 2.9 Settings
Required settings screen:
- Light / dark theme toggle
- Language selector: RU / KG / EN
- Music toggle
- Contact developers section
- About app section

### Mock behavior
- Persist theme and language locally
- Music toggle is just stored as setting unless actual audio is implemented

---

## 2.10 Account
Required account screen:
- User profile header
- My bookings
- My posts
- Favorites
- Logout
- Delete account

### Mock behavior
- all user-specific data is local/runtime or local storage only

---

## 3. Recommended Flutter Architecture

Use a structure that is simple enough for fast development, but scalable for future backend integration.

## Recommended approach
- **Feature-first folder structure**
- **Clean-ish separation** between UI, domain models, and data sources
- **Repository pattern** with mock repositories
- **State management:** Riverpod preferred, Provider acceptable
- **Routing:** go_router preferred

### Why this approach
This gives:
- easy maintenance
- good demo quality
- future migration to backend without large rewrites

---

## 4. Suggested Tech Stack

## Core
- Flutter
- Dart

## Packages
Suggested package list:
- `flutter_riverpod`
- `go_router`
- `freezed_annotation` or simple manual models
- `json_annotation` if using JSON mocks
- `shared_preferences`
- `google_fonts`
- `flutter_svg`
- `intl`
- `cached_network_image` or local assets only
- `equatable` if needed

Optional:
- `flutter_animate`
- `lottie`
- `rive`

### Recommendation for current phase
Keep dependencies minimal. Do not overcomplicate.

---

## 5. Folder Structure

Recommended project structure:

```text
lib/
  app/
    app.dart
    router/
      app_router.dart
    theme/
      app_theme.dart
      color_palette.dart
      text_styles.dart
  core/
    constants/
      app_constants.dart
    utils/
      result.dart
      validators.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_card.dart
      loading_view.dart
      empty_view.dart
  data/
    models/
      user_model.dart
      region_model.dart
      place_model.dart
      review_model.dart
      post_model.dart
      booking_model.dart
      ai_character_model.dart
    mock/
      mock_users.dart
      mock_regions.dart
      mock_places.dart
      mock_reviews.dart
      mock_posts.dart
      mock_bookings.dart
      mock_ai_responses.dart
    repositories/
      auth_repository.dart
      places_repository.dart
      feed_repository.dart
      booking_repository.dart
      settings_repository.dart
      ai_repository.dart
      profile_repository.dart
    repositories_mock/
      mock_auth_repository.dart
      mock_places_repository.dart
      mock_feed_repository.dart
      mock_booking_repository.dart
      mock_settings_repository.dart
      mock_ai_repository.dart
      mock_profile_repository.dart
  features/
    auth/
      presentation/
        screens/
        widgets/
        providers/
    home/
      presentation/
        screens/
        widgets/
    map/
      presentation/
        screens/
        widgets/
        providers/
    places/
      presentation/
        screens/
        widgets/
        providers/
    ai_assistant/
      presentation/
        screens/
        widgets/
        providers/
    feed/
      presentation/
        screens/
        widgets/
        providers/
    booking/
      presentation/
        screens/
        widgets/
        providers/
    settings/
      presentation/
        screens/
        widgets/
        providers/
    account/
      presentation/
        screens/
        widgets/
        providers/
  main.dart
```

---

## 6. Data Modeling Guidance

Even though the app uses mock data, define real models from the beginning.

## Core models to create
- User
- Region
- Place
- PlaceType
- Review
- Post
- Comment
- Booking
- AICharacter
- AppSettings

### Important rule
Codex should implement models first before building screens that depend on them.

---

## 7. Mock Data Strategy

There are two acceptable approaches:

## Option A — Mock data in Dart files
Best for speed.

Example:
- `mock_places.dart`
- `mock_regions.dart`
- `mock_posts.dart`

## Option B — JSON assets
Best if you want easier future replacement.

### Recommendation
For hackathon speed, use **Dart mock lists** first.
Later, if needed, move to JSON.

### Minimum mock dataset
Prepare:
- 7 regions
- 12 to 15 places
- 20 reviews
- 10 posts
- 5 bookings
- 2 AI characters
- 1 current mock user

### Example places distribution
- Chuy: 2–3 places
- Issyk-Kul: 3 places
- Naryn: 2 places
- Osh: 2 places
- Jalal-Abad: 2 places
- Talas: 1 place
- Batken: 1 place

---

## 8. UI/UX Guidance

The app should feel modern, calm, cultural, and premium.

## Style direction
- clean layout
- elegant typography
- soft earth/nature inspired palette
- subtle national identity accents
- avoid clutter

## Visual direction ideas
- sand / stone / sky / turquoise / warm neutral palette
- cards with rounded corners
- minimal gradients
- light decorative patterns inspired by Kyrgyz ornaments

## Home screen recommendation
Use a dashboard style layout:
- greeting/header
- featured sacred places carousel
- 7 feature cards / menu grid

## Place detail recommendation
Make this one of the strongest screens visually.
It will likely be the most important demo screen.

---

## 9. State Management Guidance

Use Riverpod providers for:
- auth state
- selected region
- catalog filters
- favorites
- feed posts
- bookings
- settings
- AI selected character and messages

### Rule for Codex
Avoid tightly coupling UI directly to raw mock data files.
Always read via repository/provider where practical.

---

## 10. Routing Plan

Recommended routes:

```text
/
/splash
/onboarding
/login
/register
/home
/map
/region/:id
/catalog
/place/:id
/ai
/feed
/feed/create
/booking
/my-bookings
/settings
/account
/favorites
/my-posts
```

### Rule
Define routing early so the app structure stays stable.

---

## 11. Recommended Build Order

Codex should implement the project in the following order.

## Phase 1 — Project Setup
1. Create Flutter project
2. Configure theme
3. Configure routing
4. Add folder structure
5. Add base reusable widgets

## Phase 2 — Models and Mock Repositories
6. Create domain/data models
7. Add mock data lists
8. Implement repository interfaces
9. Implement mock repository classes

## Phase 3 — Auth and App Shell
10. Splash screen
11. Onboarding
12. Login
13. Register
14. Session persistence mock
15. Home screen with 7 sections

## Phase 4 — Core Browsing Experience
16. Regions screen / map selector
17. Region places list
18. Catalog screen
19. Search and filters
20. Place detail screen
21. Favorites
22. Reviews UI

## Phase 5 — Additional Feature Screens
23. AI assistant UI + mock responses
24. Feed screen
25. Create post screen
26. Booking form
27. My bookings screen
28. Settings screen
29. Account screen

## Phase 6 — Polish
30. Dark theme support
31. Localization structure setup
32. Animation/polish
33. Error/empty states
34. Demo data QA
35. Presentation polish

---

## 12. Suggested Implementation Rules for Codex

Codex should follow these rules during implementation:

### Rule 1
Do not start with backend code. This phase is Flutter-only with mock repositories.

### Rule 2
Implement reusable components early:
- buttons
- text fields
- cards
- app bars
- chips
- search bar
- empty state views

### Rule 3
Keep business logic out of widgets where possible.

### Rule 4
Separate models, repositories, providers, and UI.

### Rule 5
Use placeholder/local images and avoid external dependencies unless necessary.

### Rule 6
Make screens navigable as early as possible, even if content is still mock.

### Rule 7
Keep the code presentation-friendly:
- readable names
- small widgets
- no messy duplicate code

### Rule 8
Build for future backend migration:
- repository interfaces should remain stable
- mock implementations should be replaceable later

---

## 13. Localization Plan

Even in MVP, prepare the structure for multilingual support.

### Languages
- Russian
- Kyrgyz
- English

### For current phase
It is acceptable to:
- fully implement UI text in Russian first
- structure localization so KG and EN can be added later

### Recommendation
At minimum:
- language setting exists
- app strings are not hardcoded everywhere in random widgets

---

## 14. Theme Plan

Implement both light and dark theme early enough.

### Theme settings
- light mode
- dark mode
- saved locally

### Important
Use a central theme file. Avoid inline styling everywhere.

---

## 15. AI Assistant Mock Design

Since there is no real backend yet, simulate AI behavior.

## Recommended mock logic
- if user is on a place detail screen and opens AI, pass selected place context
- AI repository returns canned responses based on:
  - selected character
  - place type
  - keywords in prompt

### Example response categories
- history
- traditions
- visit rules
- timing
- route

### Example
If prompt contains “rules” or “как себя вести”, return place visit rules.
If prompt contains “что это за место”, return short description.

### Important
The chat UI must look real, even if responses are mocked.

---

## 16. Booking Mock Design

Bookings should be stored in local state and optionally in local persistence.

### Required fields in model
- bookingId
- placeId
- placeTitle
- date
- peopleCount
- notes
- rulesConfirmed
- status
- createdAt

### Mock statuses
- pending
- approved
- rejected

### For demo
Use pending as default after submission.

---

## 17. Feed Mock Design

Posts model should include:
- id
- userName
- userAvatar
- text
- imageUrl optional
- timestamp
- likeCount
- commentCount
- postType
- placeId optional

### Demo requirement
At least a few posts should feel realistic and culturally relevant.

---

## 18. Recommended Demo Data Content

To make the prototype convincing, mock content should not feel generic.

### Place content should include
- real-sounding Kyrgyz place names
- concise but rich descriptions
- respectful visit rules
- route guidance in simple text
- clear differentiation between sacred sites and petroglyph locations

### Feed content examples
- a visitor sharing impressions
- a user reporting access difficulty
- a short review after visiting
- a recommendation about best season/time to visit

---

## 19. Testing Checklist for Mock MVP

Before considering the prototype complete, verify:

### Navigation
- all major screens open correctly
- deep navigation to place detail works
- back navigation works

### State
- login state persists
- favorites update correctly
- booking is added to my bookings
- created post appears in feed
- selected theme persists

### UI
- no overflow on common device sizes
- loading/empty states look acceptable
- cards and text spacing are consistent

---

## 20. What Not to Build Yet

Do **not** spend time on these in current phase unless everything else is complete:
- real backend
- real maps SDK integration
- real 3D engine
- real AI API integration
- real push notifications
- real admin panel
- advanced moderation
- payment system
- complex offline sync

---

## 21. Definition of Done

This Flutter mock MVP phase is done when:
- app launches successfully
- user can login/register in mock flow
- main menu works
- regions browsing works
- catalog and filters work
- place detail screen is polished
- AI assistant UI works with mock responses
- feed is visible and post creation works locally
- booking request works locally
- settings persist locally
- account screen shows local user-related data
- codebase is clean and ready for backend integration later

---

## 22. Next Phase After Mock MVP

After this phase is approved, next step is:
1. Replace mock auth with real auth
2. Replace mock repositories with backend repositories
3. Connect real DB and storage
4. Add real AI backend
5. Add content admin panel
6. Add real moderation and booking workflows

---

## 23. Immediate Action List for Codex

Codex should begin with the following concrete tasks:

### Step 1
Create a new Flutter project and set up dependencies.

### Step 2
Create the folder structure from this document.

### Step 3
Implement:
- theme
- router
- reusable widgets

### Step 4
Create models:
- User
- Region
- Place
- Review
- Post
- Booking
- AICharacter

### Step 5
Create mock repositories and sample data.

### Step 6
Implement screens in this order:
1. Splash
2. Login/Register
3. Home
4. Regions/Map
5. Catalog
6. Place Detail
7. AI Assistant
8. Feed
9. Booking
10. Settings
11. Account

### Step 7
Add polish, local persistence, and demo-ready UI improvements.

---

## 24. Final Notes

This project should be built as a **convincing MVP prototype**, not as a fully production-ready platform.

The main goals of the current phase are:
- strong presentation value
- clean architecture
- mock-driven development
- future scalability
- realistic implementation speed for a small team

If Codex must choose between complexity and demo quality, it should prefer:
- cleaner UX
- stable navigation
- strong place details
- good visual polish
- believable mock interactions

