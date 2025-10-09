# Quick Deployment (You Already Have Edge Functions Working!)

Since you already have the `chat` Edge Function deployed with OpenAI API key, deploying `generate-custom-study` is super simple.

## 3 Simple Steps

### 1. Go to Functions Page
https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions

(Same place where your `chat` function lives)

### 2. Create New Function
- Click **"Create a new function"**
- Name: `generate-custom-study`
- Click **"Create function"**

### 3. Paste Code & Deploy
- Copy **ALL** the code from `/Users/jared/faith_mono/backend/supabase/functions/generate-custom-study/index.ts`
- Paste into the editor
- Click **"Deploy"**

## Done! 🎉

The function will automatically use your existing:
- ✅ `OPENAI_API_KEY` (from your `chat` function)
- ✅ `SUPABASE_URL` (auto-injected)
- ✅ `SUPABASE_SERVICE_ROLE_KEY` (auto-injected)

## Test It

**Best way**: Test from your iOS app (handles all UUIDs automatically):
1. Build and run the app
2. Tap "Generate Custom Bible Study"
3. Fill out the 6-step intake
4. Tap "Generate Study"
5. Watch the logs: https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions/generate-custom-study/logs

**Or test in Dashboard** (requires real UUIDs from database):
1. Get user_id: Run `SELECT id FROM auth.users LIMIT 1;` in SQL Editor
2. Create test preference (see DEPLOYMENT.md)
3. Use real UUIDs in the Invoke test

You should see:
```
🎯 Starting study generation...
✅ Fetched preferences
🏷️  Running classifier...
✅ Classification complete
📋 Running planner...
✅ Plan complete
✅ Created study: [uuid]
📚 Generating units and sessions...
✅ Created unit 1: [title]
✅ Created unit 2: [title]
...
🎉 Study generation complete!
```

## Troubleshooting

**If it fails:**

1. Check logs: https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions/generate-custom-study/logs
2. Common issues:
   - Function timeout (>150s): Reduce number of units or use faster model
   - OpenAI rate limit: Wait a bit and try again
   - Database error: Check that migration `006_add_custom_studies.sql` was run

**Function takes too long (~60s)**
- This is normal! Generating 10 units with OpenAI takes 30-60 seconds
- The user will see a loading spinner in the app
- Consider showing a "This may take a minute..." message

## Next: Build the UI (Phase 3)

Now that studies are generating, you need to build the UI to:
- View the generated study
- See all 10 units
- Read each session's content
- Mark sessions as complete
- Track progress

Ready for Phase 3?

