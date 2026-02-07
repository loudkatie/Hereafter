# Hereafter

**Leave a message. Find it hereafter.**

A time-locked, location-pinned messaging app where you write to future-you. Drop a message where you are, lock it to a date, and when you return after that date — it unlocks. No AI. No filters. Just you, talking to yourself across time.

By [Loud Labs](https://loudlabs.com) · Proactive AI for real life.

---

## What Is Hereafter?

Hereafter is the anti-Instagram. Instead of broadcasting moments outward, you plant them inward — messages to yourself, anchored to the places where they happened, locked until a future date you choose.

The entire app is a conversation. No dashboards. No feeds. No map covered in pins. Just a chat thread between you and future-you, hosted by Hereafter as a warm, minimal guide.

**The core loop:**

1. You're somewhere that matters to you.
2. You write a message to future-you (up to 500 characters, optional photo).
3. You pick a date when it unlocks.
4. You leave. You forget.
5. Weeks, months, or years later — you return to that place after the unlock date.
6. Hereafter taps you. "Something you left here on March 3, 2026 just unlocked."
7. You read your own words. You remember who you were.
8. You can reply — to yourself, from a different time.

That's it. That's the whole app.

---

## Why Hereafter?

**"Here"** = place. **"After"** = time. The word itself means "from this point forward" — it carries weight without being heavy. It's familiar but no one owns it in the app space.

The name IS the product: you leave something *here*, and find it *after*.

---

## Product Philosophy

### What Hereafter IS:
- A conversation with future-you
- A reason to be present where you are
- Delayed gratification as a feature
- Messages that gain meaning with time
- Private by default — self-only in v1

### What Hereafter IS NOT:
- A social network
- A journal app
- A map app with pins
- A time capsule gimmick
- AI-generated anything

### Core Principles:
- **No AI in v1.** The magic is human — your words, your places, your future self discovering them. AI would dilute the emotional payload.
- **Text-first.** 500 character cap. Forces brevity and intention, just like a postcard.
- **One optional photo.** Not a gallery. Not a carousel. One image, if you want it.
- **Date-only time locks.** You pick a date, not a time. Simplicity over precision.
- **Self-only messaging (v1).** You write to you. No sharing, no social, no audience. That's the purity of it.
- **Presence over performance.** This app exists to make you look UP from your screen, not deeper into it.

---

## The Experience

### The App IS a Conversation

Hereafter's UI is a chat thread. It looks and feels like iMessage — because that's a mental model every human already knows. There is almost nothing to design because we're borrowing the most intuitive interaction pattern on earth.

### First Launch (Onboarding IS the First Message)

You open the app. Clean screen. A chat bubble appears:

> **Hereafter:** Hi. Welcome to Hereafter. What's your first name?

You type: *Katie*

> **Hereafter:** Hey Katie. Hereafter is simple. You leave a message to future-you, right where you are. We lock it to this place and a date you choose. When you come back after that date — we'll let you know it's here.
>
> Want to leave your first one?

You tap yes. You're IN. No tutorial. No settings screen. No onboarding carousel. The onboarding IS the first message.

### Composing a Message

Still in the chat. The compose experience is inline:

> **Hereafter:** You're at Peacebank Yoga Studio. What do you want to say to future-you?

You type your message (up to 500 characters). A camera button sits in the compose bar — tap it to add one photo, just like iMessage. Then:

> **Hereafter:** When should this unlock?

A simple date picker slides up. You pick a date. Done.

> **Hereafter:** Locked. You'll find this here when you come back after March 3, 2027. See you then.

### The Return (The Magic Moment)

Months or years later, you walk past Peacebank. Your phone taps you — a gentle haptic. A notification:

> **Hereafter:** Something you left at Peacebank on Feb 8, 2026 just unlocked.

You open the app. Your own words appear in the chat thread, timestamped, placed.

Below them:

> **Hereafter:** Want to add to it?

And you can reply. To yourself. From a different version of yourself. The thread grows. Same place. Same you. Different time.

### Subsequent Opens

Every time you open the app, Hereafter knows where you are and what's relevant:

- **Nothing here yet:** "You're at Blue Bottle Coffee. Want to leave something?"
- **Locked messages nearby:** "You have 2 messages locked near here. The first one unlocks on June 15."
- **Just unlocked:** "Something you left here on Feb 8, 2026 just unlocked. Want to see it?"
- **No location context:** Your thread history, with a simple "Leave a message where you are" prompt.

---

## Technical Architecture

### Platform
- **iOS 17+** (iPhone-first, Apple Watch + AirPods integrations planned)
- **SwiftUI** — declarative, modern, clean
- **Xcode 16+**

### Core Frameworks
- **CoreLocation** — Background location monitoring, geofence registration, visit detection
- **CloudKit** — Private database for user messages, sync across devices
- **CoreHaptics** — Tactile feedback for the "tap" when a message unlocks nearby
- **UserNotifications** — Lock screen notifications for unlocked messages
- **PhotosUI** — PHPicker for single photo attachment
- **MapKit** — Reverse geocoding for place names (background, not UI-facing in v1)

### Data Model

```swift
struct HereafterMessage: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let placeName: String?           // Reverse geocoded
    let createdAt: Date              // When the message was written
    let unlockDate: Date             // Date-only, when it becomes readable
    let messageText: String          // Required, 500 char max
    let photoURL: URL?               // Optional single photo
    let creatorID: String            // User identifier
    let isUnlocked: Bool             // Computed: unlockDate <= today
    let isRead: Bool                 // Has the user seen it post-unlock?
    let parentMessageID: UUID?       // If this is a reply to a previous message
    let threadID: UUID               // Groups messages at same location
}
```

### Geofencing Strategy
- Register geofences (up to iOS limit of 20 active) for locations with locked messages
- Prioritize geofences by: nearest unlock date first, then proximity
- On region entry + unlock date passed → trigger haptic + notification
- Background location monitoring for passive detection
- Smart rotation of geofences based on user movement patterns

### Privacy & Permissions
- **Location:** "Always" preferred for background geofencing, "While Using" as fallback
- **Photos:** Read-only access via PHPicker (no full library access needed)
- **Notifications:** Required for the core unlock experience
- **No account required in v1** — CloudKit anonymous container, device-bound identity
- **All data private** — CloudKit private database, no sharing endpoints

---

## Project Structure

```
Hereafter/
├── App/
│   ├── HereafterApp.swift              # App entry point
│   └── AppState.swift                  # Global app state
├── Models/
│   ├── HereafterMessage.swift          # Core data model
│   ├── UserProfile.swift               # Local user profile (first name, etc.)
│   └── ConversationThread.swift        # Thread grouping by location
├── Views/
│   ├── Chat/
│   │   ├── ChatView.swift              # Main chat thread (THE primary UI)
│   │   ├── MessageBubble.swift         # Individual message display
│   │   ├── ComposeBar.swift            # Inline compose with photo + date
│   │   └── DatePickerSheet.swift       # Simple date-only picker
│   ├── Onboarding/
│   │   └── OnboardingChatView.swift    # First-launch conversational flow
│   └── Settings/
│       └── SettingsView.swift          # Minimal — permissions, about
├── Services/
│   ├── LocationManager.swift           # CoreLocation + geofencing
│   ├── CloudKitManager.swift           # CloudKit CRUD operations
│   ├── HapticManager.swift             # CoreHaptics for unlock taps
│   └── NotificationManager.swift       # Local notification scheduling
├── Utilities/
│   ├── PlaceResolver.swift             # Reverse geocoding helper
│   └── DateFormatting.swift            # Human-readable date strings
└── Resources/
    ├── Assets.xcassets/
    └── Info.plist
```

---

## v1 Scope (MVP)

### Must Have
- [ ] Conversational onboarding (first name, explanation, first message)
- [ ] Chat-style main view (iMessage mental model)
- [ ] Compose inline: text (500 char), optional photo, date picker
- [ ] Location detection + reverse geocoding for place names
- [ ] Geofence registration for message locations
- [ ] Haptic tap + notification on unlock (location + date match)
- [ ] Read your own unlocked messages in the thread
- [ ] Reply to your own past messages (thread grows over time)
- [ ] CloudKit private storage (device-synced)
- [ ] Permissions flow (location, notifications, photos)

### Won't Have (v1)
- No AI / ML
- No social / sharing / other users
- No map view
- No search
- No export
- No Apple Watch / AirPods (future)
- No video
- No account creation (CloudKit anonymous)

---

## Brand

- **Tagline:** "Leave a message. Find it hereafter."
- **Tone:** Warm, minimal, human. Like a handwritten note, not a tech product.
- **Anti-positioning:** Not a social network. Not a journal. Not nostalgia-bait. It's a conversation with the most important person in your life — future you.
- **Visual language:** Clean. Quiet. Chat bubbles on white. Almost no chrome. The content IS the interface.

---

## Loud Labs

Hereafter is built by [Loud Labs](https://loudlabs.com), a spatial computing company building proactive AI tools that guide users through complex tasks without requiring prompt engineering skills. Our apps are location-first, audio-first, and designed to help users look UP from their screens.

**Adjacent products:**
- **Kilroy** — Geo-pinned photo memories. Camera-based capture anchored to places.
- **Rounds AI** — Medical translator for family caregivers.
- **Sotto** — Proactive, location-aware voice companion (hackathon prototype).

---

## License

Copyright © 2025-2026 Loud Labs. All rights reserved.
