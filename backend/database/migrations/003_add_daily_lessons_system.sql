-- Migration: 003_add_daily_lessons_system.sql
-- Description: Add daily lessons and slides system for interactive daily practice
-- Created: 2024-01-01
-- Author: Faith App Team

-- =============================================
-- ENUMS
-- =============================================
-- Create slide type enum
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
-- Daily lessons indexes
CREATE INDEX idx_daily_lessons_date ON daily_lessons(lesson_date);
CREATE INDEX idx_daily_lessons_theme ON daily_lessons(theme);

-- Lesson slides indexes
CREATE INDEX idx_lesson_slides_lesson_id ON lesson_slides(lesson_id);
CREATE INDEX idx_lesson_slides_type ON lesson_slides(slide_type);
CREATE INDEX idx_lesson_slides_lesson_type ON lesson_slides(lesson_id, slide_type);
CREATE INDEX idx_lesson_slides_slide_index ON lesson_slides(lesson_id, slide_index);

-- User progress indexes
CREATE INDEX idx_user_lesson_progress_user_id ON user_lesson_progress(user_id);
CREATE INDEX idx_user_lesson_progress_lesson_id ON user_lesson_progress(lesson_id);
CREATE INDEX idx_user_lesson_progress_completed ON user_lesson_progress(is_completed);

-- =============================================
-- TRIGGERS
-- =============================================
-- Auto-update timestamps
CREATE TRIGGER update_daily_lessons_updated_at BEFORE UPDATE ON daily_lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lesson_slides_updated_at BEFORE UPDATE ON lesson_slides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_lesson_progress_updated_at BEFORE UPDATE ON user_lesson_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS on all new tables
ALTER TABLE daily_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_slides ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES
-- =============================================

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

-- Admin policies for lesson management (optional - for future admin interface)
-- CREATE POLICY "Admins can manage daily lessons" ON daily_lessons
--     FOR ALL USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- CREATE POLICY "Admins can manage lesson slides" ON lesson_slides
--     FOR ALL USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- =============================================
-- SAMPLE DATA
-- =============================================
-- Insert sample daily lesson for testing
INSERT INTO daily_lessons (lesson_date, title, theme, description, estimated_duration_minutes) VALUES
('2024-01-01', 'New Beginnings', 'Hope', 'Start the new year with hope and faith in God''s plans for your future.', 8),
('2024-01-02', 'Trust in the Lord', 'Faith', 'Learn to trust God completely in all areas of your life.', 6),
('2024-01-03', 'Love Never Fails', 'Love', 'Discover the power of God''s unconditional love in your daily life.', 7);

-- Insert sample slides for the first lesson
INSERT INTO lesson_slides (lesson_id, slide_type, slide_index, type_index, subtitle, main_text, verse_reference, verse_text, background_color) VALUES
-- Scripture slides
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-01'), 'scripture', 0, 0, 'Today''s Scripture', 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, to give you hope and a future.', 'Jeremiah 29:11', 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, to give you hope and a future.', '#4A90E2'),

-- Devotional slides  
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-01'), 'devotional', 1, 0, 'Reflection', 'As we begin this new year, remember that God has a purpose for your life. Even when the path ahead seems uncertain, His plans are always for your good. Take a moment to reflect on the areas where you need to trust God more deeply.', NULL, NULL, '#F5A623'),

-- Prayer slides
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-01'), 'prayer', 2, 0, 'Prayer Focus', 'Heavenly Father, thank You for this new beginning. Help me to trust in Your perfect plans for my life. Give me the courage to step forward in faith, knowing that You are with me every step of the way. Amen.', NULL, NULL, '#7ED321');

-- Insert sample slides for the second lesson
INSERT INTO lesson_slides (lesson_id, slide_type, slide_index, type_index, subtitle, main_text, verse_reference, verse_text, background_color) VALUES
-- Scripture slides
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-02'), 'scripture', 0, 0, 'Today''s Scripture', 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.', 'Proverbs 3:5-6', 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.', '#4A90E2'),

-- Devotional slides
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-02'), 'devotional', 1, 0, 'Reflection', 'Trusting God means surrendering our need to control every outcome. It''s about believing that His wisdom surpasses our understanding and that His ways are higher than ours.', NULL, NULL, '#F5A623'),

-- Prayer slides
((SELECT id FROM daily_lessons WHERE lesson_date = '2024-01-02'), 'prayer', 2, 0, 'Prayer Focus', 'Lord, I surrender my plans to You. Help me to trust Your timing and Your ways. When I don''t understand, give me the faith to follow Your lead. Amen.', NULL, NULL, '#7ED321');

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Function to get today's lesson with slides
CREATE OR REPLACE FUNCTION get_todays_lesson()
RETURNS TABLE (
    lesson_id UUID,
    lesson_date DATE,
    title TEXT,
    theme TEXT,
    description TEXT,
    estimated_duration_minutes INTEGER,
    slides JSON
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dl.id,
        dl.lesson_date,
        dl.title,
        dl.theme,
        dl.description,
        dl.estimated_duration_minutes,
        (
            SELECT json_agg(
                json_build_object(
                    'id', ls.id,
                    'slide_type', ls.slide_type,
                    'slide_index', ls.slide_index,
                    'type_index', ls.type_index,
                    'subtitle', ls.subtitle,
                    'main_text', ls.main_text,
                    'verse_reference', ls.verse_reference,
                    'verse_text', ls.verse_text,
                    'audio_url', ls.audio_url,
                    'image_url', ls.image_url,
                    'background_color', ls.background_color
                ) ORDER BY ls.slide_index
            )
            FROM lesson_slides ls
            WHERE ls.lesson_id = dl.id
        ) as slides
    FROM daily_lessons dl
    WHERE dl.lesson_date = CURRENT_DATE
    LIMIT 1;
END;
$$;

-- Function to update user progress
CREATE OR REPLACE FUNCTION update_lesson_progress(
    p_lesson_id UUID,
    p_slide_index INTEGER,
    p_is_completed BOOLEAN DEFAULT FALSE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    -- Update or insert progress
    INSERT INTO user_lesson_progress (
        user_id, lesson_id, current_slide_index, completed_slides, is_completed, completed_at
    ) VALUES (
        v_user_id, p_lesson_id, p_slide_index, ARRAY[p_slide_index], p_is_completed,
        CASE WHEN p_is_completed THEN NOW() ELSE NULL END
    )
    ON CONFLICT (user_id, lesson_id)
    DO UPDATE SET
        current_slide_index = GREATEST(user_lesson_progress.current_slide_index, p_slide_index),
        completed_slides = CASE 
            WHEN p_slide_index = ANY(user_lesson_progress.completed_slides) THEN user_lesson_progress.completed_slides
            ELSE user_lesson_progress.completed_slides || ARRAY[p_slide_index]
        END,
        is_completed = p_is_completed,
        completed_at = CASE WHEN p_is_completed THEN NOW() ELSE user_lesson_progress.completed_at END,
        updated_at = NOW();
    
    RETURN json_build_object('success', true, 'message', 'Progress updated');
END;
$$;
