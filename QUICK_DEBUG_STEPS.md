# ⚡ Quick Debug Steps for Sign Out

## Do This First:

### 1. Hot Restart Flutter App
In the terminal where Flutter is running, press **`R`** (capital R) to fully restart.

### 2. Open Browser Console
Press **F12** → Go to **Console** tab → Clear it

### 3. Try Sign Out Again
Click menu (⋮) → "Sign Out"

---

## What Should Happen:

✅ **Orange snackbar appears** ("🚪 Signing out...")  
✅ **Green snackbar appears** ("✅ Sign out successful...")  
✅ **Console shows lots of debug logs**  
✅ **Screen changes to login page**  

---

## If Nothing Happens:

### The app didn't reload with your changes!

**Fix:**
1. Stop Flutter (Ctrl+C in terminal)
2. Run again:
   ```bash
   cd /Users/pauloborges/dev/flutter_projects/motodocs_web
   flutter run -d chrome
   ```
3. Wait for it to load
4. Try sign out again

---

## Copy Console Logs

After clicking sign out, **copy ALL the console output** and send it to me.

This will show me exactly where it's breaking!

---

## Alternative: Test Sign Out Directly

If the Flutter app isn't reloading, let's test Firebase sign out directly in the browser console:

1. Open Chrome DevTools (F12)
2. Go to **Console** tab
3. Paste this:
   ```javascript
   firebase.auth().signOut().then(() => {
     console.log('✅ Sign out successful');
     console.log('Current user:', firebase.auth().currentUser);
   }).catch((error) => {
     console.error('❌ Sign out error:', error);
   });
   ```
4. Press Enter
5. Tell me what it says

This will tell us if Firebase sign out itself is working!
