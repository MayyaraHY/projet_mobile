# Social Authentication Setup Guide

## Google Sign-In Configuration

### 1. Get SHA-1 Certificate Fingerprint

Run this command in your project directory:

```bash
cd android
./gradlew signingReport
```

Look for the **SHA-1** fingerprint in the output.

### 2. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add an Android app:
   - Package name: `com.example.user`
   - Add your SHA-1 fingerprint
4. Download `google-services.json`
5. Place it in `android/app/` directory

### 3. Update Android Configuration

#### android/build.gradle.kts

Add to dependencies block:

```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

#### android/app/build.gradle.kts

Add at the bottom:

```kotlin
apply(plugin = "com.google.gms.google-services")
```

---

## Facebook Login Configuration

### 1. Facebook Developers Setup

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or select existing
3. Add Facebook Login product
4. Note your **App ID** and **Client Token**

### 2. Update Android Configuration

#### android/app/src/main/AndroidManifest.xml

Add inside `<application>` tag:

```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>

<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token"/>

<activity
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

#### android/app/src/main/res/values/strings.xml

Create or update this file:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">ProjetMobile</string>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
    <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
</resources>
```

### 3. Configure Facebook App Settings

1. In Facebook Developer Console
2. Go to Settings > Basic
3. Add Platform > Android
4. Enter:
   - Package Name: `com.example.user`
   - Class Name: `com.example.user.MainActivity`
   - Key Hashes: Generate using:
   ```bash
   keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
   ```
   (Password is usually: `android`)

---

## Testing

### Test Google Sign-In:

1. Run the app
2. Navigate to login screen
3. Click "Google" button
4. Select your Google account

### Test Facebook Login:

1. Run the app
2. Navigate to login screen
3. Click "Facebook" button
4. Log in with your Facebook account

---

## Troubleshooting

### Google Sign-In Issues:

- Verify SHA-1 is correct in Firebase Console
- Check `google-services.json` is in `android/app/`
- Ensure package name matches in Firebase and AndroidManifest.xml

### Facebook Login Issues:

- Verify App ID and Client Token are correct
- Check Key Hashes in Facebook Developer Console
- Ensure package name matches

### Common Errors:

- **"DEVELOPER_ERROR"**: SHA-1 mismatch or wrong package name
- **"Sign in cancelled"**: User cancelled the sign-in flow
- **Network errors**: Check internet connection
