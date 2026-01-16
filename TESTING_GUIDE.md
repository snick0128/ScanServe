# ScanServe Testing Guide

This guide provides all the necessary information to test the ScanServe application, including live URLs, credentials for different roles, and step-by-step testing workflows.

## 🔗 Live URLs

- **Customer App**: [https://scanserve-e460a.web.app/](https://scanserve-e460a.web.app/)
- **Admin Panel**: [https://scanserve-e460a.web.app/admin/](https://scanserve-e460a.web.app/admin/)

---

## 🔐 Credentials by Role

### 1. Super Admin (Global Manager)
*Use this role to manage all restaurants (tenants) and oversee the entire platform.*

| Email | Password |
| :--- | :--- |
| `superadmin@scanserve.com` | `password123` |
| `nick@yopmail.com` (Master) | `123456` |

### 2. Restaurant Admin (Owner/Manager)
*Use this role to manage a specific restaurant's menu, tables, and billing.*

| Email | Password | Tenant |
| :--- | :--- | :--- |
| `demoadmin@scanserve.com` | `123456` | Demo Restaurant |
| `masteradmin@scanserve.com` | `password123` | Demo Restaurant |

### 3. Kitchen Staff (Chef/Cook)
*Use this role to view incoming orders and update their cooking status.*

| Email | Password | Tenant |
| :--- | :--- | :--- |
| `demokitchen@scanserve.com` | `password123` | Demo Restaurant |

---

## 🧪 Testing Workflows

### Scenario A: The Full Dining Loop (Customer + Kitchen + Admin)

**Step 1: Customer Places Order**
1. Open the [Customer App](https://scanserve-e460a.web.app/) on your phone or browser.
   - *Note: You can simulate scanning a QR code by adding `?tableId=T1` to the URL.*
2. Browse the menu and add items to your cart.
3. Tap "View Order" and select **"Send to Kitchen"** (for Dine-in) or **"Checkout"**.
4. Enter your name (e.g., "John Doe") and submit.

**Step 2: Kitchen Prepares Order**
1. Open the [Admin Panel](https://scanserve-e460a.web.app/admin/) in a separate browser window/tab.
2. Log in as **Kitchen Staff** (`demokitchen@scanserve.com`).
3. You should see the new order under "Active Orders".
4. Tap **"Accept"** -> Order moves to "Preparing".
5. Once done, tap **"Mark Ready"** -> Order moves to "Ready".

**Step 3: Admin Billing & Completion**
1. Log out and log back in as **Restaurant Admin** (`demoadmin@scanserve.com`).
2. Go to the **"Bills"** or **"Orders"** section.
3. Locate Table T1 (or the order you placed).
4. Tap **"Generate Bill"**.
5. You can now **Print** the bill or **Share via WhatsApp**.
6. Finally, mark the order as **"Completed"** / **"Paid"** to close the session.

---

### Scenario B: Super Admin Management

1. Log in to the [Admin Panel](https://scanserve-e460a.web.app/admin/) as **Super Admin** (`superadmin@scanserve.com`).
2. You will see the **Master Console**.
3. **Features to Test**:
   - **Create Tenant**: Add a new restaurant.
   - **Switch View**: Click on "Access Panel" for "Demo Restaurant" to view the dashboard as if you were that restaurant's admin.
   - **Manage Plan**: Update subscription expiry for a tenant.

---

## 🛠 Troubleshooting

- **Login Fails?** 
  - Double-check the password. 
  - Ensure you are on the correct URL (`/admin/`).
  - Try the `nick@yopmail.com` master login if the database seems unresponsive.

- **Changes not showing?**
  - Refresh the page. Simple UI updates might require a hard refresh (Ctrl+F5 or Cmd+Shift+R).
  - Data updates (menu items, orders) are real-time and should appear automatically.
