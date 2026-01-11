# Firestore Security Rules Audit (ZADATAK 7)

## 7.1 Compliance Checklist

| Requirement | Status | Verdict | Notes |
| :--- | :---: | :--- | :--- |
| **User reads/writes OWN document in `/users/{userId}`** | ✅ | **COMPLIANT** | Controlled by `isOwner(userId)` helper. |
| **User reads/writes OWN properties** | ✅ | **COMPLIANT** | Controlled by `isResourceOwner()` and `isPropertyOwner()`. |
| **User reads/writes OWN bookings** | ✅ | **COMPLIANT** | Owners can read via `owner_id` check. |
| **User reads SOMEONE ELSE'S user document** | ❌ | **COMPLIANT** | Blocked. Only `isOwner` or `isAdmin` can read. |
| **Unauthenticated user accesses `/users` collection** | ❌ | **COMPLIANT** | Blocked. `isAuthenticated()` is prerequisite. |
| **Rate limit documents (`loginAttempts`) readable by everyone** | ❌ | **COMPLIANT** | Blocked. `allow read: if false`. |

## 7.2 Dev vs Production Rules

*   **Rule Consistency:** ✅ **CONFIRMED**.
    *   The project uses a single `firestore.rules` file for all environments (`bookbed-dev`, `bookbed-staging`, etc.), as defined in `firebase.json`.
    *   There is no divergence in security logic between environments.

*   **Permission Denied Errors (`[cloud_firestore/permission-denied]`) Analysis:**
    *   **Potential Cause 1: Strict User Update Rules.**
        *   The rule `allow write: if ... !request.resource.data.keys().hasAny(['accountStatus', ...])` strictly forbids specific fields.
        *   *Findings:* The client-side models (`UserProfile`, `CompanyDetails`) correctly exclude these fields in `toFirestore()`. The manual update in `EditProfileScreen` also only sends safe fields. This is likely safe, but any future code that blindly sends a full user object will fail here.
    *   **Potential Cause 2: Collection Group Query Mismatches.**
        *   Queries on `bookings` must strictly adhere to the allowed conditions.
        *   If a user queries for bookings without filtering by `owner_id` (relying on implicit "I am owner"), the query might fail if it hits the "public widget" path but doesn't match the specific fields required for public access.
        *   *Action:* Ensure all owner-facing queries include `.where('owner_id', isEqualTo: user.uid)`.
    *   **Potential Cause 3: Invalid `property_id` on Creation.**
        *   When creating a `unit` or `booking`, the rules perform a `get()` on the parent property. If the property does not exist or the ID is invalid, the `get()` fails, resulting in a permission denied error.

## 🛡️ Sentinel Security Observations (Additional Findings)

### CRITICAL: PII Exposure in Bookings
*   **Vulnerability:** The rule for bookings allows public read access if the document contains `unit_id` and `status` fields:
    ```javascript
    ('unit_id' in resource.data && 'status' in resource.data)
    ```
    Since almost all booking documents contain these fields, **any authenticated or unauthenticated user can read any booking document** (including PII like guest name, email, phone) if they can guess the ID or list the collection.
*   **Recommendation:** This architectural vulnerability requires immediate attention (as noted in internal documentation). PII should be moved to a private subcollection (e.g., `/bookings/{id}/pii/sensitive`) that is strictly locked to the owner, while the main booking document remains public for availability only.

### `isResourceOwner` strictness
*   The `isResourceOwner` helper relies on `resource.data.owner_id`. If legacy documents exist without this field, they become unmodifiable. This is a secure "fail-closed" state but may confuse users if they encounter old data.

### `ical_feeds` Resource Check
*   The rule `match /ical_feeds/{feedId}` uses `resource == null` in a read rule.
    ```javascript
    allow read: if isAuthenticated() && (resource == null || ...)
    ```
    This pattern is unusual for `read` operations (typically `resource` is populated). While it might be intended to allow "checking for existence", it should be reviewed to ensure it doesn't leak information about non-existent IDs.
