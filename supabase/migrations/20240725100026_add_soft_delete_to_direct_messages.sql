-- Add is_deleted column to messages
ALTER TABLE messages
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

-- Allow users to "soft delete" their own messages
CREATE POLICY "Allow sender to soft delete their direct message" ON messages FOR
UPDATE
  USING (auth.uid() = sender_id)
WITH
  CHECK (auth.uid() = sender_id); 