```mermaid
graph LR
    A[User Action] --> B{Online?}
    B -->|Yes| C[Sync immediately to Backend]
    B -->|No| D[Queue in Local Storage]
    D -->|Reconnect| E[Sync Queue to Backend]
    C --> F[Backend = Source of Truth]
```

User Experience Priority:
- Users expect to see their posts immediately (even offline)
- But thread data must be consistent across devices → backend as final authority

# MUST work offline:
- Draft post composition ✍️
- Reading cached threads 📖
- Comment drafting 💬

# MUST sync to backend:
- Post publishing 🌐
- Upvote/downvote counts 🔢
- User reputation systems 🏆


```mermaid
graph TD
    A[User Posts] --> B{Online?}
    B -->|Yes| C[Immediate Sync Attempt]
    B -->|No| D[Save to Local Queue]
    C --> E{Sync Success?}
    E -->|Yes| F[Mark as Published]
    E -->|No| G[Save to Queue + Mark Failed]
    D --> H[Show Queued Status]
    G --> I[Show Retry Button]
```