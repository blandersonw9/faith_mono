-- Supabase Function: friend_management
-- Description: Handles friend requests, acceptance, and management
-- Usage: Called from iOS app for social features

-- Function to send friend request
CREATE OR REPLACE FUNCTION send_friend_request(p_addressee_username TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_requester_id UUID;
  v_addressee_id UUID;
  v_result JSON;
BEGIN
  -- Get the current user's ID
  v_requester_id := auth.uid();
  
  -- Check if user is authenticated
  IF v_requester_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not authenticated'
    );
  END IF;
  
  -- Get addressee's user ID
  SELECT id INTO v_addressee_id
  FROM profiles
  WHERE username = p_addressee_username;
  
  -- Check if addressee exists
  IF v_addressee_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  -- Check if trying to friend yourself
  IF v_requester_id = v_addressee_id THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Cannot send friend request to yourself'
    );
  END IF;
  
  -- Check if friendship already exists
  IF EXISTS (
    SELECT 1 FROM friendships 
    WHERE (requester_id = v_requester_id AND addressee_id = v_addressee_id)
    OR (requester_id = v_addressee_id AND addressee_id = v_requester_id)
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Friendship already exists or pending'
    );
  END IF;
  
  -- Create friend request
  INSERT INTO friendships (requester_id, addressee_id, status)
  VALUES (v_requester_id, v_addressee_id, 'pending');
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'message', 'Friend request sent successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Function to accept friend request
CREATE OR REPLACE FUNCTION accept_friend_request(p_requester_username TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_addressee_id UUID;
  v_requester_id UUID;
  v_result JSON;
BEGIN
  -- Get the current user's ID
  v_addressee_id := auth.uid();
  
  -- Check if user is authenticated
  IF v_addressee_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not authenticated'
    );
  END IF;
  
  -- Get requester's user ID
  SELECT id INTO v_requester_id
  FROM profiles
  WHERE username = p_requester_username;
  
  -- Check if requester exists
  IF v_requester_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  -- Update friendship status
  UPDATE friendships
  SET status = 'accepted'
  WHERE requester_id = v_requester_id 
  AND addressee_id = v_addressee_id 
  AND status = 'pending';
  
  -- Check if update was successful
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'No pending friend request found'
    );
  END IF;
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'message', 'Friend request accepted successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

-- Function to get friend requests
CREATE OR REPLACE FUNCTION get_friend_requests()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
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
  
  -- Get pending friend requests
  SELECT json_agg(
    json_build_object(
      'requester_username', p.username,
      'requester_display_name', p.display_name,
      'created_at', f.created_at
    )
  ) INTO v_result
  FROM friendships f
  JOIN profiles p ON f.requester_id = p.id
  WHERE f.addressee_id = v_user_id 
  AND f.status = 'pending';
  
  -- Return success response
  RETURN json_build_object(
    'success', true,
    'friend_requests', COALESCE(v_result, '[]'::json)
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;
