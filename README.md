HERE — SOCIAL-MEDIA-NETWORKING

1️⃣ CHATS (Offline-first, secure, lightweight)
Local DB (User device)
Use Drift + SQLite for reactive, type-safe storage
Store:
Messages (text, small media thumbnails/URLs only)
Chat metadata (timestamps, sender/receiver ID, status)
Last 50–100 messages per chat
Message queue: all new messages go to local DB first
Optional compression: text heavy compression; images moderate; videos low-quality previews only
Sync / Delivery Layer
Backend = temporary delivery agent, not permanent storage
Flow:
X sends → local DB
Sync → backend receives, checks Y online
Y offline → backend queues temporarily
Y online → local DB fetches messages (delta sync only)
Only sync when network detected, no constant polling
Offline Handling
Local DB handles reads/writes fully offline
Backend pushed only when network is available
Smart reconnection → avoid battery drain
Storage & Cleanup
Limit messages per chat (100)
Compress text, small media thumbnails; avoid insane video compression
Optionally allow cloud backup for older messages
Security
Local DB encryption (AES-256)
End-to-end encryption for messages → backend can’t read content
Feedback / UI
Standard messaging ticks:
Pending 🕒
Sent ✅
Received ✅✅
Read ✅✅ (highlighted)
✅ Advantages
Fully offline, fast, secure
Minimal storage
Real-time feel when network available
2️⃣ FEED (Metadata offline, media streamed)
Local DB
Store metadata only:
Post ID
Author
Timestamp
Text content (small)
Heat/engagement score
Media URL (streamed, not stored)
Media Streaming
Stream images/videos when opening feed
Cache only what’s needed for smooth scrolling
Delete cache when exceeding limit or on restart
Offline Fallback
If offline → show text + placeholder for media
Sync heat/engagement in background when online
Heat/Trending
Use local metadata to sort feed
Heat formula (likes/comments/shares / time decay)
Media streaming does not affect ranking
Optional Smart Caching
Cache top N posts in view
Videos can have low-res preview first
✅ Advantages
Tiny storage footprint
Fast scrolling
Offline-compatible
Fully scalable
Key principle:
Chats = full offline storage
Feed = metadata offline, media streamed
3️⃣ PROFILE (Lightweight, reactive, offline-friendly)
Local DB
Store essential info only:
User ID
Display name / username
Profile pic URL (streamed)
Bio / description
Stats: posts, followers/following, heat score
Optional settings/preferences
Avoid storing large media locally
UX Ideas
Quick tap → open profile
Show hot posts / trending content in thumbnails (streamed)
Editable bio, username, profile pic
Offline → cached text, placeholder images
Privacy & Offline
Sync selective metadata only
Followers/following lists fetched on-demand
Settings/preferences fully offline
Optional “Hot Activity” Panel
Show top posts or hottest comments
Stream media only, metadata offline
Keeps profile alive without storage bloat
✅ Advantages
Lightweight, scales easily
Offline-first friendly
Focus on trending activity (matches flames concept)
🔥 Core principles for all
Offline-first where possible
Streaming media only for feeds and chat media
Local DB = text + metadata + thumbnails/URLs
Backend = delivery + sync, not permanent storage
Real-time feel via Drift streams + delta sync
Heat / trending logic everywhere for engagement
User storage managed → delete old items, allow backup