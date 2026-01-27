# Setup Instructions for "Ghar jesa khana"

To create the new tenant "Ghar jesa khana" and its admin user, please run the provided Dart script.
This script ensures that the Firestore Tenant document and the Firebase Auth User are created correctly and linked, preventing data leakage and login issues.

## Prerequisites
- You must have the Flutter environment set up.
- You must have the Firebase Emulator running OR have valid credentials in your environment.

## Logic Overview
The script (`lib/create_ghar_jesa_khana.dart`) performs the following:
1.  **Creates Tenant Document**: `tenants/ghar-jesa-khana` with all mandatory fields (`name`, `slug`, `plan`, `settings`, etc.).
2.  **Creates Auth User**: Creates `ghajesakhana@scanserve.com` in Firebase Auth.
    - *Note:* If the user already exists, it attempts to log in to retrieve the UID.
3.  **Creates User Document**: `users/{uid}`.
    - **Crucial Step**: It sets `tenantId: 'ghar-jesa-khana'` on the user document.
    - This ensures that when the admin logs in, the `AdminAuthProvider` correctly scopes their session to this tenant, preventing data leakage.
4.  **Creates Initial Category**: Adds a "Starters" category to ensure the Menu Management screen does not crash on first load.

## How to Run

Open your terminal in the project root (`d:\ScanServe`) and run:

```bash
flutter run -d windows -t lib/create_ghar_jesa_khana.dart
```

*Note: The script will print logs to the console. Look for "🎉 SUCCESS!". You can close the app window after you see the success message.*

## Admin Credentials
- **Email**: `ghajesakhana@scanserve.com`
- **Password**: `password123`
