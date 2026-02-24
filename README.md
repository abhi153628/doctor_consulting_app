# Doctor Consultation & Booking App

A real-time doctor consultation and service booking application built with Flutter, Firebase, and Agora, following Clean Architecture and BLoC pattern.

## 🚀 Features

- **Role-based Authentication**: Patient, Doctor, and Admin roles.
- **Doctor Discovery**: Patients can browse and filter doctors by specialization and rating.
- **Appointment Booking**: Real-time slot selection and booking flow.
- **Real-time Chat**: In-app messaging via Firestore.
- **Audio/Video Calls**: High-quality consultations powered by Agora RTC.
- **Push Notifications**: FCM integration for appointment updates and messages.
- **Admin Panel**: Doctor verification and platform management.

## 🏗️ Architecture: Clean Architecture

The project is organized into horizontal layers to separate concerns and ensure maintainability:

- **Core**: Contains shared resources like themes, error handling, and utilities.
- **Features**: Each feature (Auth, Doctor, Booking, Chat, Call) follows:
  - **Domain Layer**: Entities, Repository Interfaces, and UseCases (Pure Dart).
  - **Data Layer**: Models, Data Sources (Firebase/Agora), and Repository Implementations.
  - **Presentation Layer**: BLoCs for state management and UI widgets/pages.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Backend / DB**: [Firebase](https://firebase.google.com) (Auth, Firestore, Cloud Messaging)
- **RTC**: [Agora](https://www.agora.io)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it)

## 📊 Database Schema (Firestore)

### `users` collection:
```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "role": "patient | doctor | admin",
  "profileImageUrl": "string",
  "specialization": "string (for doctors)",
  "isApproved": "boolean (for doctors)",
  "rating": "number",
  "availableTimeSlots": ["string"]
}
```

### `bookings` collection:
```json
{
  "id": "string",
  "doctorId": "string",
  "userId": "string",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "status": "pending | accepted | completed | cancelled",
  "totalAmount": "number"
}
```

### `chats` collection:
```json
{
  "id": "string",
  "participantIds": ["string"],
  "lastMessage": "string",
  "lastMessageTime": "timestamp"
}
```

## ⚙️ Setup Instructions

1. **Clone the repository.**
2. **Firebase Setup**:
   - Create a Firebase project.
   - Add Android/iOS apps and download `google-services.json` / `GoogleService-Info.plist`.
   - Enable Email/Password Auth and Firestore.
3. **Agora Setup**:
   - Create an Agora project and get the `AppID`.
   - Update `CallRemoteDataSource` with your `AppID`.
4. **Environment**:
   - Run `flutter pub get`.
   - Run `flutter run`.

## 🎨 Theme
- **Color**: `#10A5C0` (Medical Blue)
- **Font**: Inter
