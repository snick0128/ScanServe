# Bugfix Requirements Document

## Introduction

This document covers 14 bugs and feature gaps in the QR Menu Platform (scan_serve), a Flutter-based restaurant SaaS app. Issues span billing, inventory, authentication, staff management, voice ordering, table management, notifications, and navigation. They are grouped by priority: P0 (Critical), P1 (High), P2 (Feature Gaps), and P3 (UI/Structure).

---

## Bug Analysis

### Current Behavior (Defect)

**P0-1 · Discount Bug [Billing]**

1.1 WHEN a two-digit discount percentage (e.g. 10%, 25%) is applied to a bill THEN the system calculates an incorrect discount amount due to type coercion between string and number

1.2 WHEN a discount is applied to a multi-item order THEN the system produces a wrong final total

**P0-2 · Mark as Paid Failure [Billing]**

1.3 WHEN a captain taps "Mark as Paid" on a pending bill THEN the system silently fails with no state change, no success feedback, and no error message

1.4 WHEN "Mark as Paid" fails THEN the system provides no retry mechanism

1.5 WHEN a captain double-taps "Mark as Paid" rapidly THEN the system may attempt to process the payment multiple times

**P0-3 · Auto Stock Deduction [Inventory]**

1.6 WHEN an order is confirmed THEN the system does not reduce linked ingredient quantities in inventory

1.7 WHEN an ingredient reaches zero quantity after an order THEN the system does not flag the linked menu item as out-of-stock

**P0-4 · Inactive Captain Can Still Operate [Auth]**

1.8 WHEN a captain account is deactivated in the admin panel THEN the system continues to allow that captain to log in

1.9 WHEN a captain is deactivated while they have an active session THEN the system does not invalidate their session or force a logout

**P0-5 · Duplicate Staff on Update [Staff]**

1.10 WHEN an admin updates an existing captain's profile information THEN the system creates a new staff record instead of updating the existing one

1.11 WHEN a duplicate staff record is created THEN the system does not reject it with a clear error

**P1-6 · Voice System Bugs [Order]**

1.12 WHEN an item is added to the cart THEN the system speaks the item name twice

1.13 WHEN "Order Again" is triggered THEN the voice announcement is unreliable and may not fire or may fire multiple times

1.14 WHEN a user taps "add item" multiple times in rapid succession THEN the system queues duplicate speech events

**P1-7 · Fake Occupied Tables After Logout [Tables]**

1.15 WHEN a captain logs out THEN the system leaves tables in "occupied" status even when no active orders exist for those tables

1.16 WHEN a captain logs back in THEN the system shows stale occupied table states that do not reflect actual server state

**P1-8 · Billing History Sort Order [Billing]**

1.17 WHEN a user views billing history THEN the system displays new bills at the bottom of the list instead of the top

**P1-9 · Captain App UI Fixes [Captain App]**

1.18 WHEN a captain logs in THEN the system does not display the captain's name in the app header

1.19 WHEN a captain is logged in THEN the system shows Sales and Analytics sections that should be restricted to admin roles only

1.20 WHEN a captain views the navigation THEN the structure does not match the expected TMBill captain app reference layout

**P1-10 · Sound Notifications [Notifications / KDS]**

1.21 WHEN a new task is assigned to a captain THEN the system plays no sound notification

1.22 WHEN a new order arrives at the KDS THEN the kitchen display plays no alert sound

1.23 WHEN a user wants to disable sound notifications THEN the system provides no toggle, and no preference is persisted

**P2-11 · Previous Bill Regeneration [Billing]**

1.24 WHEN a staff member needs to view or reprint a past bill THEN the system provides no dedicated Bill History screen with full detail and reprint capability

**P2-12 · Table Settle & Merge [Tables]**

1.25 WHEN a captain needs to settle a table THEN the system provides no "Settle Table" action to close all orders, generate a final bill, and mark the table available

1.26 WHEN a captain needs to combine orders from multiple tables THEN the system provides no "Merge Tables" action

**P2-13 · Mandatory Email on Staff Creation [Staff]**

1.27 WHEN an admin creates a new staff account without providing an email THEN the system accepts the submission and creates the account

**P3-14 · Navigation Reorder [Global Nav]**

1.28 WHEN a user views the sidebar or captain bottom navigation THEN the navigation items appear in an incorrect order that does not match the required sequence

---

### Expected Behavior (Correct)

**P0-1 · Discount Bug [Billing]**

2.1 WHEN a two-digit discount percentage is applied THEN the system SHALL calculate discount as `(discountPercent / 100) * subtotal` using numeric types, producing correct results (e.g. 10% on ₹200 = ₹180, 25% on ₹400 = ₹300)

