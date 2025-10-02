-- Faith App Database Schema
-- This file contains the complete database structure for the Faith app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- PROFILES TABLE
-- =============================================
-- Extends Supabase auth.users with additional profile information
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- USER PROGRESS TABLE
-- =============================================
-- Tracks user's gamification progress (streaks, XP, levels)
CREATE TABLE user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_xp INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  last_activity_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- DAILY COMPLETIONS TABLE
-- =============================================
-- Records daily activity completions for streak tracking
CREATE TABLE daily_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  completion_date DATE NOT NULL,
  activity_type TEXT NOT NULL, -- 'prayer', 'scripture', 'devotional', 'reflection'
  xp_earned INTEGER DEFAULT 10,
  created_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- FRIENDSHIPS TABLE
-- =============================================
-- Manages friend relationships between users
CREATE TABLE friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID REFERENCES profiles(id),
  addressee_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id)
);

-- =============================================
-- USER PREFERENCES TABLE
-- =============================================
-- Stores user settings and preferences
CREATE TABLE user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  daily_reminder_time TIME,
  notifications_enabled BOOLEAN DEFAULT true,
  privacy_level TEXT DEFAULT 'friends', -- 'public', 'friends', 'private'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- ENUMS
-- =============================================
-- Create slide type enum for daily lessons
CREATE TYPE slide_type_enum AS ENUM ('scripture', 'devotional', 'prayer');

-- =============================================
-- DAILY LESSONS TABLE
-- =============================================
-- Stores daily lesson metadata
CREATE TABLE daily_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_date DATE UNIQUE NOT NULL,
  title TEXT NOT NULL,
  theme TEXT, -- e.g., "Forgiveness", "Hope", "Love"
  description TEXT,
  estimated_duration_minutes INTEGER DEFAULT 5,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- =============================================
-- LESSON SLIDES TABLE
-- =============================================
-- Stores individual slides within each lesson
CREATE TABLE lesson_slides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID REFERENCES daily_lessons(id) ON DELETE CASCADE,
  slide_type slide_type_enum NOT NULL,
  slide_index INTEGER NOT NULL, -- Global position in lesson (0, 1, 2...)
  type_index INTEGER NOT NULL, -- Position within slide type (0, 1, 2...)
  subtitle TEXT,
  main_text TEXT NOT NULL,
  verse_reference TEXT,
  verse_text TEXT,
  audio_url TEXT,
  image_url TEXT,
  background_color TEXT, -- For visual theming (hex color)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Ensure unique slide ordering within lessons
  UNIQUE(lesson_id, slide_index),
  -- Ensure unique type ordering within lessons
  UNIQUE(lesson_id, slide_type, type_index)
);

-- =============================================
-- USER LESSON PROGRESS TABLE
-- =============================================
-- Tracks user progress through daily lessons
CREATE TABLE user_lesson_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES daily_lessons(id) ON DELETE CASCADE,
  current_slide_index INTEGER DEFAULT 0,
  completed_slides INTEGER[] DEFAULT '{}', -- Array of completed slide indices
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP,
  time_spent_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- One progress record per user per lesson
  UNIQUE(user_id, lesson_id)
);

-- =============================================
-- INDEXES
-- =============================================
-- Add indexes for better query performance

-- Profiles indexes
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_display_name ON profiles(display_name);

-- User progress indexes
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_level ON user_progress(current_level);

-- Daily completions indexes
CREATE INDEX idx_daily_completions_user_id ON daily_completions(user_id);
CREATE INDEX idx_daily_completions_date ON daily_completions(completion_date);
CREATE INDEX idx_daily_completions_user_date ON daily_completions(user_id, completion_date);

-- Friendships indexes
CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON friendships(addressee_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- User preferences indexes
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- Daily lessons indexes
CREATE INDEX idx_daily_lessons_date ON daily_lessons(lesson_date);
CREATE INDEX idx_daily_lessons_theme ON daily_lessons(theme);

-- Lesson slides indexes
CREATE INDEX idx_lesson_slides_lesson_id ON lesson_slides(lesson_id);
CREATE INDEX idx_lesson_slides_type ON lesson_slides(slide_type);
CREATE INDEX idx_lesson_slides_lesson_type ON lesson_slides(lesson_id, slide_type);
CREATE INDEX idx_lesson_slides_slide_index ON lesson_slides(lesson_id, slide_index);

-- User lesson progress indexes
CREATE INDEX idx_user_lesson_progress_user_id ON user_lesson_progress(user_id);
CREATE INDEX idx_user_lesson_progress_lesson_id ON user_lesson_progress(lesson_id);
CREATE INDEX idx_user_lesson_progress_completed ON user_lesson_progress(is_completed);

-- =============================================
-- TRIGGERS
-- =============================================
-- Auto-update timestamps

-- Update updated_at timestamp for profiles
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_lessons_updated_at BEFORE UPDATE ON daily_lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lesson_slides_updated_at BEFORE UPDATE ON lesson_slides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_lesson_progress_updated_at BEFORE UPDATE ON user_lesson_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_slides ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES
-- =============================================
-- Users can only access their own data

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- User progress policies
CREATE POLICY "Users can view own progress" ON user_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON user_progress
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily completions policies
CREATE POLICY "Users can view own completions" ON daily_completions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own completions" ON daily_completions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Friendships policies
CREATE POLICY "Users can view own friendships" ON friendships
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can insert own friendships" ON friendships
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update own friendships" ON friendships
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily lessons policies - All authenticated users can read lessons
CREATE POLICY "All users can view daily lessons" ON daily_lessons
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Lesson slides policies - All authenticated users can read slides
CREATE POLICY "All users can view lesson slides" ON lesson_slides
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- User lesson progress policies - Users can only access their own progress
CREATE POLICY "Users can view own lesson progress" ON user_lesson_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own lesson progress" ON user_lesson_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own lesson progress" ON user_lesson_progress
    FOR UPDATE USING (auth.uid() = user_id);
