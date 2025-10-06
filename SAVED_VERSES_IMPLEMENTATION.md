# Saved Verses Feature Implementation

## Overview
Implemented complete functionality for users to save their favorite Bible verses, view them in their profile, and navigate directly to saved verses in the Bible reader.

## Changes Made

### 1. Database Migration (`backend/database/migrations/005_add_saved_verses.sql`)
- Created new `saved_verses` table with columns:
  - `id` (UUID, primary key)
  - `user_id` (UUID, references auth.users)
  - `book`, `chapter`, `verse` (integers)
  - `verse_text` (text - stores verse content at save time)
  - `translation` (text - e.g., "NIV", "ESV", "KJV")
  - `created_at` (timestamp)
- Added indexes for performance
- Implemented Row Level Security (RLS) policies
- Added unique constraint to prevent duplicate saves

**⚠️ IMPORTANT: You need to run this migration in your Supabase database before the feature will work.**

### 2. UserDataManager Updates
Added new data model and methods:

#### New Model: `SavedVerse`
```swift
struct SavedVerse: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    let book: Int
    let chapter: Int
    let verse: Int
    let verse_text: String
    let translation: String?
    let created_at: String
    
    var verseReference: String { ... }
    var formattedDate: String { ... }
    var relativeDate: String { ... }
}
```

#### New Methods:
- `@Published var savedVerses: [SavedVerse]` - Published array for SwiftUI binding
- `fetchSavedVerses(userId:)` - Fetches user's saved verses from database
- `saveVerse(book:chapter:verse:verseText:translation:)` - Saves a verse
- `unsaveVerse(book:chapter:verse:translation:)` - Removes a saved verse
- `isVerseSaved(book:chapter:verse:translation:)` - Checks if verse is already saved

### 3. BibleView Updates
- Updated `saveAction` to actually save/unsave verses (was previously just a debug print)
- Integrated with UserDataManager to save verse text and translation
- Shows filled heart icon (❤️) in action menu when verse is already saved
- Button text changes from "Save verse" to "Unsave verse" based on state
- Supports toggling: tap to save, tap again to unsave
- **Visual Indicator**: Small red heart icon (❤️) appears at the end of saved verses (similar to note icon)
  - Proportionally sized to font setting
  - Appears alongside note icon if verse has both
  - Updates immediately when saving/unsaving

### 4. ProfileView Updates
Added new "Saved Verses" section that:
- Shows count of saved verses
- Displays empty state when no verses are saved
- Lists up to 5 most recent saved verses with:
  - Heart icon indicator
  - Verse reference (e.g., "John 3:16")
  - Translation badge
  - Full verse text (limited to 3 lines)
  - Relative time (e.g., "2 days ago")
  - Chevron indicator (›) showing they're tappable
- **Tap to Navigate**: Tap any saved verse to jump directly to that verse in BibleView
  - Automatically switches to Bible tab
  - Loads the correct chapter
  - Scrolls to the specific verse
  - Includes haptic feedback
- Context menu to remove verses (long-press)
- "View All" button when more than 5 verses (TODO: implement full list view)

## User Experience Flow

### Saving a Verse
1. **Reading Bible**: User finds a meaningful verse
2. **Save**: Tap verse → Tap "Save verse" → Heart fills ❤️
3. **Confirm**: Heart icon appears next to the verse
4. **View Profile**: Saved verse appears in "Saved Verses" section

### Navigating to a Saved Verse
1. **Open Profile**: Go to Profile tab
2. **See Saved Verses**: Scroll to "Saved Verses" section
3. **Tap Verse**: Tap any saved verse card
4. **Navigate**: Automatically switches to Bible tab and jumps to that verse
5. **Read**: Verse is highlighted and ready to read in context

### Removing a Saved Verse
- **From BibleView**: Tap verse → Tap "Unsave verse"
- **From ProfileView**: Long-press saved verse → "Remove from Saved"

## Database Setup

To enable this feature, run the migration:

```sql
-- In your Supabase SQL Editor, run:
-- /backend/database/migrations/005_add_saved_verses.sql
```

Or use the Supabase CLI:
```bash
supabase db push
```

## Testing Checklist

- [ ] Run database migration
- [ ] Save a verse in BibleView
- [ ] Verify heart icon fills after saving
- [ ] Check ProfileView shows saved verse
- [ ] **Tap saved verse in ProfileView and verify it navigates to BibleView**
- [ ] **Verify the correct verse is scrolled to and highlighted**
- [ ] Unsave from BibleView (should change icon back)
- [ ] Save again and unsave from ProfileView context menu
- [ ] Test with different translations
- [ ] Verify duplicate prevention (can't save same verse twice)
- [ ] Test with 5+ saved verses to see "View All" button
- [ ] Test navigation from ProfileView with verses from different books

## Future Enhancements

1. **Full Saved Verses View**: Dedicated screen showing all saved verses with search/filter
2. **Collections**: Group saved verses into custom collections (themes, topics, etc.)
3. **Share Collection**: Share a collection of verses with friends
4. **Export**: Export saved verses as PDF or text file
5. **Copy Verse**: Quick copy button on saved verse cards in ProfileView
6. **Share Individual Verse**: Share button on saved verse cards

## Files Modified

1. `backend/database/migrations/005_add_saved_verses.sql` (NEW)
2. `faith/faith/UserDataManager.swift`
3. `faith/faith/BibleView.swift`
4. `faith/faith/ProfileView.swift`
