# Logo Troubleshooting Guide

## Logo Files Status
✅ All logo.png files are in place:
- `flutter_attendance/mobile_app/assets/images/logo.png` (148KB, valid PNG)
- `supervisor_app/assets/images/logo.png` (148KB, valid PNG)
- `admin-portal/public/images/logo.png` (148KB, valid PNG)

## If Logo is Not Showing

### For Flutter Apps (Mobile & Supervisor):

1. **Run flutter pub get:**
   ```bash
   cd flutter_attendance/mobile_app
   flutter pub get
   
   cd ../../supervisor_app
   flutter pub get
   ```

2. **Do a full restart (not hot reload):**
   - Stop the app completely
   - Run `flutter run` again
   - Or use "Restart" button in your IDE (not "Hot Reload")

3. **Clear Flutter build cache:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Verify assets in pubspec.yaml:**
   - Mobile app: `assets: - assets/images/`
   - Supervisor app: `assets: - assets/images/`

### For Admin Portal (Next.js):

1. **Restart the dev server:**
   ```bash
   cd admin-portal
   # Stop the server (Ctrl+C)
   npm run dev
   ```

2. **Verify the image path:**
   - The logo should be accessible at: `http://localhost:3000/images/logo.png`
   - Check browser console for 404 errors

3. **Clear Next.js cache:**
   ```bash
   rm -rf .next
   npm run dev
   ```

## Error Handling
All Flutter apps now have error handling that will show an icon if the image fails to load, which helps identify if the issue is:
- Missing file
- Incorrect path
- Asset not registered

## Image Specifications
- Format: PNG
- Size: 2339 x 3308 pixels
- File size: ~148KB
- Valid PNG files confirmed

