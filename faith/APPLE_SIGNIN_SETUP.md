# Apple Sign-In Setup Guide

## The Error
```
Apple Sign-In error: Error Domain=com.apple.AuthenticationServices.AuthorizationError Code=1000 "(null)"
```

**Error Code 1000** = `ASAuthorizationError.unknown` - This means the app is missing the Sign in with Apple capability.

## Solution: Complete Setup in Xcode

### Step 1: Add Entitlements File to Project

✅ The entitlements file has been created at: `faith/faith.entitlements`

Now you need to add it to your Xcode project:

1. Open `faith.xcodeproj` in Xcode
2. In the Project Navigator, right-click on the `faith` folder
3. Select "Add Files to 'faith'..."
4. Navigate to and select `faith.entitlements`
5. Make sure "Copy items if needed" is **unchecked** (file is already in the right place)
6. Click "Add"

### Step 2: Link Entitlements File in Build Settings

1. Select your project (top-level "faith" item in navigator)
2. Select your target ("faith" under TARGETS)
3. Go to the "Build Settings" tab
4. Search for "Code Signing Entitlements"
5. Double-click the value field for "Code Signing Entitlements"
6. Enter: `faith/faith.entitlements`
7. Press Enter

### Step 3: Enable Sign in with Apple Capability

1. Still in your target settings, go to the "Signing & Capabilities" tab
2. Click the "+ Capability" button
3. Search for and add "Sign in with Apple"
4. It should automatically reference your entitlements file

### Step 4: Apple Developer Portal Configuration

⚠️ **Important**: You need to configure your App ID in the Apple Developer Portal:

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Select "Identifiers" and find your App ID: `com.team.faith`
4. Check the "Sign in with Apple" capability
5. Click "Save"

**Note**: If you haven't created an App ID yet, you'll need to:
- Create a new App ID with bundle identifier: `com.team.faith`
- Enable "Sign in with Apple" capability
- Create a provisioning profile that includes this capability

### Step 5: Apple Developer Portal - Service ID Setup

⚠️ **This is required for Supabase configuration**

#### Create a Service ID:

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" in the sidebar
4. Click the "+" button to create a new identifier
5. Select "Services IDs" → Click "Continue"
6. Fill in the details:
   - **Description**: `Faith Sign In` (or any name you want)
   - **Identifier**: `com.team.faith.signin` (this will be your **Client ID** for Supabase)
   - Click "Continue" → "Register"

#### Configure the Service ID:

1. Click on your newly created Service ID
2. Check "Sign in with Apple"
3. Click "Configure" next to it
4. Set the following:
   - **Primary App ID**: Select `com.team.faith` (your app's bundle ID)
   - **Domains and Subdomains**: Add your Supabase project domain
     - Example: `ppkqyfcnwajfzhvnqxec.supabase.co` (remove the `https://`)
   - **Return URLs**: Add your Supabase callback URL
     - Format: `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
     - Example: `https://ppkqyfcnwajfzhvnqxec.supabase.co/auth/v1/callback`
5. Click "Save" → "Continue" → "Save"

#### Generate a Private Key:

1. Still in "Certificates, Identifiers & Profiles"
2. Click "Keys" in the sidebar
3. Click the "+" button to create a new key
4. Fill in:
   - **Key Name**: `Faith Sign In Key` (or any name)
   - Check "Sign in with Apple"
   - Click "Configure" next to it
   - Select your Primary App ID: `com.team.faith`
   - Click "Save"
5. Click "Continue" → "Register"
6. **IMPORTANT**: Click "Download" to download the `.p8` file
   - ⚠️ You can only download this once! Keep it safe!
   - The file will be named something like `AuthKey_ABC123XYZ.p8`
7. Note the **Key ID** (10 characters, shown after download)

#### Get Your Team ID:

1. In Apple Developer Portal, click your name in the top-right
2. Your **Team ID** is displayed in the upper right
   - It's a 10-character alphanumeric string (e.g., `A1B2C3D4E5`)

### Step 6: Supabase Configuration

Now you have everything needed for Supabase:

1. Go to Authentication > Providers in your Supabase dashboard
2. Enable the Apple provider
3. Fill in the required fields:

   **Client ID (Services ID)**: 
   - Enter: `com.team.faith.signin` (your Service ID from above)
   
   **Secret Key (OAuth)**: 
   - You need to generate this using your `.p8` file
   - Use this format (it's a JWT token):
   ```
   -----BEGIN PRIVATE KEY-----
   [Contents of your .p8 file]
   -----END PRIVATE KEY-----
   ```
   
   **Additional Configuration** (if asked):
   - **Team ID**: Your 10-character Team ID
   - **Key ID**: The 10-character Key ID from your downloaded key
   - **Bundle ID**: `com.team.faith`

4. Click "Save"

#### Generating the Secret Key (JWT):

Supabase needs a JWT signed with your private key. You have two options:

**Option A: Let Supabase generate it (easier)**
- Some Supabase versions have a tool to generate this for you
- You'll need to provide: Team ID, Key ID, Client ID, and paste your `.p8` file contents

**Option B: Generate manually**
- Use a JWT generation tool or script
- The token should be signed with ES256 algorithm
- Include claims: `iss` (Team ID), `aud` (https://appleid.apple.com), `sub` (Client ID/Service ID)

**Recommended**: Use Supabase's built-in tool if available, or follow their specific guide at:
https://supabase.com/docs/guides/auth/social-login/auth-apple

### Step 6: Test Apple Sign-In

After completing all steps:

1. Clean build folder (⌘ + Shift + K)
2. Build and run the app (⌘ + R)
3. Test Apple Sign-In
4. You should see the Apple Sign-In modal appear

## Verification Checklist

✅ Entitlements file created: `faith/faith.entitlements`
☐ Entitlements file added to Xcode project
☐ Build Settings updated with entitlements path
☐ Sign in with Apple capability enabled in Xcode
☐ App ID configured in Apple Developer Portal
☐ Apple provider enabled in Supabase
☐ Apple Sign-In tested and working

## Common Issues

### "No bundle identifier found"
- Make sure your bundle identifier (`com.team.faith`) matches in Xcode and Apple Developer Portal

### "Capability not found"
- Ensure you've added the entitlements file to the project
- Check that the entitlements path is correct in Build Settings

### Still getting error 1000
- Verify all steps above are complete
- Try cleaning the build folder and rebuilding
- Check that your provisioning profile includes Sign in with Apple

### Testing in Simulator
- Apple Sign-In works in the iOS Simulator
- You don't need a physical device to test

## Alternative: Disable Apple Sign-In Button

If you want to temporarily disable Apple Sign-In while testing:

In `LoginView.swift`, you can comment out or conditionally disable the Apple Sign-In button until setup is complete.

## Resources

- [Apple Sign-In Documentation](https://developer.apple.com/documentation/authenticationservices)
- [Supabase Apple Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Code-level implementation is already complete in `AuthManager.swift`]

