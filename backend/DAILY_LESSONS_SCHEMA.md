# Daily Lessons System Schema Documentation

## Overview
The daily lessons system provides interactive, slide-based daily practice content for the Faith app. Each day has a lesson containing multiple slides of different types (Scripture, Devotional, Prayer).

## Database Schema

### Tables

#### 1. `daily_lessons`
Stores metadata for each day's lesson.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `lesson_date` | DATE | Unique date for the lesson |
| `title` | TEXT | Lesson title |
| `theme` | TEXT | Theme (e.g., "Hope", "Love", "Forgiveness") |
| `description` | TEXT | Lesson description |
| `estimated_duration_minutes` | INTEGER | Expected completion time |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

#### 2. `lesson_slides`
Stores individual slides within each lesson.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `lesson_id` | UUID | References daily_lessons.id |
| `slide_type` | slide_type_enum | 'scripture', 'devotional', or 'prayer' |
| `slide_index` | INTEGER | Global position in lesson (0, 1, 2...) |
| `type_index` | INTEGER | Position within slide type (0, 1, 2...) |
| `subtitle` | TEXT | Slide subtitle/header |
| `main_text` | TEXT | Main content text |
| `verse_reference` | TEXT | Bible verse reference (e.g., "John 3:16") |
| `verse_text` | TEXT | Full verse text |
| `audio_url` | TEXT | Optional audio file URL |
| `image_url` | TEXT | Optional image file URL |
| `background_color` | TEXT | Hex color for theming |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

**Constraints:**
- `UNIQUE(lesson_id, slide_index)` - Each slide has unique global position
- `UNIQUE(lesson_id, slide_type, type_index)` - Each slide has unique position within its type

#### 3. `user_lesson_progress`
Tracks user progress through daily lessons.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | References profiles.id |
| `lesson_id` | UUID | References daily_lessons.id |
| `current_slide_index` | INTEGER | Current slide position |
| `completed_slides` | INTEGER[] | Array of completed slide indices |
| `is_completed` | BOOLEAN | Whether lesson is fully completed |
| `completed_at` | TIMESTAMP | Completion timestamp |
| `time_spent_seconds` | INTEGER | Total time spent on lesson |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Last update timestamp |

**Constraints:**
- `UNIQUE(user_id, lesson_id)` - One progress record per user per lesson

### Enums

#### `slide_type_enum`
- `scripture` - Bible verse slides
- `devotional` - Reflection and teaching slides  
- `prayer` - Guided prayer slides

## Slide Types

### Scripture Slides
- **Purpose:** Present Bible verses with context
- **Required Fields:** `verse_text`, `verse_reference`
- **Optional Fields:** `subtitle`, `image_url`, `audio_url`
- **Example:** "Today's Scripture | John 3:16"

### Devotional Slides
- **Purpose:** Reflection and teaching content
- **Required Fields:** `main_text`, `subtitle`
- **Optional Fields:** `verse_reference`, `image_url`
- **Example:** "Reflection | God's Love in Action"

### Prayer Slides
- **Purpose:** Guided prayer and meditation
- **Required Fields:** `main_text`
- **Optional Fields:** `subtitle`, `audio_url`
- **Example:** "Prayer | Gratitude and Surrender"

## Helper Functions

### `get_todays_lesson()`
Returns today's lesson with all slides as JSON.

**Returns:**
- Lesson metadata
- Slides array with all slide data

### `update_lesson_progress(lesson_id, slide_index, is_completed)`
Updates user progress for a specific lesson.

**Parameters:**
- `p_lesson_id` - UUID of the lesson
- `p_slide_index` - Current slide index
- `p_is_completed` - Whether lesson is completed

## Security (RLS Policies)

### Daily Lessons
- All authenticated users can read lessons
- Admin-only for insert/update (future admin interface)

### Lesson Slides  
- All authenticated users can read slides
- Admin-only for insert/update

### User Progress
- Users can only access their own progress records
- Users can insert/update their own progress

## Sample Data

The migration includes sample lessons for testing:
- 2024-01-01: "New Beginnings" (Hope theme)
- 2024-01-02: "Trust in the Lord" (Faith theme)

Each lesson includes Scripture, Devotional, and Prayer slides.

## Usage Examples

### Get Today's Lesson
```sql
SELECT * FROM get_todays_lesson();
```

### Update User Progress
```sql
SELECT update_lesson_progress(
    'lesson-uuid-here'::UUID,
    2,
    false
);
```

### Get User's Completed Lessons
```sql
SELECT dl.*, ulp.completed_at
FROM daily_lessons dl
JOIN user_lesson_progress ulp ON dl.id = ulp.lesson_id
WHERE ulp.user_id = auth.uid()
AND ulp.is_completed = true
ORDER BY dl.lesson_date DESC;
```

## Migration File
- `003_add_daily_lessons_system.sql` - Complete migration with tables, indexes, policies, and sample data
