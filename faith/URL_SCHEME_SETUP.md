# Google Sign-In URL Scheme Setup

## The Error
```
Task 10: "Your app is missing support for the following URL schemes: com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g"
```

This means Google Sign-In needs a URL scheme to redirect back to your app after authentication.

## Solution: Add URL Scheme to Xcode

### Step 1: Open Xcode Project
1. Open your `faith.xcodeproj` file in Xcode
2. Select your project (top-level "faith" item in navigator)
3. Select your target ("faith" under TARGETS)

### Step 2: Add URL Scheme
1. Go to the **"Info"** tab
2. Find the **"URL Types"** section
3. Click the **"+"** button to add a new URL Type
4. Fill in these details:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: `com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g`
   - **Role**: `Editor`

### Step 3: Verify Configuration
After adding, your URL Types should look like this:
```
URL Types
├── Item 0
    ├── Identifier: GoogleSignIn
    ├── URL Schemes: com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g
    └── Role: Editor
```

## Alternative: Edit Info.plist Directly

If you prefer to edit the Info.plist directly, add this XML:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g</string>
        </array>
        <key>CFBundleURLRole</key>
        <string>Editor</string>
    </dict>
</array>
```

## How to Find Your URL Scheme

Your URL scheme is based on your Google Client ID:
- **Client ID**: `845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g.apps.googleusercontent.com`
- **URL Scheme**: `com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g`

The format is: `com.googleusercontent.apps.{CLIENT_ID_WITHOUT_DOMAIN}`

## Testing

After adding the URL scheme:
1. Clean and rebuild your project (⌘+Shift+K, then ⌘+B)
2. Run the app
3. Try Google Sign-In - the error should be gone
4. The Google Sign-In flow should work properly

## Troubleshooting

### If you still get the error:
1. Make sure the URL scheme is exactly: `com.googleusercontent.apps.845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g`
2. Check that there are no extra spaces or characters
3. Clean and rebuild your project
4. Make sure you're testing on a device or simulator (not just building)

### If Google Sign-In doesn't work:
1. Verify your Google Client ID in `Config.swift`
2. Check that Google Sign-In is enabled in your Supabase dashboard
3. Make sure your bundle identifier matches what you configured in Google Cloud Console
