# PowerShell script to create Flutter app structure for GreenPredict
# Run this in your project root: D:\ACBT\Year_03\Applied_Project\MyFirstApp\flutterapp

Write-Host "Creating Flutter app structure for GreenPredict..." -ForegroundColor Green

# Create main directories
$directories = @(
    "lib",
    "lib\models",
    "lib\providers",
    "lib\screens",
    "lib\screens\auth",
    "lib\screens\home",
    "lib\screens\ai_prediction",
    "lib\screens\marketplace",
    "lib\screens\profile",
    "lib\services",
    "lib\utils",
    "lib\widgets",
    "assets",
    "assets\images",
    "assets\icons",
    "assets\fonts",
    "assets\animations"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir" -ForegroundColor Blue
    }
}

# Create empty Dart files
$dartFiles = @(
    "lib\main.dart",
    "lib\models\ai_prediction_result.dart",
    "lib\providers\auth_provider.dart",
    "lib\providers\crop_provider.dart",
    "lib\providers\listing_provider.dart",
    "lib\screens\splash_screen.dart",
    "lib\screens\main_navigation.dart",
    "lib\screens\auth\login_screen.dart",
    "lib\screens\auth\register_screen.dart",
    "lib\screens\home\home_screen.dart",
    "lib\screens\ai_prediction\ai_prediction_screen.dart",
    "lib\screens\ai_prediction\ai_analysis_result_screen.dart",
    "lib\screens\marketplace\marketplace_screen.dart",
    "lib\screens\profile\profile_screen.dart",
    "lib\services\api_service.dart",
    "lib\utils\app_theme.dart",
    "lib\widgets\gradient_button.dart",
    "lib\widgets\glassmorphism_card.dart"
)

foreach ($file in $dartFiles) {
    if (!(Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force
        Write-Host "Created file: $file" -ForegroundColor Yellow
    }
}

# Create pubspec.yaml if it doesn't exist
if (!(Test-Path "pubspec.yaml")) {
    New-Item -ItemType File -Path "pubspec.yaml" -Force
    Write-Host "Created file: pubspec.yaml" -ForegroundColor Yellow
}

# Create README.md
if (!(Test-Path "README.md")) {
    $readmeContent = @"
# Green Predict

AI-powered agricultural platform for sustainable farming prediction and consumption.

## Features

- AI crop prediction and recommendations
- Marketplace for farmers and consumers
- Direct farmer-consumer communication
- Sustainable agriculture insights
- User-friendly mobile interface

## Getting Started

1. Install Flutter dependencies:
   ```
   flutter pub get
   ```

2. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart
├── models/
├── providers/
├── screens/
│   ├── auth/
│   ├── home/
│   ├── ai_prediction/
│   ├── marketplace/
│   └── profile/
├── services/
├── utils/
└── widgets/
```

## Requirements

- Flutter 3.0+
- Dart 3.0+
- Firebase project setup
- FastAPI backend (optional for development)
"@
    Set-Content -Path "README.md" -Value $readmeContent
    Write-Host "Created file: README.md" -ForegroundColor Yellow
}

# Create .gitignore if it doesn't exist
if (!(Test-Path ".gitignore")) {
    $gitignoreContent = @"
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Firebase
/android/app/google-services.json
/ios/Runner/GoogleService-Info.plist

# Environment variables
.env
.env.local
.env.development
.env.test
.env.production
"@
    Set-Content -Path ".gitignore" -Value $gitignoreContent
    Write-Host "Created file: .gitignore" -ForegroundColor Yellow
}

# Create analysis_options.yaml for better code analysis
if (!(Test-Path "analysis_options.yaml")) {
    $analysisContent = @"
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
    always_declare_return_types: true
    always_put_control_body_on_new_line: true
    avoid_print: true
    avoid_unnecessary_containers: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true
"@
    Set-Content -Path "analysis_options.yaml" -Value $analysisContent
    Write-Host "Created file: analysis_options.yaml" -ForegroundColor Yellow
}

Write-Host "`nFlutter app structure created successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Copy the Dart code I provided into the respective files" -ForegroundColor White
Write-Host "2. Update pubspec.yaml with the dependencies I provided" -ForegroundColor White
Write-Host "3. Run 'flutter pub get' to install dependencies" -ForegroundColor White
Write-Host "4. Set up Firebase configuration" -ForegroundColor White
Write-Host "5. Run 'flutter run' to start the app" -ForegroundColor White

Write-Host "`nProject structure:" -ForegroundColor Cyan
Get-ChildItem -Recurse -Directory | ForEach-Object { Write-Host $_.FullName.Replace((Get-Location).Path + "\", "") -ForegroundColor Gray }