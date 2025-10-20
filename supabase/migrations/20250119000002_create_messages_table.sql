-- Create messages table for host-guest communication
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id UUID REFERENCES public.properties(id) ON DELETE SET NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unread' CHECK (status IN ('unread', 'read', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    read_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT message_length_check CHECK (char_length(message) >= 10 AND char_length(message) <= 5000),
    CONSTRAINT different_users CHECK (sender_id != receiver_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_property ON public.messages(property_id);
CREATE INDEX IF NOT EXISTS idx_messages_status ON public.messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view messages where they are sender or receiver
CREATE POLICY "Users can view their own messages"
    ON public.messages
    FOR SELECT
    USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );

-- Users can insert messages where they are the sender
CREATE POLICY "Users can send messages"
    ON public.messages
    FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- Users can update messages where they are the receiver (to mark as read)
CREATE POLICY "Users can update received messages"
    ON public.messages
    FOR UPDATE
    USING (auth.uid() = receiver_id)
    WITH CHECK (auth.uid() = receiver_id);

-- Users can delete messages where they are sender or receiver
CREATE POLICY "Users can delete their messages"
    ON public.messages
    FOR DELETE
    USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at on row update
DROP TRIGGER IF EXISTS messages_updated_at_trigger ON public.messages;
CREATE TRIGGER messages_updated_at_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_messages_updated_at();

-- Function to automatically set read_at when status changes to 'read'
CREATE OR REPLACE FUNCTION public.handle_message_read()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'read' AND OLD.status != 'read' THEN
        NEW.read_at = now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to set read_at
DROP TRIGGER IF EXISTS message_read_trigger ON public.messages;
CREATE TRIGGER message_read_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    WHEN (NEW.status IS DISTINCT FROM OLD.status)
    EXECUTE FUNCTION public.handle_message_read();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT USAGE ON SEQUENCE messages_id_seq TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE public.messages IS 'Stores messages between hosts and guests';
COMMENT ON COLUMN public.messages.sender_id IS 'User ID of the message sender';
COMMENT ON COLUMN public.messages.receiver_id IS 'User ID of the message receiver';
COMMENT ON COLUMN public.messages.property_id IS 'Optional property ID related to the message';
COMMENT ON COLUMN public.messages.subject IS 'Message subject/title';
COMMENT ON COLUMN public.messages.message IS 'Message content (10-5000 characters)';
COMMENT ON COLUMN public.messages.status IS 'Message status: unread, read, archived';
COMMENT ON COLUMN public.messages.read_at IS 'Timestamp when message was marked as read';
