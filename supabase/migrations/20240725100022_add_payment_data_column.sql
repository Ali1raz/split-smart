-- Add payment_data column to group_messages table
-- This column stores payment information when a message is of category 'payment'

-- Add the payment_data column
ALTER TABLE public.group_messages 
ADD COLUMN IF NOT EXISTS payment_data jsonb;

-- Create index for payment_data queries
CREATE INDEX IF NOT EXISTS group_messages_payment_data_idx ON public.group_messages USING GIN (payment_data);

-- Add comment to document the column
COMMENT ON COLUMN public.group_messages.payment_data IS 'JSON data containing payment information when message category is payment';

-- Test the column addition
SELECT 'payment_data column added successfully' as status; 