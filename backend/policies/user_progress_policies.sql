-- Row Level Security Policies for User Progress Tables
-- Description: Defines who can access and modify user progress data

-- =============================================
-- USER PROGRESS POLICIES
-- =============================================

-- Users can view their own progress
CREATE POLICY "Users can view own progress" ON user_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update own progress" ON user_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own progress
CREATE POLICY "Users can insert own progress" ON user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own progress
CREATE POLICY "Users can delete own progress" ON user_progress
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- DAILY COMPLETIONS POLICIES
-- =============================================

-- Users can view their own completions
CREATE POLICY "Users can view own completions" ON daily_completions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own completions
CREATE POLICY "Users can insert own completions" ON daily_completions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own completions (for corrections)
CREATE POLICY "Users can update own completions" ON daily_completions
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own completions
CREATE POLICY "Users can delete own completions" ON daily_completions
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- USER PREFERENCES POLICIES
-- =============================================

-- Users can view their own preferences
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own preferences" ON user_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- FRIENDSHIPS POLICIES
-- =============================================

-- Users can view their own friendships
CREATE POLICY "Users can view own friendships" ON friendships
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Users can insert their own friendships (as requester)
CREATE POLICY "Users can insert own friendships" ON friendships
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Users can update their own friendships (accept/decline requests)
CREATE POLICY "Users can update own friendships" ON friendships
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Users can delete their own friendships
CREATE POLICY "Users can delete own friendships" ON friendships
    FOR DELETE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- =============================================
-- POLICY NOTES
-- =============================================
-- 
-- 1. All progress data is private to the user
-- 2. Friends cannot directly access each other's progress
-- 3. Progress data is accessed through Supabase functions for leaderboards
-- 4. Users have full control over their own data
-- 5. All operations require authentication
-- 
-- For leaderboards and social features, use the Supabase functions
-- which can aggregate data while respecting privacy settings
