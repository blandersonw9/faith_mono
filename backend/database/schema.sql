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

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

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
