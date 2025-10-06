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

### Step 5: Supabase Configuration

Enable Apple Sign-In in your Supabase dashboard:

1. Go to Authentication > Providers in your Supabase dashboard
2. Enable the Apple provider
3. Configure the Service ID and other required settings
4. Follow Supabase's Apple Sign-In setup guide: https://supabase.com/docs/guides/auth/social-login/auth-apple

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