2.2 WHEN a discount is applied to a multi-item order THEN the system SHALL produce the correct final total with no rounding errors

**P0-2 · Mark as Paid Failure [Billing]**

2.3 WHEN a captain taps "Mark as Paid" THEN the system SHALL show a loading indicator while the operation is in progress

2.4 WHEN "Mark as Paid" succeeds THEN the system SHALL update the bill status to PAID and display a success toast

2.5 WHEN "Mark as Paid" fails THEN the system SHALL display an error message with a retry option

2.6 WHEN a captain double-taps "Mark as Paid" THEN the system SHALL process the payment only once and ignore subsequent taps while the first is in progress

**P0-3 · Auto Stock Deduction [Inventory]**

2.7 WHEN an order is confirmed THEN the system SHALL deduct the linked ingredient quantities from inventory, logging each deduction with the order ID and timestamp

2.8 WHEN an ingredient quantity reaches zero after deduction THEN the system SHALL flag all linked menu items as out-of-stock

**P0-4 · Inactive Captain Can Still Operate [Auth]**

2.9 WHEN a deactivated captain attempts to log in THEN the system SHALL reject the login and return a 401 with the message "Your account has been deactivated."

2.10 WHEN a captain is deactivated while they have an active session THEN the system SHALL invalidate their session immediately and force a logout on their next API call

**P0-5 · Duplicate Staff on Update [Staff]**

2.11 WHEN an admin updates an existing captain's profile THEN the system SHALL update the existing staff record by ID, not create a new one

2.12 WHEN a duplicate user ID or phone number is submitted THEN the system SHALL reject it with a clear, descriptive error message

**P1-6 · Voice System Bugs [Order]**

2.13 WHEN an item is successfully added to the cart THEN the system SHALL speak the item name exactly once via a single VoiceQueue

2.14 WHEN "Order Again" is triggered THEN the system SHALL announce it exactly once

2.15 WHEN the same item is queued for speech within 500ms THEN the system SHALL deduplicate and speak it only once

**P1-7 · Fake Occupied Tables After Logout [Tables]**

2.16 WHEN a captain logs out THEN the system SHALL release all table locks and sessions held by that captain

2.17 WHEN a captain logs back in THEN the system SHALL sync table status from the server, showing no ghost occupied tables

**P1-8 · Billing History Sort Order [Billing]**

2.18 WHEN a user views billing history THEN the system SHALL display bills ordered by `createdAt` descending, with the most recent bill at the top

**P1-9 · Captain App UI Fixes [Captain App]**

2.19 WHEN a captain logs in THEN the system SHALL fetch and display the captain's name in the app header immediately

2.20 WHEN a captain is logged in THEN the system SHALL hide Sales and Analytics navigation items

2.21 WHEN a captain views the navigation THEN the system SHALL display items matching the TMBill captain app reference structure

**P1-10 · Sound Notifications [Notifications / KDS]**

2.22 WHEN a new task is assigned to a captain THEN the system SHALL play a sound notification

2.23 WHEN a new order arrives at the KDS THEN the system SHALL play a distinct kitchen alert sound

2.24 WHEN a user toggles the sound notification setting THEN the system SHALL persist the preference in localStorage and respect it immediately

**P2-11 · Previous Bill Regeneration [Billing]**

2.25 WHEN a staff member opens Bill History THEN the system SHALL display all past bills with date, table, amount, and status

2.26 WHEN a staff member selects a past bill THEN the system SHALL show the full bill detail in a read-only view

2.27 WHEN a staff member taps Reprint / Download PDF THEN the system SHALL generate an identical bill PDF

**P2-12 · Table Settle & Merge [Tables]**

2.28 WHEN a captain triggers "Settle Table" THEN the system SHALL close all orders for that table, generate a final bill, and mark the table as available, with a confirmation dialog

2.29 WHEN a captain triggers "Merge Tables" THEN the system SHALL combine orders from 2 or more selected tables into one bill with no item loss, with a confirmation dialog, and sync the result in real time across all devices

**P2-13 · Mandatory Email on Staff Creation [Staff]**

2.30 WHEN an admin submits the staff creation form without an email THEN the system SHALL prevent submission and display a validation error

2.31 WHEN a staff creation request reaches the server without an email THEN the system SHALL reject it

2.32 WHEN a duplicate email is submitted THEN the system SHALL reject it with a clear error

**P3-14 · Navigation Reorder [Global Nav]**

