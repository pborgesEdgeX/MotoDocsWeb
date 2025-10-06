# MotoDocs AI Web App

A Flutter web application for AI-powered motorcycle documentation and diagnostic system.

## 🚀 Features

- **Firebase Authentication**: Secure user login and registration
- **Document Management**: Upload and manage motorcycle manuals
- **AI Chat Interface**: Ask questions about your motorcycle documentation
- **Real-time Status**: Track document processing status
- **Responsive Design**: Works on desktop and mobile browsers

## 🛠️ Setup Instructions

### 1. Firebase Configuration

You need to configure Firebase for your project. Update the following files with your Firebase project credentials:

#### Update `lib/firebase_options.dart`:
```dart
static const DefaultFirebaseOptions web = DefaultFirebaseOptions._(
  apiKey: 'YOUR_FIREBASE_API_KEY',
  appId: 'YOUR_FIREBASE_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'motodocs-ai-1759166719',
  authDomain: 'motodocs-ai-1759166719.firebaseapp.com',
  storageBucket: 'motodocs-ai-1759166719.appspot.com',
);
```

#### Get Firebase credentials:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `motodocs-ai-1759166719`
3. Go to Project Settings > General
4. Scroll down to "Your apps" section
5. Click "Add app" > Web app
6. Copy the config values

### 2. Backend Configuration

Make sure your MotoDocs AI Backend is running on `http://localhost:8000`:

```bash
cd "/Users/pauloborges/dev/flutter_projects/MotoDoc Backend"
source venv/bin/activate
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Run the Flutter Web App

```bash
cd "/Users/pauloborges/dev/flutter_projects/motodocs_web"
flutter run -d web-server --web-port 3000
```

The app will be available at: `http://localhost:3000`

## 📱 App Structure

### Screens
- **Authentication Screen**: User login and registration
- **Home Screen**: Document management and navigation
- **Document Upload**: Upload PDF motorcycle manuals
- **AI Chat**: Interactive Q&A with your documents

### Key Features

#### 🔐 Authentication
- Email/password authentication via Firebase
- Secure JWT token management
- Automatic token refresh

#### 📄 Document Management
- Upload PDF motorcycle manuals
- Categorize by bike models and components
- Track processing status
- View document metadata

#### 🤖 AI Chat
- Ask questions about your uploaded documents
- Filter by specific bike models
- Get confidence scores for answers
- Real-time conversation interface

## 🔧 API Integration

The app communicates with your MotoDocs AI Backend:

- **Base URL**: `http://localhost:8000`
- **Authentication**: Firebase JWT tokens
- **Endpoints**:
  - `GET /api/v1/documents/` - List documents
  - `POST /api/v1/documents/upload` - Upload documents
  - `POST /api/suggest` - AI chat queries
  - `GET /healthz` - Health check

## 🎨 UI/UX Features

- **Material Design 3**: Modern, clean interface
- **Responsive Layout**: Works on all screen sizes
- **Dark/Light Theme**: Automatic theme switching
- **Loading States**: Smooth user experience
- **Error Handling**: User-friendly error messages

## 🚀 Deployment

### Development
```bash
flutter run -d web-server --web-port 3000
```

### Production Build
```bash
flutter build web
```

The built files will be in `build/web/` directory.

## 🔍 Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Check your Firebase configuration
   - Ensure all API keys are correct

2. **Backend connection failed**
   - Verify backend is running on port 8000
   - Check CORS settings

3. **Authentication issues**
   - Verify Firebase Auth is enabled
   - Check email/password provider is enabled

### Debug Mode
```bash
flutter run -d web-server --web-port 3000 --debug
```

## 📚 Dependencies

- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `http`: HTTP requests
- `dio`: Advanced HTTP client
- `provider`: State management
- `file_picker`: File upload functionality

## 🎯 Next Steps

1. **Configure Firebase**: Update credentials in `firebase_options.dart`
2. **Test Authentication**: Create test users
3. **Upload Documents**: Test document upload functionality
4. **AI Chat**: Test the RAG query system
5. **Deploy**: Deploy to production when ready

## 📞 Support

For issues or questions:
- Check the backend logs for API errors
- Verify Firebase configuration
- Ensure backend is running and accessible

---

**MotoDocs AI** - Your intelligent motorcycle documentation assistant! 🏍️🤖
