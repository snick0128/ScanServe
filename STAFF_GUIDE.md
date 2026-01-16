# 🎯 Quick Reference: P0 Features

## For Kitchen Staff

### Item Status Buttons (NEW!)
Each menu item now has its own status buttons:

1. **"Start Cooking"** (Blue) - Click when you begin preparing the item
2. **"Mark Ready"** (Green) - Click when item is ready to serve
3. **"Mark Served"** (Teal) - Click when captain has served it

**Note**: You control each item individually, not the whole order!

### Time Display (NEW!)
Look for these messages:
- 🟢 **"Just ordered"** - Fresh order, no rush
- ⚪ **"Cooking for 8 mins"** - Normal cooking time
- 🔴 **"Late – please check"** - Over 15 mins, needs attention!
- 🟦 **"Served at 2:45 PM"** - All items delivered

### Add-Ons (NEW!)
Items with blue **"NEW ADD-ON"** badge = customer added more items to existing order

---

## For Captains/Waiters

### Order Status (Automatic!)
Order status now updates automatically based on items:
- If ANY item is cooking → Order shows "Preparing"
- If ANY item is ready → Order shows "Ready"
- If ALL items served → Order shows "Served"

**You don't need to change order status manually anymore!**

### Adding Items to Existing Orders
When you add items to a table that already has an order:
- ✅ Same order number (no confusion!)
- ✅ New items marked as "ADD-ON"
- ✅ Kitchen sees them separately
- ✅ Each item has its own status

---

## For Admins

### Notifications (Enhanced!)
You'll now hear alerts for:
1. **New orders** - Sound + flash
2. **Add-on items** - Sound + flash
3. **Chef note changes** - Sound + flash

**Works on ANY screen** (Dashboard, Tables, Reports, etc.)

### Scrolling (Fixed!)
- Entire Orders screen now scrolls smoothly
- No more fixed sections
- Can handle 100+ items without lag

### Order Management
- **One order per table** (no duplicates!)
- **Item-level control** (mark items individually)
- **Auto-derived status** (no manual updates needed)

---

## Common Scenarios

### Scenario 1: Customer adds items mid-meal
**Old way**: Created new order number, confusion  
**New way**: Items append to existing order with "ADD-ON" badge

### Scenario 2: One item ready, others still cooking
**Old way**: Couldn't mark anything ready  
**New way**: Mark ready item as "Ready", others stay "Cooking"

### Scenario 3: Checking if order is late
**Old way**: Calculate minutes in your head  
**New way**: Look for red "Late – please check" message

### Scenario 4: Tracking when items were served
**Old way**: No record  
**New way**: Shows "Served at 2:45 PM" with exact time

---

## Troubleshooting

### Q: I don't see item status buttons
**A**: Check if item is already served (served items don't show buttons)

### Q: Order status not updating
**A**: It updates automatically when you change item status. Wait 1-2 seconds.

### Q: Not hearing notification sounds
**A**: Check browser sound permissions and volume

### Q: Can't scroll to see all items
**A**: This is now fixed! Try scrolling the entire screen.

### Q: Multiple orders showing for same table
**A**: This shouldn't happen anymore. Contact admin if you see this.

---

## Key Changes Summary

| Feature | Before | After |
|---------|--------|-------|
| **Scroll** | Fixed sections | Full-screen scroll |
| **Time Display** | "15m elapsed" | "Cooking for 15 mins" |
| **Notifications** | Only on Orders screen | Any screen |
| **Add-ons** | New order number | Same order + badge |
| **Item Status** | Not tracked | Individual control |
| **Order Status** | Manual update | Auto-derived |

---

## Tips for Efficiency

### For Kitchen:
1. Click "Start Cooking" immediately when you see new items
2. Watch for red "Late" warnings
3. Mark items "Ready" as soon as they're plated
4. Look for "NEW ADD-ON" badges for priority items

### For Captains:
1. Check "Ready" items frequently
2. Mark items "Served" right after delivering
3. Add items to existing orders (don't create new ones)
4. Use item notes for special instructions

### For Admins:
1. Keep sound on to catch all alerts
2. Check "Late" orders first
3. Monitor item-level completion for analytics
4. Use derived status for accurate reporting

---

**Questions?** Contact your system administrator.

**Last Updated**: 2026-01-13  
**Version**: 2.0 (P0 Features)
