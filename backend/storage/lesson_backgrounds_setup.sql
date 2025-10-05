-- =============================================
-- SUPABASE STORAGE SETUP FOR LESSON BACKGROUNDS
-- =============================================
-- This file sets up the storage bucket for daily lesson background images

-- Create the storage bucket for lesson backgrounds
INSERT INTO storage.buckets (id, name, public)
VALUES ('lesson-backgrounds', 'lesson-backgrounds', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to view images (authenticated or not)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'lesson-backgrounds' );

-- Allow authenticated users to upload images (for admin/content management)
CREATE POLICY "Authenticated users can upload lesson backgrounds"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'lesson-backgrounds' 
    AND auth.role() = 'authenticated'
);

-- Allow authenticated users to update images
CREATE POLICY "Authenticated users can update lesson backgrounds"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'lesson-backgrounds' AND auth.role() = 'authenticated' );

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete lesson backgrounds"
ON storage.objects FOR DELETE
USING ( bucket_id = 'lesson-backgrounds' AND auth.role() = 'authenticated' );

-- =============================================
-- BACKGROUND IMAGES TABLE (Optional - for metadata)
-- =============================================
-- Store metadata about background images for easier management

CREATE TABLE IF NOT EXISTS lesson_background_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  file_name TEXT NOT NULL UNIQUE,
  storage_path TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE lesson_background_images ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read background image metadata
CREATE POLICY "All users can view background images" ON lesson_background_images
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Allow authenticated users to manage backgrounds
CREATE POLICY "Authenticated users can manage backgrounds" ON lesson_background_images
    FOR ALL USING (auth.role() = 'authenticated');

-- Add index for faster queries
CREATE INDEX idx_background_images_active ON lesson_background_images(is_active);
CREATE INDEX idx_background_images_order ON lesson_background_images(display_order);

-- Trigger to update updated_at
CREATE TRIGGER update_lesson_background_images_updated_at BEFORE UPDATE ON lesson_background_images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- HELPER FUNCTION: Get all active background images
-- =============================================
CREATE OR REPLACE FUNCTION get_lesson_backgrounds()
RETURNS TABLE (
    id UUID,
    file_name TEXT,
    storage_path TEXT,
    public_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lbi.id,
        lbi.file_name,
        lbi.storage_path,
        -- Construct the public URL
        CONCAT(
            current_setting('app.settings.supabase_url', true),
            '/storage/v1/object/public/lesson-backgrounds/',
            lbi.storage_path
        ) as public_url
    FROM lesson_background_images lbi
    WHERE lbi.is_active = true
    ORDER BY lbi.display_order, lbi.created_at;
END;
$$;

-- =============================================
-- SAMPLE DATA (Optional - for testing)
-- =============================================
-- After uploading your 25 images, insert their metadata here
-- Example:
-- INSERT INTO lesson_background_images (file_name, storage_path, display_order) VALUES
-- ('background_1.jpg', 'background_1.jpg', 1),
-- ('background_2.jpg', 'background_2.jpg', 2),
-- ...and so on for all 25 images
