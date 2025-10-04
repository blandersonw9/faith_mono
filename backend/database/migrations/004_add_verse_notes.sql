-- Migration to add verse notes functionality
-- Run this migration after 003_add_daily_lessons_system.sql

-- =============================================
-- VERSE NOTES TABLE
-- =============================================
-- Stores user notes on Bible verses
CREATE TABLE verse_notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  note_text TEXT NOT NULL,
  translation TEXT, -- e.g., "NIV", "ESV", "KJV"
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- INDEXES
-- =============================================
-- Add indexes for better query performance
CREATE INDEX idx_verse_notes_user_id ON verse_notes(user_id);
CREATE INDEX idx_verse_notes_verse ON verse_notes(book, chapter, verse);
CREATE INDEX idx_verse_notes_user_verse ON verse_notes(user_id, book, chapter, verse);
CREATE INDEX idx_verse_notes_created ON verse_notes(created_at DESC);

-- =============================================
-- TRIGGERS
-- =============================================
-- Auto-update timestamp
CREATE TRIGGER update_verse_notes_updated_at BEFORE UPDATE ON verse_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on verse_notes table
ALTER TABLE verse_notes ENABLE ROW LEVEL SECURITY;

-- Verse notes policies - Users can only access their own notes
CREATE POLICY "Users can view own verse notes" ON verse_notes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own verse notes" ON verse_notes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own verse notes" ON verse_notes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own verse notes" ON verse_notes
    FOR DELETE USING (auth.uid() = user_id);

