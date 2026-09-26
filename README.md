# Future Tech - Tuition Center Management App

Future Tech is a modern, responsive, and secure mobile application for managing students, attendance, tasks, fees, and more. It consists of a Java Spring Boot backend and a Flutter mobile frontend.

## Prerequisites
- **Java 17+**
- **Maven** (for building the backend)
- **MySQL 8+**
- **Flutter SDK 3+**
- **Resend API Key** (for automated emails)

## 1. Database Setup
Create the MySQL database before running the backend. Run the following command in your MySQL terminal or GUI (e.g., MySQL Workbench):
```sql
CREATE DATABASE future_tech;
```

## 2. Backend Setup (Spring Boot)
The backend uses Spring Boot, Spring Security (JWT), and Spring Data JPA.

1. Navigate to the backend directory:
   ```powershell
   cd backend
   ```
2. Configure your database and API credentials in `src/main/resources/application.yml`:
   - Set `spring.datasource.password` to your MySQL root password.
   - Set `resend.api.key` to your active Resend API Key.
3. Start the Spring Boot application:
   ```powershell
   mvn spring-boot:run
   ```
   *The backend server will start locally at `http://localhost:8080`.*

## 3. Frontend Setup (Flutter)
The frontend uses Flutter with Provider for clean state management and secure JWT storage.

1. Navigate to the frontend directory:
   ```powershell
   cd frontend
   ```
2. Install dependencies:
   ```powershell
   flutter pub get
   ```
3. Run the Flutter application:
   ```powershell
   flutter run
   ```
   *Note: Make sure you have an Android/iOS emulator running, or a physical device connected.*

## 4. Usage Flow
- **Student Registration**: A student installs the app and registers. Their status becomes `PENDING_APPROVAL`. An email is sent to the Admin.
- **Admin Dashboard**: The Admin logs in to view pending student requests and clicks "Approve". An email notifies the student.
- **Student Dashboard**: The student logs in to view their profile, daily assigned tasks (with checkboxes), fee payments, and attendance records.
