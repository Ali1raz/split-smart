# DATABASE SCHEMA PSEUDO CODE

## TABLES

# Table: balance_transactions

# Purpose: Record all financial movements for users

TABLE balance_transactions:
id: unique_identifier
user_id: foreign_key -> profiles.id
amount: decimal (positive or negative)
transaction_type: enum (ADD_FUNDS, SPEND, LOAN, REPAYMENT)
title_id: foreign_key -> default_balance_titles.id (optional)
description: text (optional)
balance_before: decimal
balance_after: decimal
created_at: timestamp

    PRIMARY KEY: id
    INDEXES: user_id, created_at

# Table: default_balance_titles

# Purpose: Predefined standardized transaction categories

TABLE default_balance_titles:
id: unique_identifier
title: string (e.g., "Salary", "Groceries", "Rent")
category: enum (INCOME, EXPENSE, OTHER)
is_active: boolean

    PRIMARY KEY: id
    UNIQUE: title

# Table: expenses

# Purpose: Track shared expenses within groups

TABLE expenses:
id: unique_identifier
group_id: foreign_key -> groups.id
total_amount: decimal
description: text
paid_by_user_id: foreign_key -> profiles.id
created_at: timestamp
settled: boolean

    PRIMARY KEY: id
    INDEXES: group_id, paid_by_user_id, created_at

# Table: expense_shares

# Purpose: Split expenses among group members

TABLE expense_shares:
id: unique_identifier
expense_id: foreign_key -> expenses.id
user_id: foreign_key -> profiles.id
share_amount: decimal
has_paid: boolean
paid_at: timestamp (optional)

    PRIMARY KEY: id
    INDEXES: expense_id, user_id
    CONSTRAINT: SUM(share_amount) per expense_id should equal expenses.total_amount

# Table: groups

# Purpose: Define user groups for shared expenses

TABLE groups:
id: unique_identifier
name: string
created_by_user_id: foreign_key -> profiles.id
created_at: timestamp
is_active: boolean

    PRIMARY KEY: id
    INDEXES: created_by_user_id

# Table: group_members

# Purpose: Map users to groups with role assignment

TABLE group_members:
id: unique_identifier
group_id: foreign_key -> groups.id
user_id: foreign_key -> profiles.id
is_admin: boolean
joined_at: timestamp

    PRIMARY KEY: id
    UNIQUE: (group_id, user_id)
    INDEXES: group_id, user_id

# Table: group_messages

# Purpose: Store all group chat messages

TABLE group_messages:
id: unique_identifier
group_id: foreign_key -> groups.id
sender_id: foreign_key -> profiles.id
message_content: text
message_type: enum (CHAT, EXPENSE_NOTIFICATION, PAYMENT_NOTIFICATION)
related_expense_id: foreign_key -> expenses.id (optional)
created_at: timestamp

    PRIMARY KEY: id
    INDEXES: group_id, sender_id, created_at

# Table: group_message_deliveries

# Purpose: Track delivery status of messages to members

TABLE group_message_deliveries:
id: unique_identifier
message_id: foreign_key -> group_messages.id
user_id: foreign_key -> profiles.id
delivery_status: enum (SENT, DELIVERED, READ)
delivered_at: timestamp (optional)

    PRIMARY KEY: id
    UNIQUE: (message_id, user_id)
    INDEXES: message_id, user_id

# Table: group_message_reads

# Purpose: Track when users read specific messages

TABLE group_message_reads:
id: unique_identifier
message_id: foreign_key -> group_messages.id
user_id: foreign_key -> profiles.id
read_at: timestamp

    PRIMARY KEY: id
    UNIQUE: (message_id, user_id)
    INDEXES: message_id, user_id

# Table: invitations

# Purpose: Manage group and direct chat invitations

