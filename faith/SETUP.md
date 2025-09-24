# Authentication Setup Guide

This app uses **Google Sign-In only** for authentication (Apple Sign-In is ready to be added later).

## 1. Supabase Configuration

### Get your Supabase credentials:
1. Go to your Supabase project dashboard
2. Navigate to Settings > API
3. Copy your:
   - **Project URL** (looks like: `https://your-project.supabase.co`)
   - **anon public** key (starts with `eyJ...`)

### Update Config.swift:
Replace the placeholder values in `Config.swift`:
```swift
static let supabaseURL = "https://your-project.supabase.co"
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## 2. Google Sign-In Setup

### Enable Google Sign-In in Supabase:
1. Go to Authentication > Providers in your Supabase dashboard
2. Enable Google provider
3. Add your Google OAuth credentials:
   - **Client ID**: `845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g.apps.googleusercontent.com`
   - **Client Secret**: (get this from Google Cloud Console)

### Google Cloud Console Setup:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select your project
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add your iOS app's bundle identifier
6. Download the configuration file

## 3. Xcode Project Setup

### Add Dependencies:
You'll need to add these Swift Package Manager dependencies:

1. **Supabase Swift**: `https://github.com/supabase/supabase-swift`
2. **Google Sign-In**: `https://github.com/google/GoogleSignIn-iOS`

### Add to your project:
1. File > Add Package Dependencies
2. Add both URLs above
3. Add to your target

### Configure URL Schemes:
1. Open your project in Xcode
2. Select your target
3. Go to Info tab
4. Add URL Scheme: `REVERSED_CLIENT_ID` (from Google configuration)

### Update Info.plist:
Add Google Sign-In configuration:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 4. Security Best Practices

### For Production:
1. **Never commit API keys** to version control
2. Use environment variables or secure key management
3. Consider using Xcode build configurations for different environments
4. Implement proper error handling and logging

### Environment Variables (Recommended):
Set these in your Xcode scheme or environment:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 5. Testing

### Test Authentication Flow:
1. Build and run the app
2. Test Google Sign-In
3. Verify sign-out functionality
4. Test that Apple Sign-In button is disabled (until configured)

### Debug Configuration:
The app will log configuration status on launch. Check the console for:
- ✅ Configuration Valid
- ❌ Missing configuration

## 6. Troubleshooting

### Common Issues:
1. **"Configuration not valid"** - Check your Supabase URL and key
2. **Google Sign-In not working** - Verify URL schemes and bundle ID
3. **Network errors** - Check internet connection and Supabase project status

### Debug Steps:
1. Check Xcode console for error messages
2. Verify Supabase project is active
3. Test API endpoints in Supabase dashboard
4. Check Google Cloud Console for OAuth setup

## 6. Apple Sign-In (Future Setup)

When you're ready to add Apple Sign-In:

### Apple Developer Setup:
1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Create an App ID with Sign In with Apple capability
3. Create a Service ID for web authentication
4. Configure domains and redirect URLs

### Supabase Configuration:
1. Add Apple provider in Supabase Authentication settings
2. Use your Service ID and private key

### Code Changes:
1. Enable Apple Sign-In button in `LoginView.swift`
2. Implement `signInWithApple()` method in `AuthManager.swift`
3. Add Sign In with Apple framework to your project

## Next Steps

Once authentication is working:
1. Customize the UI to match your app's design
2. Add user profile management
3. Implement role-based access control
4. Add biometric authentication (Face ID/Touch ID)
5. Set up push notifications for auth events
6. Configure Apple Sign-In when ready
