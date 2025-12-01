# Logo Setup Instructions

## Logo File Location

Place your PNG logo file (`logo.png`) in the following locations:

### Mobile App (Flutter)
- **Path:** `flutter_attendance/mobile_app/assets/images/logo.png`

### Supervisor App (Flutter)
- **Path:** `supervisor_app/assets/images/logo.png`

### Admin Portal (Next.js)
- **Path:** `admin-portal/public/images/logo.png`

## After Adding the Logo

### For Flutter Apps:
1. Run `flutter pub get` in both mobile app and supervisor app directories
2. Restart the app

### For Admin Portal:
1. The logo will be automatically available at `/images/logo.png`
2. Restart the Next.js dev server if running

## Logo Specifications

The logo should be:
- Format: PNG
- Recommended size: At least 512x512 pixels for best quality
- Transparent background (optional but recommended)

