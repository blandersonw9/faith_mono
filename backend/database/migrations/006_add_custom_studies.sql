-- Migration: Add Custom Bible Study System
-- This migration adds tables for user-generated custom Bible studies

-- =============================================
-- CUSTOM STUDY PREFERENCES TABLE
-- =============================================
-- Stores user preferences for custom Bible study generation
CREATE TABLE custom_study_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  goals TEXT[] NOT NULL, -- Array of goal strings
  topics TEXT[] NOT NULL, -- Array of topic strings
  minutes_per_session INTEGER NOT NULL DEFAULT 15,
  translation TEXT NOT NULL DEFAULT 'NIV', -- KJV, NIV, ESV, NLT, CSB
  reading_level TEXT NOT NULL DEFAULT 'conversational', -- simple, conversational, scholarly
  include_discussion_questions BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- CUSTOM STUDIES TABLE
-- =============================================
-- Stores generated custom Bible studies
CREATE TABLE custom_studies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  preference_id UUID REFERENCES custom_study_preferences(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  total_units INTEGER NOT NULL DEFAULT 10,
  completed_units INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- CUSTOM STUDY UNITS TABLE
-- =============================================
-- Stores individual units within a custom study (10 units per study)
CREATE TABLE custom_study_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_id UUID REFERENCES custom_studies(id) ON DELETE CASCADE,
  unit_index INTEGER NOT NULL, -- 0-9 for 10 units
  unit_type TEXT NOT NULL, -- 'devotional', 'inductive', 'character', 'theme', 'word-study'
  scope TEXT NOT NULL, -- 'single-day', 'deep-dive-2days', 'deep-dive-3days'
  title TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL,
  primary_passages TEXT[] NOT NULL, -- Array of verse references
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Ensure unique unit ordering within studies
  UNIQUE(study_id, unit_index)
);

-- =============================================
-- CUSTOM STUDY SESSIONS TABLE
-- =============================================
-- Stores individual sessions within a unit (1-3 sessions per unit)
CREATE TABLE custom_study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID REFERENCES custom_study_units(id) ON DELETE CASCADE,
  session_index INTEGER NOT NULL, -- 0-2 for up to 3 sessions
  title TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL,
  passages TEXT[] NOT NULL, -- Array of verse references
  context TEXT, -- Historical/canonical context (≤100 words)
  key_insights TEXT[] NOT NULL, -- Array of 2-3 key insights
  reflection_questions TEXT[] NOT NULL, -- Array of 3-6 questions
  prayer_prompt TEXT NOT NULL,
  action_step TEXT NOT NULL,
  memory_verse TEXT, -- Single verse reference
  cross_references TEXT[], -- Array of related verse references
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Ensure unique session ordering within units
  UNIQUE(unit_id, session_index)
);

-- =============================================
-- INDEXES
-- =============================================
-- Add indexes for better query performance

-- Custom study preferences indexes
CREATE INDEX idx_custom_study_preferences_user_id ON custom_study_preferences(user_id);

-- Custom studies indexes
CREATE INDEX idx_custom_studies_user_id ON custom_studies(user_id);
CREATE INDEX idx_custom_studies_is_active ON custom_studies(is_active);
CREATE INDEX idx_custom_studies_user_active ON custom_studies(user_id, is_active);

-- Custom study units indexes
CREATE INDEX idx_custom_study_units_study_id ON custom_study_units(study_id);
CREATE INDEX idx_custom_study_units_is_completed ON custom_study_units(is_completed);

-- Custom study sessions indexes
CREATE INDEX idx_custom_study_sessions_unit_id ON custom_study_sessions(unit_id);
CREATE INDEX idx_custom_study_sessions_is_completed ON custom_study_sessions(is_completed);

-- =============================================
-- TRIGGERS
-- =============================================
-- Auto-update timestamps

CREATE TRIGGER update_custom_study_preferences_updated_at BEFORE UPDATE ON custom_study_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_studies_updated_at BEFORE UPDATE ON custom_studies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_study_units_updated_at BEFORE UPDATE ON custom_study_units
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_custom_study_sessions_updated_at BEFORE UPDATE ON custom_study_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on all tables
ALTER TABLE custom_study_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_studies ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_study_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_study_sessions ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES
-- =============================================

-- Custom study preferences policies
CREATE POLICY "Users can view own study preferences" ON custom_study_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study preferences" ON custom_study_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study preferences" ON custom_study_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own study preferences" ON custom_study_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- Custom studies policies
CREATE POLICY "Users can view own custom studies" ON custom_studies
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own custom studies" ON custom_studies
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own custom studies" ON custom_studies
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own custom studies" ON custom_studies
    FOR DELETE USING (auth.uid() = user_id);

-- Custom study units policies - Access via parent study ownership
CREATE POLICY "Users can view own custom study units" ON custom_study_units
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM custom_studies
            WHERE custom_studies.id = custom_study_units.study_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own custom study units" ON custom_study_units
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM custom_studies
            WHERE custom_studies.id = study_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own custom study units" ON custom_study_units
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM custom_studies
            WHERE custom_studies.id = custom_study_units.study_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own custom study units" ON custom_study_units
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM custom_studies
            WHERE custom_studies.id = custom_study_units.study_id
            AND custom_studies.user_id = auth.uid()
        )
    );

-- Custom study sessions policies - Access via parent unit/study ownership
CREATE POLICY "Users can view own custom study sessions" ON custom_study_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM custom_study_units
            JOIN custom_studies ON custom_studies.id = custom_study_units.study_id
            WHERE custom_study_units.id = custom_study_sessions.unit_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own custom study sessions" ON custom_study_sessions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM custom_study_units
            JOIN custom_studies ON custom_studies.id = custom_study_units.study_id
            WHERE custom_study_units.id = unit_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own custom study sessions" ON custom_study_sessions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM custom_study_units
            JOIN custom_studies ON custom_studies.id = custom_study_units.study_id
            WHERE custom_study_units.id = custom_study_sessions.unit_id
            AND custom_studies.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own custom study sessions" ON custom_study_sessions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM custom_study_units
            JOIN custom_studies ON custom_studies.id = custom_study_units.study_id
            WHERE custom_study_units.id = custom_study_sessions.unit_id
            AND custom_studies.user_id = auth.uid()
        )
    );

