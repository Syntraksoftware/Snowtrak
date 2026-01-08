# UI/UX Design Prompt for Syntrak

As an experienced UI/UX designer with 50+ years of experience working with major brands, create comprehensive design guidelines for **Syntrak**, a mobile sports tracking application built with Flutter. Syntrak is a skiing-focused fitness and community app that combines the activity tracking features of Strava with social community features similar to Reddit and Threads.

## Application Context

**Syntrak** is a Flutter-based mobile application that enables users to:
- Record and track skiing activities with GPS mapping
- Engage in a community-driven social feed (similar to Reddit/Threads)
- View and interact with other users' activities and posts
- Participate in groups, challenges, and clubs
- Manage personal profiles and activity history

## Current Application Structure

The app currently has the following navigation structure with 5 main tabs:

1. **Map Tab** (Record Activities) - Currently "RecordScreen"
   - Full-screen map interface for recording activities
   - Real-time GPS tracking with route visualization
   - Activity type selection (currently supports: run, ride, walk, hike, swim, other - needs to be redesigned for skiing)
   - Live metrics display (distance, pace, elevation, duration)
   - Start/pause/stop recording controls

2. **Community Tab** - Currently "CommunityScreen"
   - Social feed with posts, replies, likes, and reposts
   - Thread-style conversation interface
   - Compact composer for creating posts
   - Expandable reply threads
   - Similar to Reddit/Threads interaction patterns

3. **Home Tab** (Activities Feed) - Currently "ActivitiesScreen"
   - Feed of activities from users you follow
   - Activity cards showing metrics (distance, time, pace)
   - Similar to Strava's activity feed
   - Should display skiing activities prominently

4. **Groups/Activities Tab** - Currently "GroupsScreen"
   - Three sub-tabs: Active, Challenges, Clubs
   - Group activities and events
   - Challenges and competitions
   - Ski clubs and communities

5. **You Tab** (Profile) - Currently "ProfileScreen"
   - User profile and statistics
   - Personal activity history
   - Settings and preferences

## Current Design State

