-- Supabase Function: update_progress
-- Description: Updates user progress when completing daily activities
-- Usage: Called from iOS app when user completes prayer, scripture, etc.

CREATE OR REPLACE FUNCTION update_progress(
  p_activity_type TEXT,
  p_xp_earned INTEGER DEFAULT 10,
  p_completion_date DATE DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_today DATE;
  v_existing_completion BOOLEAN;
  v_current_streak INTEGER;
  v_longest_streak INTEGER;
  v_total_xp INTEGER;
  v_current_level INTEGER;
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
  
  -- Use provided date or fall back to server's current date
  v_today := COALESCE(p_completion_date, CURRENT_DATE);
  
  -- Check if user already completed this activity today
  SELECT EXISTS(
    SELECT 1 FROM daily_completions 
    WHERE user_id = v_user_id 
    AND completion_date = v_today 
    AND activity_type = p_activity_type
  ) INTO v_existing_completion;
  
  -- If already completed today, return error
  IF v_existing_completion THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Activity already completed today'
    );
  END IF;
  
  -- Record the completion
  INSERT INTO daily_completions (user_id, completion_date, activity_type, xp_earned)
  VALUES (v_user_id, v_today, p_activity_type, p_xp_earned);
  
  -- Get current progress
  SELECT current_streak, longest_streak, total_xp, current_level
  INTO v_current_streak, v_longest_streak, v_total_xp, v_current_level
  FROM user_progress
  WHERE user_id = v_user_id;
  
  -- Update progress
  v_total_xp := v_total_xp + p_xp_earned;
  v_current_level := (v_total_xp / 100) + 1;
  
  -- Update streak logic
  IF v_current_streak = 0 OR 
     (SELECT last_activity_date FROM user_progress WHERE user_id = v_user_id) = v_today - INTERVAL '1 day' THEN
    v_current_streak := v_current_streak + 1;
  ELSE
    v_current_streak := 1;
  END IF;
  
  -- Update longest streak if necessary
  IF v_current_streak > v_longest_streak THEN
    v_longest_streak := v_current_streak;
  END IF;
  
  -- Update user progress
  UPDATE user_progress
  SET 
    current_streak = v_current_streak,
    longest_streak = v_longest_streak,
    total_xp = v_total_xp,
    current_level = v_current_level,
    last_activity_date = v_today,
    updated_at = NOW()
  WHERE user_id = v_user_id;
  
  -- Return success response with updated progress
  RETURN json_build_object(
    'success', true,
    'current_streak', v_current_streak,
    'longest_streak', v_longest_streak,
    'total_xp', v_total_xp,
    'current_level', v_current_level,
    'xp_earned', p_xp_earned,
    'message', 'Progress updated successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;
