# LifeLine – NGO Application

LifeLine is a disaster relief and emergency response system designed to improve coordination between victims, rescuers, NGOs, and administrators during emergency situations.

This repository contains the **NGO application** of LifeLine. It provides NGOs with tools to monitor emergency information, coordinate with rescuers, view victim-related information, and support disaster response activities through a centralized application.

## 🎯 Purpose

The NGO application is intended to help registered NGOs participate effectively in emergency response operations by providing access to relevant disaster information and communication features.

It is part of the complete LifeLine system, which connects:

- Victims
- Rescuers
- NGOs
- System administrators

The application is designed to support faster communication, better coordination, and more organized disaster relief operations.

## 🎯 Objectives

The main objectives of the NGO application are to:

- Provide NGOs with a dedicated platform for disaster response.
- Allow authorized NGO users to register and log in.
- Provide a centralized NGO dashboard.
- Help NGOs access relevant victim and rescuer information.
- Support communication between NGOs and rescuers.
- Display critical emergency alerts.
- Provide map-based information using OpenStreetMap.
- Improve coordination between different emergency-response participants.
- Support organized management of emergency resources and response activities.

## 🚨 NGO Application Modules

### 1. NGO Authentication

The application provides authentication-related screens for NGO users, including:

- NGO login
- NGO registration
- Authentication flow
- Access to the NGO application after successful authentication

Firebase is initialized when the application starts and is used as part of the application's backend configuration.

### 2. NGO Dashboard

The dashboard provides the main working area for NGO users.

It serves as the central point from which NGOs can access the application's response and coordination features.

### 3. Critical Alerts

The application includes a critical-alert module for presenting important emergency information to NGO users.

This helps NGOs stay informed about urgent situations that may require attention or coordinated response.

### 4. Victim Information

Authorized NGO users can access victim-related information through the victim information module.

This supports the wider LifeLine emergency-response workflow by making relevant victim information available to participating organizations.

### 5. Rescuer Information

The application includes a rescuer information module that allows NGO users to access relevant information about rescuers participating in the response system.

### 6. NGO–Rescuer Communication

LifeLine includes communication support between NGOs and rescuers.

The repository contains dedicated NGO contact and chat-related functionality, allowing the NGO application to support coordination with rescuers during emergency response activities.

### 7. Rescuer Management

The application includes functionality for managing rescuers associated with NGO response activities.

This can help NGOs coordinate the personnel involved in disaster relief operations.

### 8. Map & Location

The NGO application uses:

- **Flutter Map**
- **OpenStreetMap**
- **LatLong2**
- **Flutter Map Location Marker**

These components provide map-based visualization and location-related functionality within the application.

### 9. Media & Audio Support

The application includes support for:

- Audio playback through `just_audio`
- File/media drop-zone functionality through `flutter_dropzone`

These capabilities can support application features involving audio and file interaction.

## 📦 Main Dependencies

The current project configuration includes:

```yaml
flutter_dropzone: ^4.2.1
just_audio: ^0.10.5
appwrite: ^14.0.0
cloud_firestore: ^6.1.0
firebase_core: ^4.2.1
flutter_riverpod: ^3.3.1
flutter_map: ^8.2.2
flutter_map_location_marker: ^10.1.0
latlong2: ^0.9.1
```

The project uses Dart SDK:

```text
^3.9.2
```

## 💻 Requirements

Before running the project, make sure you have:

- Flutter SDK installed
- Dart SDK compatible with the project's Flutter version
- Android Studio or another supported Flutter development environment
- A configured Flutter device/emulator for testing
- Internet connectivity for Firebase and other online services
- Access to the required Firebase project configuration

For web development/testing, a supported browser is also required.

## 🚀 Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/StorageArea483/LifeLine_Ngo.git
cd LifeLine_Ngo
```

### 2. Install dependencies

Run:

```bash
flutter pub get
```

### 3. Configure Firebase

The project contains Firebase configuration files and initializes Firebase through `firebase_options.dart`.

Make sure the required Firebase project configuration is available for the platform you intend to run.

### 4. Check connected devices

Run:

```bash
flutter devices
```

### 5. Run the application

Use:

```bash
flutter run
```

For a specific device, select the desired device through your IDE or Flutter command line.

## 🔐 Security & Privacy

Because LifeLine handles emergency-related and potentially sensitive information, security is an important part of the overall system.

The NGO application should be used with appropriate backend access controls and authenticated access.

Important considerations include:

- Protect Firebase and backend configuration.
- Do not commit private credentials, API keys, passwords, or service-account files to the repository.
- Restrict access to victim and rescuer information to authorized users.
- Apply appropriate Firestore security rules.
- Protect personal and location-related information.
- Use authenticated communication and controlled backend access.
- Keep production credentials separate from publicly shared source code.

## 🧪 Testing

The NGO application should be tested as part of the complete LifeLine emergency-response workflow.

Recommended testing areas include:

- NGO registration
- NGO login
- Dashboard navigation
- Critical alert display
- Victim information access
- Rescuer information access
- NGO–rescuer communication
- Rescuer management
- Map and location functionality
- Firebase connectivity
- Firestore data retrieval
- Application behavior under different network conditions
- UI navigation and error handling

Integration testing should also verify that information exchanged between NGOs, rescuers, victims, and administrators behaves correctly across the complete LifeLine system.

## 🌐 Supported Platform

The repository is a Flutter project and includes a `web` configuration.

The NGO application is therefore intended to support **Flutter Web** as its primary application environment.

Platform support may depend on the configuration of Firebase, Flutter packages, and the deployment environment.

## 📚 Project Documentation

This application is one component of the complete **LifeLine – A Disaster Relief & Emergency Response App** Final Year Project.

The complete system consists of:

1. LifeLine – Victim Mobile Application
2. LifeLine – Rescuer Mobile Application
3. LifeLine – NGO Application
4. LifeLine – Admin Application

The system is designed to improve communication and coordination during disasters and emergency situations such as floods, earthquakes, landslides, accidents, and other incidents requiring emergency assistance.

**Daniyal Mushtaq**  
**Aryan Sajid**

## 🎓 Final Year Project

**Project:** LifeLine – A Disaster Relief & Emergency Response App  
**Academic Session:** 2022–2026  
**FYP:** Spring 2026  
**Institution:** COMSATS University Islamabad, Abbottabad Campus  
**Supervisor:** Ms. Aatikah Rasool

## 📄 License

This repository is part of an academic Final Year Project.

Unless a separate license is added to the repository, the source code should be treated as project work developed for academic purposes. Refer to the repository owner for permission before redistributing or using the project commercially.
