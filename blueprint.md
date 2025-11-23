
# Task Manager Application Blueprint

## Overview

This document outlines the architecture, features, and implementation details of the Task Manager Flutter application. The app is designed to be a comprehensive tool for project and task management, featuring user authentication, role-based access control, a multi-language interface, and a dynamic theme system.

## Core Features

*   **User Authentication:** Secure login, registration, and password reset functionality using Firebase Authentication.
*   **Project Management:** Users can create, view, and manage projects.
*   **Task Management:** Within each project, users can manage tasks in a Kanban-style board with "To Do", "In Progress", and "Done" columns.
*   **Role-Based Access Control (RBAC):** The first user to register becomes an "admin", with subsequent users assigned the "user" role. (Further development is needed to define specific permissions).
*   **Internationalization (i18n):** Full support for English and Arabic languages using the `intl` package.
*   **Dynamic Theming:** Light, dark, and system theme options, managed with the `provider` package.
*   **Profile Management:** Users can update their display name.
*   **Task Details & Comments:** Users can view task details and add comments.

## Project Structure

```
lib
├── l10n/                 # Localization files (ARB)
├── generated/            # Auto-generated localization files
├── src/
│   ├── models/             # Data models (e.g., Project, Task)
│   ├── providers/          # State management (e.g., ThemeProvider)
│   ├── screens/            # UI screens (login, home, profile, etc.)
│   ├── widgets/            # Reusable UI components
│   └── services/           # Business logic (e.g., AuthService)
├── main.dart             # App entry point
└── auth_gate.dart        # Handles auth state changes
```

## Style & Design

*   **UI Framework:** Flutter with Material Design 3.
*   **Layout:** Clean, responsive, and intuitive layouts with a focus on usability.
*   **Icons:** Material Design icons are used throughout the app to enhance clarity.
*   **State Management:** `provider` is used for managing global state like the theme, while `StatefulWidget` and `ValueNotifier` are used for local state.

## Current Implementation Plan

**Task: Fix Localization Issues in Authentication Screens**

*   **Objective:** Resolve all hardcoded strings and incorrect localization key usage in the `login`, `signup`, and `forgot_password` screens.
*   **Status:** Completed.

**Steps Taken:**

1.  **Reviewed `forgot_password_screen.dart`:**
    *   Identified and corrected an incorrect translation key (`sendResetLink` -> `sendResetEmail`).

2.  **Reviewed `login_screen.dart`:**
    *   Identified several missing translation keys (`pleaseEnterEmail`).
    *   Added the missing keys to `app_en.arb` and `app_ar.arb`.
    *   Updated the screen to use the correct keys for validation and error messages (`error_user_not_found`, `error_wrong_password`, etc.).

3.  **Reviewed `signup_screen.dart`:**
    *   Identified numerous missing translation keys (`createAccount`, `name`, `pleaseEnterName`, `emailInUse`, etc.).
    *   Added all missing keys to both `app_en.arb` and `app_ar.arb`.
    *   Corrected a data inconsistency by changing the Firestore field for the user's name from `name` to `displayName` to match the profile screen.
    *   Updated the screen to use the correct localization keys for UI text, validation, and error handling.

4.  **Regenerated Localization Files:**
    *   Ran `flutter gen-l10n` after each modification to the `.arb` files to ensure the `AppLocalizations` class was correctly updated.

**Outcome:** All user-facing text in the authentication flow is now correctly translated and managed through the localization system. Error messages are user-friendly and translated. The user's display name is now correctly saved and displayed after registration.
