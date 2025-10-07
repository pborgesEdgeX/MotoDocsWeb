# 🔍 Debug Sign Out - Instructions

## What We Added

Added comprehensive debug logging to trace the entire sign out flow:

### 1. **AuthService** (`lib/services/auth_service.dart`)
- Logs when `signOut()` is called
- Shows current user before/after sign out
- Logs `notifyListeners()` call

### 2. **HomeScreen** (`lib/screens/home_screen.dart`)
- Logs when sign out button is clicked
- Shows SSE cleanup process
- Tracks sign out completion

### 3. **AuthWrapper** (`lib/main.dart`)
- Shows every rebuild with full state
- Displays connection state, data, and flags
- Tracks which screen is being returned

---

## How to Test

### Step 1: Open the Flutter Web App
```bash
# In terminal 1 (this directory):
cd /Users/pauloborges/dev/flutter_projects/motodocs_web
flutter run -d chrome
```

### Step 2: Open Browser Console
1. Open Chrome DevTools (F12 or Cmd+Option+I)
2. Go to the "Console" tab
3. Clear the console (trash icon or Cmd+K)

### Step 3: Sign In
1. Sign in with your test credentials
2. Watch the console - you should see:
   ```
   ════════════════════════════════════════
   🔄 AuthWrapper rebuild triggered
      ConnectionState: ConnectionState.active
      hasData: true
      data: Instance of 'User'
      _showLoginAnimation: false
      _lastAuthenticatedUserId: null
   ════════════════════════════════════════
   🎬 New user detected, showing login animation
   ➡️  Returning LoginSuccessScreen
   ```

### Step 4: Click Sign Out
1. Click the menu button (⋮) in the top right
2. Click "Sign Out"
3. **WATCH THE CONSOLE CAREFULLY**

### Expected Console Output:
```
════════════════════════════════════════
🚪 SIGN OUT INITIATED
════════════════════════════════════════
✅ Got AuthService
📡 Cancelling SSE subscription...
📡 Disposing SSE service...
✅ SSE cleaned up
🔓 Calling authService.signOut()...
════════════════════════════════════════
🔓 AuthService.signOut() called
   Current user: test@example.com
════════════════════════════════════════
✅ Firebase auth.signOut() completed
   Current user after signOut: null
�� Calling notifyListeners()...
✅ notifyListeners() completed
════════════════════════════════════════
✅ authService.signOut() completed
⏳ Waiting for AuthWrapper StreamBuilder to rebuild...
════════════════════════════════════════
🔄 AuthWrapper rebuild triggered
   ConnectionState: ConnectionState.active
   hasData: false
   hasError: false
   data: null
   _showLoginAnimation: false
   _lastAuthenticatedUserId: null
════════════════════════════════════════
🚪 No authenticated user detected
   Resetting state variables
➡️  Returning AuthScreen (signed out)
```

---

## What to Look For

### ✅ **Sign Out WORKING:**
1. Sign out button is clicked
2. SSE is cleaned up
3. `authService.signOut()` completes
4. `authStateChanges` stream emits null
5. `AuthWrapper` rebuilds with `hasData: false`
6. `AuthScreen` is returned
7. **YOU SEE THE LOGIN SCREEN**

### ❌ **Sign Out NOT WORKING:**
1. Console shows sign out initiated
2. Console shows sign out completed
3. **BUT** `AuthWrapper` doesn't rebuild, OR
4. **OR** `AuthWrapper` rebuilds but still shows `hasData: true`, OR
5. **OR** `AuthWrapper` rebuilds correctly but returns `HomeScreen` instead of `AuthScreen`
6. **YOU'RE STILL ON THE HOME SCREEN**

---

## Common Issues & Solutions

### Issue 1: AuthWrapper Not Rebuilding
**Symptom:** Sign out completes but no AuthWrapper rebuild log
**Cause:** `authStateChanges` stream not emitting
**Solution:** Check if `StreamBuilder` is properly connected

### Issue 2: hasData Still True After Sign Out
**Symptom:** AuthWrapper rebuilds but `hasData: true`, `data: Instance of 'User'`
**Cause:** Firebase not actually signing out
**Solution:** Check Firebase initialization

### Issue 3: AuthWrapper Rebuilds but Returns Wrong Screen
**Symptom:** Logs show `➡️  Returning AuthScreen` but UI doesn't change
**Cause:** Widget tree not updating properly
**Solution:** Check MaterialApp routing

---

## Debugging Steps

### If Sign Out Doesn't Work:

1. **Copy the ENTIRE console output** from clicking sign out
2. Look for:
   - Does sign out initiate? (`🚪 SIGN OUT INITIATED`)
   - Does Firebase sign out complete? (`✅ Firebase auth.signOut() completed`)
   - Does `notifyListeners()` get called? (`📢 Calling notifyListeners()...`)
   - Does `AuthWrapper` rebuild? (`🔄 AuthWrapper rebuild triggered`)
   - What is `hasData` after rebuild? (`hasData: false` is correct)
   - What screen is returned? (`➡️  Returning AuthScreen` is correct)

3. **Share the console logs** so we can see exactly where it's failing

---

## Quick Test Commands

```bash
# Terminal 1: Run Flutter app
cd /Users/pauloborges/dev/flutter_projects/motodocs_web
flutter run -d chrome

# Terminal 2: Watch for errors
cd /Users/pauloborges/dev/flutter_projects/motodocs_web
flutter logs
```

---

## What Happens Next

After you test and share the console logs, we'll know exactly:
- ✅ If sign out is actually working (Firebase side)
- ✅ If the auth state stream is emitting
- ✅ If the UI is updating correctly
- ✅ Where exactly the flow breaks (if it does)

**Then we can fix the specific issue!**
