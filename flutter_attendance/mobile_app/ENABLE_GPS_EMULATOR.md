# Enable GPS in Android Emulator

## Quick Fix for Android Emulator

The error "Unable to fetch location. Please enable GPS." appears because the Android emulator doesn't have GPS enabled by default.

### Option 1: Enable GPS via Emulator Settings (Recommended)

1. **Open Emulator Extended Controls:**
   - Click the "..." (three dots) button on the emulator toolbar
   - Or press `Ctrl + Shift + A` (Windows/Linux) or `Cmd + Shift + A` (Mac)

2. **Navigate to Location:**
   - Click on "Location" in the left sidebar
   - You'll see a map interface

3. **Set a Location:**
   - **Method A - Use Preset Locations:**
     - Click "Set location" button
     - Choose a preset location (e.g., "Tokyo", "Paris", "New York")
     - Click "Set"
   
   - **Method B - Enter Coordinates:**
     - Click "Set location" button
     - Enter coordinates manually:
       - Latitude: `37.7749` (San Francisco)
       - Longitude: `-122.4194`
     - Click "Set"

4. **Enable Location Services:**
   - Make sure the toggle for location services is ON
   - The location should now be active

5. **Test in App:**
   - Go back to your app
   - Take a photo
   - GPS location should now be captured successfully

### Option 2: Use ADB Command (Alternative)

You can also set location via command line:

```bash
# Set location to San Francisco
adb emu geo fix -122.4194 37.7749

# Or set to any coordinates
adb emu geo fix <longitude> <latitude>
```

### Option 3: Test on Real Device

For the most accurate testing:
1. Connect a real Android device via USB
2. Enable USB debugging
3. Run: `flutter run`
4. Real device GPS will work automatically

## Verify GPS is Working

After enabling GPS:
1. Take a photo in the app
2. You should see "Location Captured" with coordinates
3. No error message should appear

## Troubleshooting

- **Still showing error?** Make sure location services are enabled in Android Settings:
  - Settings → Location → Turn ON
  
- **Emulator doesn't have GPS option?** Update your emulator or use a newer Android system image

- **Want to test without GPS?** The app will show an error but won't hang, which is the expected behavior

