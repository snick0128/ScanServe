#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Dual Deployment Process..."

# 1. Clean and Get Dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# 2. Build Customer App
echo "📦 Building Customer App (Main)..."
flutter build web --target lib/main.dart --release --no-tree-shake-icons

# 3. Save Customer App build
echo "💾 Saving Customer App build..."
rm -rf build/customer_web
mv build/web build/customer_web

# 4. Build Admin App
echo "📦 Building Admin App..."
flutter build web --target lib/main_admin.dart --release --base-href "/admin/" --no-tree-shake-icons

# 5. Save Admin App build
echo "💾 Saving Admin App build..."
rm -rf build/admin_web
mv build/web build/admin_web

# 6. Assemble Final Structure
echo "🔗 Assembling final build structure..."
mkdir -p build/web/admin
cp -r build/customer_web/* build/web/
cp -r build/admin_web/* build/web/admin/

# 7. Firebase Deploy
echo "🚢 Deploying to Firebase..."
firebase deploy

echo "✅ Dual Deployment Complete!"
echo "Customer App: https://scanserve-e460a.web.app"
echo "Admin App: https://scanserve-e460a.web.app/admin"
