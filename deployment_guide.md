# SmartExam - Deployment & Setup Guide

This guide describes how to configure the backend API, set up the MySQL database, and run the Flutter client application on your local machine.

---

## 1. Prerequisites
Ensure you have the following installed on your developer machine:
*   **XAMPP / WampServer** (PHP 8.0+ and MySQL Server)
*   **Flutter SDK** (Channel stable, 3.10+)
*   **Web Browser** (Google Chrome) or mobile emulator (Android/iOS) for client execution.

---

## 2. Database Configuration
SmartExam uses a MySQL database named `smartexam_db`.

1.  Open **XAMPP Control Panel** and start both **Apache** and **MySQL** services.
2.  Open your browser and navigate to **phpMyAdmin** (`http://localhost/phpmyadmin`).
3.  Choose **Import** and select the schema script [schema.sql](file:///c:/Aman/htdocs/online-examination-system/db/schema.sql) located at your project directory under `/db/schema.sql`, OR:
4.  Run the automated importer script using PHP CLI from the project directory:
    ```bash
    C:\Aman\php\php.exe db/import.php
    ```
5.  This will automatically build the tables and insert three default test users:
    *   **Administrator**: `admin@smartexam.com` (password: `admin123`)
    *   **Teacher/Examiner**: `teacher@smartexam.com` (password: `teacher123`)
    *   **Student**: `student@smartexam.com` (password: `student123`)

---

## 3. Backend REST API Deployment
1.  Verify that the project directory `online-examination-system` is located in your Apache root folder:
    *   Path: `C:\Aman\htdocs\online-examination-system`
2.  The backend routes requests dynamically using the [.htaccess](file:///c:/Aman/htdocs/online-examination-system/backend/.htaccess) URL rewrite rules. Ensure that `mod_rewrite` is enabled in your Apache configuration (`httpd.conf`):
    *   Search for `LoadModule rewrite_module modules/mod_rewrite.so` and make sure it is not commented out with a `#`.
3.  The API endpoints will be accessible locally at:
    *   `http://localhost/online-examination-system/backend/api/`

---

## 4. Flutter Frontend Client Configuration
1.  Navigate to the `frontend/` directory:
    ```bash
    cd frontend
    ```
2.  Open [api_endpoints.dart](file:///c:/Aman/htdocs/online-examination-system/frontend/lib/constants/api_endpoints.dart) and configure the host URL based on your target execution platform:
    *   **Web Browser (Chrome)**: Use `localhost` (e.g. `http://localhost/online-examination-system/backend/api`).
    *   **Android Emulator**: Replace `localhost` with `10.0.2.2` (e.g. `http://10.0.2.2/online-examination-system/backend/api`).
    *   **Physical Mobile Device**: Replace `localhost` with your computer's local IP address (e.g. `http://192.168.1.100/...`) and ensure both devices are connected to the same Wi-Fi.
3.  Download package dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the application in debug mode on Google Chrome:
    ```bash
    flutter run -d chrome
    ```
5.  To build a release bundle:
    *   **Web**: `flutter build web` (Outputs bundle to `build/web/`)
    *   **Android APK**: `flutter build apk` (Outputs APK to `build/app/outputs/flutter-apk/app-release.apk`)
