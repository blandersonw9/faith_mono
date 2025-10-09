# Supabase Edge Functions Deployment Guide

You can deploy Edge Functions using either the **Dashboard (easier)** or the **CLI (more powerful)**.

---

## Option 1: Deploy via Dashboard (Recommended for Quick Start)

**Note**: Since you already have `OPENAI_API_KEY` set up from your `chat` function, you can skip the API key setup!

### Step 1: Create Edge Function (Same as your `chat` function)

1. Go to https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions (same place as your `chat` function)
2. Click **"Create a new function"** 
3. Name: `generate-custom-study`
4. Click **"Create function"**

### Step 2: Copy Function Code

1. In the function editor, paste the entire contents of `/Users/jared/faith_mono/backend/supabase/functions/generate-custom-study/index.ts`
2. Click **"Deploy"** (same process as deploying your `chat` function)

**That's it!** The function will automatically use your existing `OPENAI_API_KEY`.

### Step 3: Test the Function

**Important**: You need **real UUIDs** from your database, not test strings!

#### Get Test UUIDs:
1. Go to SQL Editor: https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/sql/new
2. Run: `SELECT id FROM auth.users LIMIT 1;` to get a user_id
3. Create a test preference:
   ```sql
   INSERT INTO custom_study_preferences (
     user_id, goals, topics, minutes_per_session, 
     translation, reading_level, include_discussion_questions
   ) VALUES (
     'YOUR_USER_ID_HERE',
     ARRAY['Build a daily habit'], 
     ARRAY['Hope', 'Prayer'],
     15, 'NIV', 'conversational', true
   ) RETURNING id;
   ```
4. Use the returned IDs in the test

#### Test in Dashboard:
1. In the function page, click **"Invoke"**
2. In the "Body" section, enter real UUIDs:
   ```json
   {
     "preference_id": "real-preference-uuid-here",
     "user_id": "real-user-uuid-here"
   }
   ```
3. Click **"Run"**

**Or just test from the iOS app** (easier!) - it handles all UUIDs automatically.

### Step 4: Monitor Logs

1. Click the **"Logs"** tab to see real-time execution logs
2. Errors will show up here if something goes wrong

---

## Differences from Your `chat` Function

Your existing `chat` function and the new `generate-custom-study` function are similar:

| Feature | `chat` | `generate-custom-study` |
|---------|--------|------------------------|
| OpenAI API Key | ✅ Uses OPENAI_API_KEY | ✅ Uses OPENAI_API_KEY |
| Authentication | ✅ JWT verification | ✅ JWT verification |
| CORS headers | ✅ Handles OPTIONS | ✅ Handles OPTIONS |
| Rate limiting | ✅ (200/day via RPC) | ❌ (not implemented yet) |
| Model used | gpt-4o-mini | gpt-4o-mini + gpt-4o |
| Database writes | ❌ (read-only) | ✅ (writes studies) |

The main difference: `generate-custom-study` **writes data to your database** (creates studies, units, sessions), while `chat` only reads and returns responses.

---

## Option 2: Deploy via CLI (Advanced)

### Prerequisites

1. **Install Supabase CLI**:
   ```bash
   brew install supabase/tap/supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link to your project**:
   ```bash
   supabase link --project-ref ppkqyfcnwajfzhvnqxec
   ```

### Set Environment Variables (CLI)

Before deploying via CLI, set the required secrets:

```bash
# Set OpenAI API Key
supabase secrets set OPENAI_API_KEY=your_openai_api_key_here

# Verify secrets
supabase secrets list
```

### Deploy the Function (CLI)

Deploy the generate-custom-study Edge Function:

```bash
cd /Users/jared/faith_mono/backend/supabase

# Deploy the function
supabase functions deploy generate-custom-study

# Or deploy with environment file
supabase functions deploy generate-custom-study --no-verify-jwt
```

---

## Testing (Both Methods)

### Test from Dashboard:

1. Go to https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions/generate-custom-study
2. Click **"Invoke"**
3. Enter test payload
4. View response and logs

### Test using curl:

```bash
curl -i --location --request POST \
  'https://ppkqyfcnwajfzhvnqxec.supabase.co/functions/v1/generate-custom-study' \
  --header 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "preference_id": "uuid-here",
    "user_id": "uuid-here"
  }'
```

### View Logs:

**Dashboard**: https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions/generate-custom-study/logs

**CLI**:
```bash
# View function logs in real-time
supabase functions logs generate-custom-study --tail
```

---

## Local Development (CLI Only)

Run the function locally for testing:

```bash
# Start Supabase locally
supabase start

# Serve the function locally
supabase functions serve generate-custom-study --env-file ./supabase/.env.local

# Test locally
curl -i --location --request POST \
  'http://localhost:54321/functions/v1/generate-custom-study' \
  --header 'Authorization: Bearer YOUR_LOCAL_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "preference_id": "uuid-here",
    "user_id": "uuid-here"
  }'
```

## Environment Variables Required

The function needs these environment variables (automatically available in Supabase):
- `SUPABASE_URL` - Auto-injected
- `SUPABASE_SERVICE_ROLE_KEY` - Auto-injected  
- `OPENAI_API_KEY` - Must be set via `supabase secrets set`

---

## Troubleshooting

### Function fails with "OPENAI_API_KEY not configured"

**Dashboard**: 
1. Go to Settings > Vault
2. Verify `OPENAI_API_KEY` exists and has correct value

**CLI**:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

### Check function status:

**Dashboard**: https://supabase.com/dashboard/project/ppkqyfcnwajfzhvnqxec/functions

**CLI**:
```bash
supabase functions list
```

### View detailed logs:

**Dashboard**: Click function → "Logs" tab

**CLI**:
```bash
supabase functions logs generate-custom-study --tail
```

### Redeploy after changes:

**Dashboard**: Edit function code → Click "Deploy"

**CLI**:
```bash
supabase functions deploy generate-custom-study
```

## Cost Estimation

**OpenAI API Usage per study generation:**
- Classifier: ~100 tokens (gpt-4o-mini) = $0.0001
- Planner: ~500 tokens (gpt-4o) = $0.0025
- Unit Builder (10 units × 1-3 sessions): ~10,000 tokens (gpt-4o) = $0.05

**Total per study: ~$0.05 - $0.08**

For 100 users generating studies per month: **~$5-8/month**

## Next Steps

After deployment:
1. Test from the iOS app
2. Monitor logs for errors
3. Adjust token limits if needed
4. Consider adding rate limiting for production

