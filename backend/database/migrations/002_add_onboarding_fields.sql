-- Migration: Add onboarding fields to profiles table
-- Created: 2025-10-01

-- Add growth_goal field to store user's spiritual growth goal from onboarding
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS growth_goal TEXT;

-- Add onboarding_completed_at timestamp
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding_completed ON profiles(onboarding_completed_at);

