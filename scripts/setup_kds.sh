#!/bin/bash

# Setup script for creating KDS and Captain users
# This script will install dependencies and run the user creation script

echo "🚀 ScanServe KDS User Setup"
echo "======================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

# Check if service account key exists
if [ ! -f "service-account-key.json" ]; then
    echo "❌ service-account-key.json not found!"
    echo ""
    echo "Please download your Firebase service account key:"
    echo "1. Go to Firebase Console"
    echo "2. Project Settings → Service Accounts"
    echo "3. Click 'Generate New Private Key'"
    echo "4. Save as 'service-account-key.json' in the project root"
    echo ""
    exit 1
fi

echo "✅ Service account key found"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Run the user creation script
echo "👥 Creating KDS and Captain users..."
echo ""
node scripts/create_kds_users.js

if [ $? -eq 0 ]; then
    echo ""
    echo "✨ Setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Test login with the created accounts"
    echo "2. Change passwords after first login"
    echo "3. Configure kitchen stations if needed"
    echo ""
else
    echo ""
    echo "❌ Setup failed. Please check the error messages above."
    exit 1
fi
