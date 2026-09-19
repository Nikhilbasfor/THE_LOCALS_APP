# THE LOCALS (BookYourGuide / yatraki_mobile) - Project Handoff

## Context
- App Name: THE LOCALS (yatraki_mobile)
- Type: Cross-platform Flutter project (Android & iOS)
- Previous Conversation: ff0e8fc9-0743-45a4-9b31-e2de02cb270c
- Related Projects: THG_admin (React admin portal), YatraKi (Android Kotlin prototype)

## Goal
Upgrade the UI from feeling like an AI-generated template to a fluid, human-crafted, premium app using flutter_animate and spring physics while keeping the current Himalayan design.

## Status: Completed (flutter_animate Spring Micro-Interactions Upgrade)
All key micro-interactions and tactile spring physics have been implemented:
1. Added `flutter_animate: ^4.5.2` to `pubspec.yaml`.
2. Created `lib/widgets/spring_interactions.dart` with `SpringTapFeedback`, `SpringCard`, `BouncingButton`, `BespokeAnimationExtensions` (`.staggeredEntrance()`, `.springPop()`), and `bespokeBouncingScrollPhysics`.
3. Upgraded `RoleSelectionScreen` with spring cards, haptic feedback, and staggered entrance.
4. Upgraded `ExploreHomeScreen` with `SpringCard`, `Hero` image transition (`hero_exp_image_${experience.id}`), `CachedNetworkImage`, and staggered cascading feeds.
5. Upgraded `ExperienceDetailScreen` with matching `Hero` header image, staggered detail body sections, and `BouncingButton` for "Book Journey Now".
6. Upgraded `TravellerDashboardTab` with `SpringCard` quick actions, hero banner, upcoming booking cards, and horizontal featured feed.
7. Upgraded `TravellerMainScreen` & `GuideMainScreen` with spring pop icons and selection haptic clicks.
8. Upgraded `TravellerBookingsTab` & `TravellerWishlistTab` with tactile spring cards and cascading entries.
