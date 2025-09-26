-- Supabase Function: create_profile
-- Description: Creates a new user profile after authentication
-- Usage: Called from iOS app after successful Google/Apple sign-in

CREATE OR REPLACE FUNCTION create_profile(
  p_username TEXT,
  p_display_name TEXT,
  p_profile_picture_url TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_profile_id UUID;
  v_result JSON;
BEGIN
  -- Get the current user's ID
  v_user_id := auth.uid();
  
  -- Check if user is authenticated
  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not authenticated'
    );
  END IF;
  
  -- Check if profile already exists
  IF EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Profile already exists'
    );
  END IF;
  
  -- Check if username is already taken
  IF EXISTS (SELECT 1 FROM profiles WHERE username = p_username) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Username already taken'
    );
  END IF;
  
  -- Create profile
  INSERT INTO profiles (id, username, display_name, profile_picture_url)
  VALUES (v_user_id, p_username, p_display_name, p_profile_picture_url)
  RETURNING id INTO v_profile_id;
  
  -- Create initial user progress record
  INSERT INTO user_progress (user_id, current_streak, longest_streak, total_xp, current_level)
  VALUES (v_user_id, 0, 0, 0, 1);
  
  -- Create default user preferences
  INSERT INTO user_preferences (user_id, daily_reminder_time, notifications_enabled, privacy_level)
  VALUES (v_user_id, '08:00:00', true, 'friends');
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'message', 'Profile created successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;
