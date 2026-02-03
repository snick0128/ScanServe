# Creating KDS and Captain Users for ghar-jesa-khana

This guide will help you create the Kitchen Display System (KDS) and Captain user accounts for the tenant `ghar-jesa-khana`.

## Prerequisites

1. **Firebase Admin SDK Service Account Key**
   - Download your Firebase service account key from Firebase Console
   - Go to: Project Settings → Service Accounts → Generate New Private Key
   - Save the file as `service-account-key.json` in the root of the ScanServe project

2. **Node.js and npm**
   - Ensure Node.js is installed (version 14 or higher)
   - Install Firebase Admin SDK:
     ```bash
     npm install firebase-admin
     ```

## Running the Script

1. **Navigate to the project root:**
   ```bash
   cd /Users/albertamac/Desktop/ScanServe
   ```

2. **Ensure service account key is in place:**
   ```bash
   ls service-account-key.json
   ```
   If the file doesn't exist, download it from Firebase Console.

3. **Run the user creation script:**
   ```bash
   node scripts/create_kds_users.js
   ```

## Created Users

The script will create two users:

### 1. Kitchen Staff (KDS User)
- **Email:** `kitchen@ghar-jesa-khana.com`
- **Password:** `Kitchen@2026`
- **Role:** `kitchen`
- **Station:** `hot_kitchen` (default)
- **Purpose:** For kitchen display operations and marking items as ready

### 2. Floor Captain
- **Email:** `captain@ghar-jesa-khana.com`
- **Password:** `Captain@2026`
- **Role:** `captain`
- **Purpose:** For floor management, serving orders, and table operations

## Post-Creation Steps

1. **Test Login:**
   - Open the ScanServe admin panel
   - Log in with each account to verify they work
   - Change passwords if needed

2. **Configure Kitchen Station (if needed):**
   - The KDS user is set to `hot_kitchen` by default
   - To change the station, update the user profile in Firestore:
     ```
     users/{uid}/kitchenStationId
     ```
   - Available stations:
     - `hot_kitchen` - Hot Kitchen
     - `cold_kitchen` - Cold Kitchen
     - `bar` - Bar Station
     - `pass_expo` - Pass/Expo (shows all orders)

3. **Verify Permissions:**
   - KDS user should be able to:
     - View orders in the Kitchen Display
     - Mark items as preparing/ready
     - Print KOT tickets
   - Captain user should be able to:
     - View all orders
     - Mark items as served
     - Manage tables
     - Fire orders to kitchen

## Troubleshooting

### "Tenant not found" error
- Ensure the tenant ID `ghar-jesa-khana` exists in Firestore
- Check: `tenants/ghar-jesa-khana`

### "Email already exists" error
- The script will update existing users instead of failing
- This is safe and will update the user's role and permissions

### Permission errors
- Ensure your service account key has the necessary permissions
- The key should have "Firebase Admin SDK Administrator Service Agent" role

## Security Notes

⚠️ **IMPORTANT:**
- Store the service account key securely
- Never commit `service-account-key.json` to version control
- Change default passwords after first login
- Use strong passwords in production

## KDS Functionality

After creating these users, the KDS should work with the following features:

### Kitchen User Can:
- ✅ View orders filtered by their station
- ✅ Check items as they're being prepared
- ✅ Mark selected items as READY (batch operation)
- ✅ Print KOT tickets
- ✅ See order age and urgency indicators
- ✅ View order details and special notes

### Captain User Can:
- ✅ View all active orders
- ✅ Mark entire orders as SERVED
- ✅ Manage table status
- ✅ Fire orders to kitchen
- ✅ Handle bill requests

## Recent Fixes

The following KDS issues have been fixed:

1. **Item Status Updates Not Working:**
   - Added comprehensive error handling
   - Improved transaction logic
   - Added detailed logging for debugging

2. **"Mark All as Ready" Button Not Working:**
   - Fixed batch update logic
   - Added loading indicators
   - Improved error feedback
   - Added retry functionality

3. **UI Not Refreshing:**
   - Fixed state management
   - Improved real-time sync
   - Added visual feedback for updates

## Support

If you encounter any issues:
1. Check the browser console for error messages
2. Check the Flutter debug console for backend logs
3. Verify Firebase rules allow the operations
4. Ensure the user has the correct role assigned
