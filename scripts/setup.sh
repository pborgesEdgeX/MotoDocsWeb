#!/bin/bash

echo "🚀 Setting up MotoDocs AI Web App..."
echo "=================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if backend is running
echo "🔍 Checking if backend is running..."
if curl -s http://localhost:8000/healthz > /dev/null; then
    echo "✅ Backend is running on port 8000"
else
    echo "❌ Backend is not running. Please start it first:"
    echo "cd '/Users/pauloborges/dev/flutter_projects/MotoDoc Backend'"
    echo "source venv/bin/activate"
    echo "uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload"
    exit 1
fi

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Check Firebase configuration
echo "🔧 Checking Firebase configuration..."
if grep -q "your-api-key-here" lib/firebase_options.dart; then
    echo "⚠️  Firebase configuration needed!"
    echo "Please update lib/firebase_options.dart with your Firebase credentials:"
    echo "1. Go to https://console.firebase.google.com/"
    echo "2. Select project: motodocs-ai-1759166719"
    echo "3. Go to Project Settings > General"
    echo "4. Add a web app and copy the config"
    echo "5. Update the values in lib/firebase_options.dart"
    echo ""
    echo "Press Enter when you've updated the Firebase config..."
    read
fi

# Run the app
echo "🚀 Starting MotoDocs AI Web App..."
echo "The app will be available at: http://localhost:3000"
echo "Press Ctrl+C to stop the server"
echo ""

flutter run -d web-server --web-port 3000
