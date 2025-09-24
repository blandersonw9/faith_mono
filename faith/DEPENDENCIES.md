# Dependencies Setup

## Required Dependencies

You need to add these Swift Package Manager dependencies to your Xcode project:

### 1. Supabase Swift SDK
- **URL**: `https://github.com/supabase/supabase-swift`
- **Purpose**: Authentication and database integration

### 2. Google Sign-In iOS SDK
- **URL**: `https://github.com/google/GoogleSignIn-iOS`
- **Purpose**: Google authentication

## How to Add Dependencies

### In Xcode:
1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter each URL above and click **Add Package**
4. Select your target and click **Add Package**

### After Adding Dependencies:

1. **Update AuthManager.swift**:
   - Uncomment the import statements at the top:
     ```swift
     import Supabase
     import GoogleSignIn
     ```
   - Remove all the placeholder types (lines 15-78)
   - Uncomment the actual Google Sign-In implementation (lines 132-159)

2. **Add URL Scheme**:
   - Open your project in Xcode
   - Select your target
   - Go to **Info** tab
   - Add URL Scheme with your Google Client ID (reversed)

3. **Update Info.plist**:
   - Add Google Sign-In configuration (see SETUP.md for details)

## Current Status

The app is currently using placeholder implementations that will show:
- "Please add Supabase and GoogleSignIn dependencies to your project" when trying to sign in
- This allows the app to compile and run while you set up the dependencies

## Testing Without Dependencies

You can still:
- ✅ See the login screen
- ✅ Test the UI layout
- ✅ Verify navigation flow
- ✅ See error messages for missing dependencies
- ❌ Actually authenticate users (until dependencies are added)

## Next Steps

1. Add the dependencies using Xcode
2. Follow the instructions above to update the code
3. Configure your Supabase and Google credentials
4. Test the full authentication flow
