# Force Update System - Setup Instructions

## Firestore Configuration

Create a document in Firestore at: `app_config/android`

**Document fields:**
```json
{
  "minRequiredVersion": "1.0.2",
  "latestVersion": "1.0.3",
  "forceUpdateEnabled": true,
  "updateMessage": "A new version with important security fixes is available.",
  "storeUrl": "https://play.google.com/store/apps/details?id=io.bookbed.app"
}
```

**Field descriptions:**
- `minRequiredVersion` (string, required): Minimum app version required. Users below this version will be **forced** to update.
- `latestVersion` (string, required): Latest available version. Users below this version will see **optional** update dialog.
- `forceUpdateEnabled` (boolean, optional, default: true): Global toggle for force updates.
- `updateMessage` (string, optional): Custom message to display in update dialog. If null, uses default localized message.
- `storeUrl` (string, optional): Custom Play Store URL. If null, uses default BookBed app URL.

## Usage Scenarios

### 1. Force Update for Critical Bug Fix
```json
{
  "minRequiredVersion": "1.0.3",
  "latestVersion": "1.0.3",
  "forceUpdateEnabled": true,
  "updateMessage": "Critical security update required. Please update immediately."
}
```
→ All users below 1.0.3 will be **blocked** from using the app until they update.

### 2. Optional Update for Improvements
```json
{
  "minRequiredVersion": "1.0.0",
  "latestVersion": "1.0.4",
  "forceUpdateEnabled": true
}
```
→ Users on 1.0.0+ can continue using the app, but will see "Update Available" dialog (dismissible, reminds every 24h).

### 3. Disable Force Updates Temporarily
```json
{
  "minRequiredVersion": "1.0.0",
  "latestVersion": "1.0.4",
  "forceUpdateEnabled": false
}
```
→ No force updates, but optional update dialog still shows if user is below `latestVersion`.

## Testing

1. **Local Testing**:
   - Update Firestore document with test values
   - Set `minRequiredVersion` > current app version
   - Open app → should see force update dialog

2. **Optional Update Testing**:
   - Set `minRequiredVersion` < current version
   - Set `latestVersion` > current version
   - Open app → should see optional update dialog
   - Dismiss → should not show again for 24h

3. **Firestore Rules Testing**:
   - Try to write to `app_config/android` from app → should fail (permission-denied)
   - Read from app → should succeed

## Version Format

Use semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `1.0.2`)

Version comparison logic:
- `1.0.2` < `1.0.3` → true
- `1.0.2` < `1.1.0` → true
- `1.0.2` < `2.0.0` → true
- `1.0.2` < `1.0.2` → false (equal)

## Security Rules

```javascript
// firestore.rules
match /app_config/{platform} {
  allow read: if isAuthenticated(); // Any authenticated user can check version
  allow write: if false; // Only Cloud Functions via Admin SDK
}
```

## Monitoring

Version check logs are sent to:
- **Cloud Logging** (all checks)
- **Sentry** (if errors occur during version check)

Log format:
```
VersionCheck: current=1.0.2, min=1.0.0, latest=1.0.3, status=optionalUpdate
```

## Future Enhancements (TODO)

- [ ] iOS support (create `app_config/ios` document)
- [ ] A/B testing for optional update message
- [ ] Scheduled force updates (enable at specific date/time)
- [ ] In-app changelog viewer
