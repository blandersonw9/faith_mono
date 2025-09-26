# Faith App Backend Documentation

This folder contains all backend-related files for the Faith app, including database schemas, Supabase functions, and policies.

## Database Structure

### Core Tables

#### `profiles` - User Profile Information
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `user_progress` - Gamification & Progress Tracking
```sql
CREATE TABLE user_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_xp INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  last_activity_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### `daily_completions` - Daily Activity Tracking
```sql
CREATE TABLE daily_completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  completion_date DATE NOT NULL,
  activity_type TEXT NOT NULL, -- 'prayer', 'scripture', 'devotional', 'reflection'
  xp_earned INTEGER DEFAULT 10,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### `friendships` - Social Features
```sql
CREATE TABLE friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID REFERENCES profiles(id),
  addressee_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(requester_id, addressee_id)
);
```

#### `user_preferences` - User Settings
```sql
CREATE TABLE user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  daily_reminder_time TIME,
  notifications_enabled BOOLEAN DEFAULT true,
  privacy_level TEXT DEFAULT 'friends', -- 'public', 'friends', 'private'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## XP & Leveling System

### XP Values by Activity
- **Prayer**: 15 XP
- **Scripture**: 20 XP
- **Devotional**: 25 XP
- **Reflection**: 30 XP

### Level Calculation
- **Level 1**: 0-99 XP
- **Level 2**: 100-199 XP
- **Level 3**: 200-299 XP
- **Formula**: `level = (total_xp / 100) + 1`

## File Structure

```
backend/
├── database/
│   ├── schema.sql              # Complete database schema
│   ├── migrations/             # Database migration files
│   └── seed_data.sql          # Sample data for development
├── functions/
│   ├── create_profile.sql      # Profile creation function
│   ├── update_progress.sql     # Progress tracking function
│   └── friend_management.sql   # Friend system functions
└── policies/
    ├── profiles_policies.sql   # Row Level Security policies
    └── user_progress_policies.sql
```

## Setup Instructions

1. **Create Tables**: Run the schema.sql file in your Supabase SQL editor
2. **Set Up Policies**: Apply the RLS policies for security
3. **Create Functions**: Deploy the Supabase functions for business logic
4. **Configure Storage**: Set up storage buckets for profile pictures

## Security Notes

- All tables use Row Level Security (RLS)
- Users can only access their own data
- Friends can see each other's progress (based on privacy settings)
- Profile pictures are stored in Supabase Storage with proper access controls

## Development Workflow

1. Make changes to schema files
2. Test in Supabase dashboard
3. Create migration files for production
4. Update iOS app models to match schema changes
5. Test integration between app and backend

## Next Steps

- [ ] Create complete schema.sql file
- [ ] Set up RLS policies
- [ ] Create Supabase functions
- [ ] Configure storage buckets
- [ ] Test with iOS app integration
