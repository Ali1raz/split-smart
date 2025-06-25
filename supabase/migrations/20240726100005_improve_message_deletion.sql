-- Improve message deletion system
-- Add deleted_for_users column to track which users have deleted specific messages

-- Add deleted_for_users column to messages table (direct messages)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS deleted_for_users uuid[] DEFAULT '{}';

-- Add deleted_for_users column to group_messages table
ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS deleted_for_users uuid[] DEFAULT '{}';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_deleted_for_users 
ON messages USING GIN(deleted_for_users) 
WHERE array_length(deleted_for_users, 1) > 0;

CREATE INDEX IF NOT EXISTS idx_group_messages_deleted_for_users 
ON group_messages USING GIN(deleted_for_users) 
WHERE array_length(deleted_for_users, 1) > 0;

-- Update the get_user_chats_with_last_message function to handle both deletion types
DROP FUNCTION IF EXISTS get_user_chats_with_last_message(uuid);

CREATE OR REPLACE FUNCTION get_user_chats_with_last_message(current_user_id uuid)
RETURNS TABLE (
    id uuid,
    username text,
    display_name text,
    last_message_content text,
    last_message_created_at timestamp with time zone,
    last_message_sender_id uuid,
    last_message_sender_display_name text
) AS $$
BEGIN
    RETURN QUERY
    WITH last_messages AS (
        SELECT
            CASE
                WHEN sender_id = current_user_id THEN receiver_id
                ELSE sender_id
            END AS other_user_id,
            content,
            created_at,
            sender_id,
            is_deleted,
            deleted_for_users,
            ROW_NUMBER() OVER (
                PARTITION BY
                    CASE
                        WHEN sender_id = current_user_id THEN receiver_id
                        ELSE sender_id
                    END
                ORDER BY created_at DESC
            ) AS rn
        FROM messages
        WHERE (sender_id = current_user_id OR receiver_id = current_user_id)
        AND (
            -- Message is not deleted for current user only
            (deleted_for_users IS NULL OR NOT (current_user_id = ANY(deleted_for_users)))
        )
    )
    SELECT
        p.id,
        p.username,
        p.display_name,
        lm.content AS last_message_content,
        lm.created_at AS last_message_created_at,
        lm.sender_id AS last_message_sender_id,
        sender_profile.display_name AS last_message_sender_display_name
    FROM profiles p
    LEFT JOIN last_messages lm ON p.id = lm.other_user_id AND lm.rn = 1
    LEFT JOIN profiles sender_profile ON lm.sender_id = sender_profile.id
    WHERE p.id != current_user_id
    ORDER BY lm.created_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Add a comment to document the function
COMMENT ON FUNCTION get_user_chats_with_last_message(uuid) IS 'Get all users with their last non-deleted message for chat list display, excluding messages deleted for the current user'; 