**Color Scheme:**
- Primary color: Orange/Red (#FF4500)
- Background: White (#FFFFFF)
- Secondary backgrounds: Off-white (#FAFAFA)
- Text: Black (#000000) and various shades of grey
- Accent: Orange/Red for selected states

**Typography:**
- Default Material Design typography
- Font sizes: 12-24px range
- Font weights: Normal, Bold (w600, w700)

**Current UI Patterns:**
- Material Design components
- Bottom navigation bar (5 tabs, no labels, icon-only)
- Card-based layouts for activities
- List-based layouts for feeds
- Map integration with Google Maps
- Minimalist, clean aesthetic

## Design Requirements

### 1. Color Scheme & Brand Identity

Design a cohesive color palette that:
- Reflects the skiing/winter sports theme (consider cool tones, snow-inspired colors, but maintain energy and excitement)
- Maintains excellent contrast for accessibility (WCAG AA minimum)
- Works well in both light and dark modes (consider dark mode support)
- Differentiates Syntrak from Strava while maintaining a professional, athletic feel
- Includes primary, secondary, accent, success, warning, and error colors
- Provides color variations for different skiing activity types (alpine, cross-country, freestyle, etc.)

### 2. Typography System

Create a comprehensive typography system that:
- Establishes clear hierarchy (headings, body, captions, labels)
- Is optimized for mobile readability
- Supports both short-form (community posts) and long-form (activity details) content
- Includes font size scales, line heights, letter spacing, and font weights
- Considers skiing-specific terminology and metrics display
- Ensures readability in various lighting conditions (outdoor use)

### 3. Iconography & Visual Language

Design guidelines for:
- Custom icon set that reflects skiing/snow sports theme
- Activity type icons (different skiing disciplines)
- Navigation icons that are intuitive and recognizable
- Social interaction icons (like, comment, repost, share)
- Status indicators (recording, paused, completed)
- Map markers and route visualization styles
- Consistent icon style (outlined, filled, or a hybrid approach)

### 4. Layout & Navigation

Redesign the layout system for each tab:

**Map Tab (Record Activities):**
- Optimal map-to-control ratio for mobile screens
- Placement of recording controls (start/pause/stop)
- Real-time metrics overlay design (distance, speed, elevation, time)
- Activity type selector interface
- Post-activity summary and save flow
- Skiing-specific metrics (vertical drop, runs completed, lift usage, etc.)

**Community Tab:**
- Feed layout optimized for thread-style conversations
- Post card design with clear hierarchy
- Reply threading visualization
- Composer placement and interaction
- Media attachment handling (photos, videos, route maps)
- Engagement metrics display (likes, replies, reposts)
- Search and filtering capabilities

**Home Tab (Activities Feed):**
- Activity card design inspired by Strava but with skiing focus
- Feed layout (infinite scroll, pull-to-refresh)
- Activity detail preview
- Social interactions (kudos, comments, shares)
- Filtering options (following, all, trending)
- Map previews for activities
- Skiing-specific activity metrics display

**Groups/Activities Tab:**
- Tab navigation design (Active, Challenges, Clubs)
- Group card/list layouts
- Challenge participation interface
- Club discovery and joining flow
- Event calendar and scheduling
- Group activity feeds

**You Tab (Profile):**
- Profile header design (avatar, stats, bio)
- Activity history layout (list, grid, calendar views)
- Statistics dashboard (total distance, vertical drop, days on mountain, etc.)
- Achievements and badges display
- Settings and preferences organization
- Social connections (followers, following)

**Bottom Navigation:**
- Redesign the 5-tab navigation bar
- Consider labels for better discoverability
- Active/inactive states
- Badge/notification indicators
- Accessibility considerations

### 5. Interactive Elements & Components

Design specifications for:
- Buttons (primary, secondary, text, icon buttons)
- Input fields (text inputs, search bars, composers)
- Cards and containers (elevation, shadows, borders, corner radius)
- Loading states and skeletons
- Empty states (no activities, no posts, etc.)
- Error states and retry mechanisms
- Pull-to-refresh interactions
- Swipe gestures (if applicable)
- Bottom sheets and modals
- Dialogs and alerts

### 6. Activity-Specific Design Elements

Skiing-focused components:
- Activity type selection (Alpine, Cross-Country, Freestyle, Backcountry, etc.)
- Skiing metrics visualization (vertical drop, runs, lift rides, speed, etc.)
- Trail/resort map integration
- Weather and conditions display
- Equipment tracking (skis, bindings, etc.)
- Season statistics and goals

### 7. Community Features Design

Social interaction patterns:
- Post creation flow (text, media, activity sharing)
- Thread navigation and expansion
- Reply composition and threading
- Like/repost/share interactions
- User profile previews
- Following/follower management
- Notification system design

### 8. Consistency Guidelines

Establish rules for:
- Spacing system (padding, margins, gaps)
- Border radius standards
- Shadow and elevation system
- Animation and transition guidelines
- Responsive breakpoints (if applicable)
- Component reuse patterns
- Design token system

### 9. Accessibility

Ensure:
- Color contrast ratios meet WCAG AA standards
- Touch target sizes (minimum 44x44 points)
- Screen reader compatibility
- Text scaling support
- Alternative text for images/icons
- Keyboard navigation support
- Focus indicators

### 10. Dark Mode Support

Design guidelines for:
- Dark mode color palette
- Component adaptations for dark mode
- Image/media handling in dark mode
- Map styling for dark mode
- Consistent theming system

## Technical Constraints

- **Framework:** Flutter (Material Design components available)
- **Platform:** Mobile (iOS and Android)
- **Screen Sizes:** Various mobile screen sizes (small phones to large phones)
- **Map Integration:** Google Maps Flutter plugin
- **State Management:** Provider pattern

## Deliverables Requested

Please provide:

1. **Comprehensive Design Guidelines Document** covering all aspects above
2. **Visual Design System** with:
   - Color palette with hex codes and usage guidelines
   - Typography scale with examples
   - Icon library specifications
   - Component library with states and variations
3. **Layout Specifications** for each of the 5 main tabs with:
   - Wireframes or layout descriptions
   - Component hierarchy
   - Spacing and sizing specifications
   - Interaction patterns
4. **Skiing-Specific Design Elements** including:
   - Activity type icons and visualizations
   - Metrics display patterns
   - Trail/resort integration concepts
5. **Implementation Recommendations** for:
   - Flutter-specific implementation approaches
   - Animation and transition suggestions
   - Performance considerations
   - Accessibility implementation

## Design Philosophy

The design should:
- Feel modern, energetic, and athletic (inspired by Strava's success)
- Support community engagement (inspired by Reddit/Threads)
- Celebrate skiing culture and winter sports
- Be intuitive for both casual and serious skiers
- Encourage activity recording and social sharing
- Maintain visual consistency across all features
- Prioritize usability and accessibility
- Feel premium but approachable

## Additional Considerations

- Consider seasonal theming (winter focus, but app is used year-round)
- Account for outdoor usage (bright sunlight readability)
- Design for one-handed use where possible
- Consider cold weather usage (gloves, reduced dexterity)
- Optimize for quick interactions (recording activities, quick posts)
- Support both portrait and landscape orientations where appropriate

---

Please create detailed, actionable design guidelines that can be easily understood and implemented by designers, developers, and stakeholders. The guidelines should be comprehensive enough to ensure consistency across the entire application while being flexible enough to accommodate future features and iterations.

