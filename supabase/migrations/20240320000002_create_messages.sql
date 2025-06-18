-- Create messages table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  sender_id uuid references auth.users(id) not null,
  receiver_id uuid references auth.users(id) not null,
  content text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security
alter table public.messages enable row level security;

-- Create policies
create policy "Users can view their own messages"
  on public.messages for select
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Users can insert their own messages"
  on public.messages for insert
  with check (auth.uid() = sender_id);

create policy "Users can update their own messages"
  on public.messages for update
  using (auth.uid() = sender_id);

-- Create indexes for better query performance
create index messages_sender_id_idx on public.messages(sender_id);
create index messages_receiver_id_idx on public.messages(receiver_id);
create index messages_created_at_idx on public.messages(created_at); 