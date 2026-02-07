# Hereafter — Product & Technical Spec
# Loud Labs · February 2026

---

## 1. Product Definition

**One-liner:** Time-locked, location-pinned messages from you to future-you.

**Core insight:** The most powerful message you'll ever receive is one from yourself, found in a place that mattered, at a time you've forgotten why.

**Target user:** Anyone with an iPhone who has places that matter to them. Not tech enthusiasts — humans. Parents, travelers, romantics, grievers, dreamers. Anyone who has ever thought "I want to remember how this feels right now."

---

## 2. Core Loop

```
PLANT → FORGET → RETURN → DISCOVER → REPLY
```

1. **PLANT:** User writes a message (500 char max, optional photo) at their current location. Picks an unlock date.
2. **FORGET:** Message is locked. User moves on with their life. The app is quiet.
3. **RETURN:** User physically returns to the location after the unlock date.
4. **DISCOVER:** Hereafter taps them (haptic) and notifies: "Something you left here just unlocked."
5. **REPLY:** User reads their past self's words. Can reply, creating a growing thread across time.

---

## 3. UX Architecture

### Primary Screen: The Chat Thread

The entire app is ONE screen — a chat view. Everything happens here:
- Onboarding (first launch)
- Composing messages
- Reading unlocked messages
- Replying to past self
- Location-aware prompts from Hereafter

### Hereafter as Host

Hereafter is the "third voice" — a warm, minimal guide that surfaces context:
- Knows where you are (reverse geocoded place name)
- Knows what's locked/unlocked nearby
- Prompts naturally, never aggressively
- Speaks in short, warm sentences — never corporate, never robotic

### Interaction Model

All input happens in the compose bar at the bottom of the chat — identical to iMessage:
- Text input (primary)
- Camera button (optional single photo)
- Date picker (slides up inline when composing)
- Send button

### Chat Bubble Types

| Bubble Type | Source | Style |
|---|---|---|
| Hereafter prompt | System | Left-aligned, subtle gray |
| User message (locked) | User | Right-aligned, muted/locked indicator |
| User message (unlocked) | User | Right-aligned, full color, timestamp + place |
| User reply | User | Right-aligned, different shade, shows time delta |

---

## 4. Data Model (Detailed)

### HereafterMessage
| Field | Type | Required | Notes |
|---|---|---|---|
| id | UUID | Yes | Primary key |
| threadID | UUID | Yes | Groups messages at same location |
| parentMessageID | UUID? | No | Links replies to originals |
| coordinate.latitude | Double | Yes | Where the message was planted |
| coordinate.longitude | Double | Yes | Where the message was planted |
| placeName | String? | No | Reverse geocoded (e.g., "Peacebank Yoga Studio") |
| createdAt | Date | Yes | Timestamp of creation |
| unlockDate | Date | Yes | Date-only (no time component) when it becomes readable |
| messageText | String | Yes | 500 character max |
| photoAssetID | String? | No | CloudKit asset reference |
| creatorID | String | Yes | Device-bound user identifier |
| isRead | Bool | Yes | Has user seen it post-unlock? Default false |

### UserProfile (Local)
| Field | Type | Required | Notes |
|---|---|---|---|
| firstName | String | Yes | Collected during onboarding |
| createdAt | Date | Yes | First launch date |
| hasCompletedOnboarding | Bool | Yes | Gate for first-launch flow |

### ConversationThread
| Field | Type | Notes |
|---|---|---|
| id | UUID | Thread identifier |
| coordinate | CLLocationCoordinate2D | Center point of the thread's location |
| placeName | String? | Display name for the location |
| messages | [HereafterMessage] | All messages in this thread, ordered by createdAt |
| oldestUnlockDate | Date | Earliest unlock date in thread |
| hasUnreadUnlocked | Bool | Computed: any unlocked + unread messages? |

---

## 5. Geofencing Architecture

### iOS Geofencing Constraints
- Maximum 20 active geofences per app
- ~100m radius minimum for reliable triggering
- Background location required for passive monitoring

### Hereafter Geofence Strategy
1. **Priority ranking:** Sort all message locations by (a) has unlocked but unread messages, (b) nearest unlock date, (c) proximity to user's last known location
2. **Active set:** Register top 20 geofences from priority list
3. **Rotation:** On significant location change, re-evaluate and rotate geofences
4. **Radius:** 150m default (balances accuracy with battery)
5. **Trigger:** On region entry → check if any messages at this location have passed unlock date → if yes, fire haptic + notification

### Fallback Strategy
- **Visit monitoring:** Use CLVisit for detecting when user spends time at a location (lower battery cost)
- **Significant location changes:** Re-evaluate geofence set on major moves
- **Manual check:** When user opens app, check current location against all messages

---

## 6. Notification & Haptic Design

### Unlock Notification
- **Title:** "Hereafter"
- **Body:** "Something you left at [Place Name] on [Date] just unlocked."
- **Category:** Actionable — "Read" / "Later"
- **Sound:** Custom, gentle, distinctive (not a ping — more like a soft chime)

### Haptic Pattern
- Custom CoreHaptics pattern: gentle tap-pause-tap
- Distinct from standard iOS haptics
- Should feel like someone tapping your shoulder, not buzzing your pocket

---

## 7. Permissions Flow

Handled conversationally within the chat, not as modal interrupts:

1. **Location (first message):**
   > "To anchor your message here, I need to know where 'here' is. Okay to share your location?"
   > [Allow Location → system prompt]

2. **Notifications (after first message planted):**
   > "When this unlocks and you're nearby, I'll let you know. Can I send you a notification when that happens?"
   > [Allow Notifications → system prompt]

3. **Photos (when user taps camera):**
   > Standard PHPicker — no special permission needed for limited access

---

## 8. Development Phases

### Phase 1: Foundation (Current)
- Project setup, data model, CloudKit schema
- Chat UI skeleton
- Onboarding flow
- Basic compose (text + date)

### Phase 2: Location
- CoreLocation integration
- Geofence registration
- Reverse geocoding
- Background monitoring

### Phase 3: Unlock Experience
- Haptic patterns
- Notification scheduling
- Unlock flow in chat
- Reply threading

### Phase 4: Polish
- Photo attachment
- Edge cases (no location, no network, etc.)
- Permissions flow refinement
- App Store prep

---

## 9. Future (Post-v1, Not Now)

- **Shared messages:** Leave a message for someone else to find at a place
- **Apple Watch:** Haptic tap on wrist, read message via Siri
- **AirPods:** Audio playback of your own message (hear past-you speak)
- **Themes/trends:** "You've left 12 messages at coffee shops this year"
- **Map view:** See where your messages are planted (discovery, not primary)
- **Anniversary nudges:** "It's been one year since you left a message at Peacebank"

---

*Document version: 1.0 · Feb 7, 2026 · Katie + Claude, Loud Labs*