2.33 WHEN a user views the sidebar or captain bottom navigation THEN the system SHALL display items in exactly this order: Dashboard → Table → Order → Bill → Staff → KDS → Menu → Inventory, with correct active highlight states and no broken routes

---

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a discount of 0% is applied THEN the system SHALL CONTINUE TO calculate the full subtotal with no discount applied

3.2 WHEN a positive quantity order is placed with no discount THEN the system SHALL CONTINUE TO calculate subtotal, tax, and total correctly

3.3 WHEN "Mark as Paid" succeeds on a valid first tap THEN the system SHALL CONTINUE TO update the bill status and release the table as before

3.4 WHEN an order is cancelled before confirmation THEN the system SHALL CONTINUE TO not deduct inventory stock

3.5 WHEN a refund is processed THEN the system SHALL CONTINUE TO restore the deducted inventory quantities

3.6 WHEN an active admin account logs in THEN the system SHALL CONTINUE TO authenticate successfully without any isActive check interference

3.7 WHEN a new staff member is created (not updated) THEN the system SHALL CONTINUE TO insert a new record correctly

3.8 WHEN a single item is added to the cart slowly (no rapid taps) THEN the system SHALL CONTINUE TO speak the item name once as before

3.9 WHEN a table has an active order and the captain is still logged in THEN the system SHALL CONTINUE TO show the table as occupied

3.10 WHEN billing history is filtered THEN the system SHALL CONTINUE TO maintain descending sort order within the filtered results

3.11 WHEN an admin is logged in THEN the system SHALL CONTINUE TO show all navigation items including Sales and Analytics

3.12 WHEN sound notifications are enabled THEN the system SHALL CONTINUE TO play sounds on new orders and tasks as configured

3.13 WHEN a current bill is being viewed THEN the system SHALL CONTINUE TO allow editing and payment actions (read-only restriction applies only to past bills)

3.14 WHEN a table is settled individually THEN the system SHALL CONTINUE TO not affect the status or orders of other tables

3.15 WHEN staff email is provided during creation THEN the system SHALL CONTINUE TO create the account successfully as before

3.16 WHEN navigating between screens THEN the system SHALL CONTINUE TO maintain correct active highlight states with no broken routes

---

## Bug Condition Pseudocode

### P0-1 · Discount Bug

```pascal
FUNCTION isBugCondition_Discount(X)
  INPUT: X of type BillInput { discountPercent: any, subtotal: number }
  OUTPUT: boolean
  RETURN typeof(X.discountPercent) = 'string' OR X.discountPercent >= 10
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_Discount(X) DO
  result ← calculateBill'(X)
  ASSERT result.discount = (toNumber(X.discountPercent) / 100) * X.subtotal
  ASSERT result.finalTotal = X.subtotal - result.discount + result.tax
END FOR

// Property: Preservation Checking
FOR ALL X WHERE NOT isBugCondition_Discount(X) DO
  ASSERT calculateBill(X) = calculateBill'(X)
END FOR
```

### P0-2 · Mark as Paid Failure

```pascal
FUNCTION isBugCondition_MarkAsPaid(X)
  INPUT: X of type PaymentAction { taps: number, networkState: string }
  OUTPUT: boolean
  RETURN X.taps >= 1
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_MarkAsPaid(X) DO
  result ← markAsPaid'(X)
  ASSERT result.loadingShown = true
  ASSERT (result.success → result.status = 'PAID' AND result.toastShown = true)
  ASSERT (NOT result.success → result.errorShown = true AND result.retryAvailable = true)
  ASSERT result.paymentCount = 1
END FOR
```

### P0-4 · Inactive Captain Auth

```pascal
FUNCTION isBugCondition_InactiveCaptain(X)
  INPUT: X of type AuthRequest { userId: string, isActive: boolean }
  OUTPUT: boolean
  RETURN X.isActive = false
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_InactiveCaptain(X) DO
  result ← authenticate'(X)
  ASSERT result.statusCode = 401
  ASSERT result.message = "Your account has been deactivated."
END FOR
```

### P0-5 · Duplicate Staff on Update

```pascal
FUNCTION isBugCondition_StaffUpdate(X)
  INPUT: X of type StaffUpdateRequest { staffId: string, operation: string }
  OUTPUT: boolean
  RETURN X.operation = 'update' AND X.staffId != null
END FUNCTION

// Property: Fix Checking
FOR ALL X WHERE isBugCondition_StaffUpdate(X) DO
  countBefore ← countStaffRecords(X.staffId)
  updateStaff'(X)
  countAfter ← countStaffRecords(X.staffId)
  ASSERT countAfter = countBefore
  ASSERT getStaffById(X.staffId).data = X.newData
END FOR
```
