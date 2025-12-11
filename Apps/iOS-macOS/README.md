# VibeCreator iOS & macOS Application

A native iOS and macOS application for VibeCreator - the social media management platform. This app provides a seamless experience across Apple devices, allowing users to manage their social media posts, schedule content, and track analytics.

## Features

- **Dashboard**: View analytics, recent posts, and account statistics
- **Post Management**: Create, edit, schedule, and manage posts across multiple social platforms
- **Calendar View**: Month and week views for visualizing scheduled content
- **Account Management**: Connect and manage Twitter/X, Facebook Pages, Facebook Groups, and Mastodon accounts
- **Media Library**: Upload, manage, and search stock photos (Unsplash) and GIFs (Tenor)
- **Settings**: Customize timezone, time format, and notification preferences
- **Cross-Platform Sync**: All data syncs with the web application and backend

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Backend server running VibeCreator

## Project Structure

```
Apps/iOS-macOS/
├── VibeCreator/                    # Main app target
│   ├── App/
│   │   ├── VibeCreatorApp.swift   # App entry point
│   │   └── ContentView.swift      # Main navigation
│   ├── Views/
│   │   ├── Auth/                  # Login/Register views
│   │   ├── Dashboard/             # Dashboard and analytics
│   │   ├── Posts/                 # Post management views
│   │   ├── Calendar/              # Calendar views
│   │   ├── Accounts/              # Account management
│   │   ├── Media/                 # Media library
│   │   ├── Settings/              # Settings and profile
│   │   └── Components/            # Reusable UI components
│   ├── ViewModels/                # View models
│   ├── Models/                    # Local models
│   ├── Services/                  # App services
│   ├── Utilities/                 # Helper utilities
│   ├── Resources/                 # Assets and resources
│   └── Assets.xcassets/           # Image assets
├── VibeCreatorKit/                # Shared framework
│   └── Sources/VibeCreatorKit/
│       ├── API/                   # API client
│       ├── Models/                # Data models
│       ├── Extensions/            # Swift extensions
│       └── Utilities/             # Shared utilities
├── VibeCreatorTests/              # Unit tests
└── VibeCreatorUITests/            # UI tests
```

## Setup Instructions

### 1. Configure Backend URL

Open `VibeCreator/App/VibeCreatorApp.swift` and update the API base URL:

```swift
struct AppConfig {
    static var apiBaseURL: String {
        #if DEBUG
        // Development URL
        return "http://localhost:8000"
        #else
        // Production URL
        return "https://your-vibecreator-server.com"
        #endif
    }
}
```

### 2. Configure Backend API Routes

Ensure the mobile API routes are registered in your Laravel backend. Add the following to your `routes/api.php` or register the routes provider:

```php
// Include the mobile API routes
require __DIR__.'/api_mobile.php';
```

Or add to your service provider:

```php
Route::prefix('api/mobile')
    ->middleware(['api'])
    ->group(base_path('routes/api_mobile.php'));
```

### 3. Install Laravel Sanctum (if not already installed)

The mobile API uses Laravel Sanctum for authentication. Ensure it's installed:

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

Add the `HasApiTokens` trait to your User model:

```php
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
}
```

### 4. Build and Run

1. Open `VibeCreator.xcodeproj` in Xcode
2. Select your target device (iPhone, iPad, or Mac)
3. Build and run (⌘+R)

## Architecture

### SwiftUI + MVVM

The app uses SwiftUI with the MVVM (Model-View-ViewModel) architecture pattern:

- **Views**: SwiftUI views that display the UI
- **ViewModels**: Handle business logic and state management
- **Models**: Data structures that match the backend API

### VibeCreatorKit Framework

A shared Swift Package that provides:

- **APIClient**: Networking layer with async/await support
- **AuthManager**: Authentication and session management with Keychain storage
- **Models**: Codable data models matching the backend API
- **Utilities**: Image loading, date formatting, and other helpers

### Dependencies

- [Alamofire](https://github.com/Alamofire/Alamofire) - HTTP networking
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - Secure credential storage

## API Endpoints

The app communicates with these backend API endpoints:

### Authentication
- `POST /api/mobile/login` - User login
- `POST /api/mobile/register` - User registration
- `POST /api/mobile/logout` - Logout
- `POST /api/mobile/refresh` - Refresh token

### Dashboard & Reports
- `GET /api/mobile/dashboard` - Dashboard data
- `GET /api/mobile/reports` - Analytics reports

### Posts
- `GET /api/mobile/posts` - List posts (paginated)
- `POST /api/mobile/posts` - Create post
- `GET /api/mobile/posts/{id}` - Get post
- `PUT /api/mobile/posts/{id}` - Update post
- `DELETE /api/mobile/posts/{id}` - Delete post
- `POST /api/mobile/posts/{id}/schedule` - Schedule post
- `POST /api/mobile/posts/{id}/duplicate` - Duplicate post

### Calendar
- `GET /api/mobile/calendar` - Calendar data

### Accounts
- `GET /api/mobile/accounts` - List accounts
- `GET /api/mobile/accounts/add/{provider}` - Get OAuth URL
- `PUT /api/mobile/accounts/{id}` - Refresh account
- `DELETE /api/mobile/accounts/{id}` - Remove account

### Media
- `GET /api/mobile/media/uploads` - List uploads
- `GET /api/mobile/media/stock` - Search stock photos
- `GET /api/mobile/media/gifs` - Search GIFs
- `POST /api/mobile/media/upload` - Upload file
- `POST /api/mobile/media/download` - Download external media
- `DELETE /api/mobile/media` - Delete media

### Tags
- `GET /api/mobile/tags` - List tags
- `POST /api/mobile/tags` - Create tag
- `PUT /api/mobile/tags/{id}` - Update tag
- `DELETE /api/mobile/tags/{id}` - Delete tag

### Settings
- `GET /api/mobile/settings` - Get settings
- `PUT /api/mobile/settings` - Update settings

### System
- `GET /api/mobile/system/status` - System status
- `GET /api/mobile/services` - List services

## Supported Platforms

- **Twitter/X**: Post tweets, view analytics
- **Facebook Pages**: Post to pages, view insights
- **Facebook Groups**: Post to groups
- **Mastodon**: Post to any Mastodon instance

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is part of the VibeCreator platform. See the main project for license details.

## Support

For support, please open an issue in the main VibeCreator repository or contact the development team.
