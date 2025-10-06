-- Migration to add saved verses functionality
-- Run this migration after 004_add_verse_notes.sql

-- =============================================
-- SAVED VERSES TABLE
-- =============================================
-- Stores user's favorite/saved verses
CREATE TABLE saved_verses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  book INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  verse_text TEXT NOT NULL, -- Store the verse text at time of saving
  translation TEXT, -- e.g., "NIV", "ESV", "KJV"
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Prevent duplicate saves of the same verse
  UNIQUE(user_id, book, chapter, verse, translation)
);

-- =============================================
-- INDEXES
-- =============================================
-- Add indexes for better query performance
CREATE INDEX idx_saved_verses_user_id ON saved_verses(user_id);
CREATE INDEX idx_saved_verses_verse ON saved_verses(book, chapter, verse);
CREATE INDEX idx_saved_verses_created ON saved_verses(created_at DESC);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on saved_verses table
ALTER TABLE saved_verses ENABLE ROW LEVEL SECURITY;

-- Saved verses policies - Users can only access their own saved verses
CREATE POLICY "Users can view own saved verses" ON saved_verses
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saved verses" ON saved_verses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own saved verses" ON saved_verses
    FOR DELETE USING (auth.uid() = user_id);
