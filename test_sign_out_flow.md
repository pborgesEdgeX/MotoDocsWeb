# 🔍 Sign Out Debug Checklist

## Step 1: Verify Hot Reload
The Flutter web app needs to reload to pick up the code changes.

**Actions:**
1. In the terminal where `flutter run` is running, press **`r`** to hot reload
2. Or press **`R`** to hot restart (full restart)
3. Or stop and restart: `flutter run -d chrome`

---

## Step 2: Open DevTools Console
1. Press **F12** (or Cmd+Option+I on Mac)
2. Go to **"Console"** tab
3. Clear the console (trash icon or Cmd+K)

---

## Step 3: Click Sign Out and Watch Console

**What to look for in the console:**

### Scenario A: NO logs at all
**Means:** The code hasn't reloaded
**Fix:** Hot restart the app (press `R` in terminal)

### Scenario B: Logs show "Building popup menu items"
**Means:** Menu is opening
**Look for:** `🔘 PopupMenu item selected: signout`

### Scenario C: Logs show popup selected but no "SIGN OUT INITIATED"
**Means:** `_signOut()` function isn't being called
**Indicates:** Issue with the menu callback

### Scenario D: Logs show "SIGN OUT INITIATED" but no AuthWrapper rebuild
**Means:** Firebase sign out works but StreamBuilder isn't reacting
**Look for:** `🔄 AuthWrapper rebuild triggered` with `hasData: false`

---

## Step 4: Debug Commands

### Check if sign out snackbars appear:
- **Orange snackbar:** "🚪 Signing out..." (appears immediately)
- **Green snackbar:** "✅ Sign out successful..." (appears after Firebase signout)

### If NO snackbars appear:
- Code hasn't reloaded
- Press `R` in terminal to hot restart

### If snackbars appear but still on home screen:
- AuthWrapper isn't rebuilding
- Check console for `🔄 AuthWrapper rebuild triggered`

---

## Expected Console Output:

```
📋 Building popup menu items
🔘 PopupMenu item selected: signout
🔘 Sign out menu item matched, calling _signOut()
════════════════════════════════════════════════════════════════════════════════
🚪 SIGN OUT INITIATED
════════════════════════════════════════════════════════════════════════════════
✅ Got AuthService
📡 Cancelling SSE subscription...
📡 Disposing SSE service...
✅ SSE cleaned up
🔓 Calling authService.signOut()...
════════════════════════════════════════════════════════════════════════════════
🔓 AuthService.signOut() called
   Current user: your-email@example.com
════════════════════════════════════════════════════════════════════════════════
✅ Firebase auth.signOut() completed
   Current user after signOut: null
📢 Calling notifyListeners()...
✅ notifyListeners() completed
════════════════════════════════════════════════════════════════════════════════
✅ authService.signOut() completed
⏳ Waiting for AuthWrapper StreamBuilder to rebuild...
════════════════════════════════════════════════════════════════════════════════
🔄 AuthWrapper rebuild triggered
   ConnectionState: ConnectionState.active
   hasData: false
   hasError: false
   data: null
   _showLoginAnimation: false
   _lastAuthenticatedUserId: null
════════════════════════════════════════════════════════════════════════════════
🚪 No authenticated user detected
   Resetting state variables
➡️  Returning AuthScreen (signed out)
```

---

## What to Tell Me:

1. **Did you hot reload/restart the Flutter app?** (press `R`)
2. **Do you see ANY logs in the console?**
3. **Do you see the orange/green snackbars?**
4. **Copy and paste the console output here**

This will tell us exactly where the sign out flow is breaking!
