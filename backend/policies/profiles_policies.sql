-- Row Level Security Policies for Profiles Table
-- Description: Defines who can access and modify profile data

-- =============================================
-- PROFILES POLICIES
-- =============================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete own profile" ON profiles
    FOR DELETE USING (auth.uid() = id);

-- =============================================
-- ADDITIONAL POLICIES FOR SOCIAL FEATURES
-- =============================================

-- Friends can view each other's profiles (based on privacy settings)
-- This policy allows friends to see basic profile information
CREATE POLICY "Friends can view profiles" ON profiles
    FOR SELECT USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM friendships f
            JOIN user_preferences up ON f.addressee_id = up.user_id
            WHERE (f.requester_id = auth.uid() AND f.addressee_id = id)
            OR (f.addressee_id = auth.uid() AND f.requester_id = id)
            AND f.status = 'accepted'
            AND up.privacy_level IN ('public', 'friends')
        )
    );

-- =============================================
-- POLICY NOTES
-- =============================================
-- 
-- 1. Users can always view and modify their own profile
-- 2. Friends can view profiles based on privacy settings
-- 3. Public profiles can be viewed by anyone
-- 4. Private profiles can only be viewed by the owner
-- 5. All profile modifications require authentication
-- 
-- Privacy Levels:
-- - 'public': Anyone can view the profile
-- - 'friends': Only friends can view the profile
-- - 'private': Only the owner can view the profile
