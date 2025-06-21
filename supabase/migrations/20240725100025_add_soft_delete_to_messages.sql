-- Add is_deleted column to group_messages
ALTER TABLE group_messages
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

-- Allow users to "soft delete" their own messages
CREATE POLICY "Allow sender to soft delete their message" ON group_messages FOR
UPDATE
  USING (auth.uid() = sender_id)
WITH
  CHECK (auth.uid() = sender_id); 