TABLE invitations:
id: unique_identifier
invitation_type: enum (GROUP, DIRECT_CHAT)
group_id: foreign_key -> groups.id (optional, for group invites)
invited_by_user_id: foreign_key -> profiles.id
invited_user_email: string (or user_id if registered)
invitation_token: unique_string
status: enum (PENDING, ACCEPTED, EXPIRED, DECLINED)
created_at: timestamp
expires_at: timestamp
accepted_at: timestamp (optional)

    PRIMARY KEY: id
    UNIQUE: invitation_token
    INDEXES: invited_user_email, status, invitation_token

# Table: messages

# Purpose: Store direct one-on-one messages

TABLE messages:
id: unique_identifier
sender_id: foreign_key -> profiles.id
receiver_id: foreign_key -> profiles.id
message_content: text
is_read: boolean
read_at: timestamp (optional)
created_at: timestamp

    PRIMARY KEY: id
    INDEXES: sender_id, receiver_id, created_at

# Table: profiles

# Purpose: Public user profile information

TABLE profiles:
id: unique_identifier (same as auth.users.id)
user_id: foreign_key -> auth.users.id
username: string (unique)
display_name: string
avatar_url: string (optional)
created_at: timestamp
updated_at: timestamp

    PRIMARY KEY: id
    UNIQUE: username
    INDEXES: username

# Table: user_balances

# Purpose: Summary of user financial status

TABLE user_balances:
id: unique_identifier
user_id: foreign_key -> profiles.id (unique)
current_balance: decimal
total_added: decimal (cumulative funds added)
total_spent: decimal (cumulative funds spent)
last_updated: timestamp

    PRIMARY KEY: id
    UNIQUE: user_id
    INDEXES: user_id

## VIEWS

# View: group_members_with_profiles

# Purpose: Combine group membership with user profile details

VIEW group_members_with_profiles AS:
SELECT
gm.id,
gm.group_id,
gm.user_id,
gm.is_admin,
gm.joined_at,
p.username,
p.display_name,
p.avatar_url
FROM group_members gm
JOIN profiles p ON gm.user_id = p.id

# View: group_messages_with_profiles

# Purpose: Display group messages with sender profile information

VIEW group_messages_with_profiles AS:
SELECT
gm.id,
gm.group_id,
gm.sender_id,
gm.message_content,
gm.message_type,
gm.related_expense_id,
gm.created_at,
p.username,
p.display_name,
p.avatar_url
FROM group_messages gm
JOIN profiles p ON gm.sender_id = p.id

# View: user_profiles_with_emails

# Purpose: Provide user profiles including email addresses

VIEW user_profiles_with_emails AS:
SELECT
p.id,
p.username,
p.display_name,
p.avatar_url,
p.created_at,
p.updated_at,
u.email
FROM profiles p
JOIN auth.users u ON p.user_id = u.id

## KEY RELATIONSHIPS

RELATIONSHIPS:
profiles.user_id -> auth.users.id (one-to-one)
balance_transactions.user_id -> profiles.id (many-to-one)
balance_transactions.title_id -> default_balance_titles.id (many-to-one)
expenses.group_id -> groups.id (many-to-one)
expenses.paid_by_user_id -> profiles.id (many-to-one)
expense_shares.expense_id -> expenses.id (many-to-one)
expense_shares.user_id -> profiles.id (many-to-one)
groups.created_by_user_id -> profiles.id (many-to-one)
group_members.group_id -> groups.id (many-to-one)
group_members.user_id -> profiles.id (many-to-one)
group_messages.group_id -> groups.id (many-to-one)
group_messages.sender_id -> profiles.id (many-to-one)
group_message_deliveries.message_id -> group_messages.id (many-to-one)
group_message_deliveries.user_id -> profiles.id (many-to-one)
group_message_reads.message_id -> group_messages.id (many-to-one)
group_message_reads.user_id -> profiles.id (many-to-one)
invitations.group_id -> groups.id (many-to-one)
invitations.invited_by_user_id -> profiles.id (many-to-one)
messages.sender_id -> profiles.id (many-to-one)
messages.receiver_id -> profiles.id (many-to-one)
user_balances.user_id -> profiles.id (one-to-one)
