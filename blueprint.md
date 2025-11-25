# TaskVerse Blueprint

## Overview

TaskVerse is a comprehensive task management application built with Flutter and Firebase. It aims to provide a seamless and intuitive experience for managing projects and tasks, with a focus on collaboration and real-time updates. The application supports multiple languages (English and Arabic), dynamic themes, and a role-based access control system.

---

## Current Implemented Features (as of last session)

*   **Authentication:**
    *   Email/Password signup and login.
    *   Google Sign-In.
    *   Password reset functionality.
    *   Secure session management with Firebase Authentication.

*   **Project Management:**
    *   Create new projects via a simple dialog with a title and description.
    *   View a list of all projects.
    *   Projects are stored in the `projects` collection in Firestore.

*   **Task Management:**
    *   Kanban-style board for tasks within a project (`To Do`, `In Progress`, `Done`).
    *   Create tasks with a title and description.
    *   Assign tasks to any registered user.
    *   View task details, add comments, and update task status.
    *   Real-time updates for task changes.

*   **User & Profile:**
    *   The first user to register is automatically assigned an `admin` role.
    *   Users can view and edit their display name.
    *   User information is stored in the `users` collection.

*   **UI/UX:**
    *   **Localization (i18n):** Full support for English and Arabic, with an in-app language switcher.
    *   **Theming:** Light, Dark, and System theme options.
    *   **Responsive Design:** UI adapts to different screen sizes.

---

## Plan for New Feature Implementation

**Objective:** Overhaul the project and task creation process to be more detailed and collaborative, as per the user's request.

### Part 1: New Project Creation Screen

1.  **Create a New Dedicated Screen:**
    *   Replace the current "New Project" dialog with a full-screen page: `lib/src/screens/create_project_screen.dart`.

2.  **Update Navigation:**
    *   The Floating Action Button on the projects view will navigate to this new screen.

3.  **Develop UI for `CreateProjectScreen`:**
    *   The screen will be a `StatefulWidget` containing a `Form`.
    *   **Input Fields:**
        *   `TextFormField` for **Project Name** (required).
        *   `TextFormField` for **Project Description** (optional).
        *   `TextFormField` for **Project Plan** (optional).
    *   **Date Selection:**
        *   `DatePicker` for **Start Date** (required).
        *   `DatePicker` for **Expected End Date** (required).
    *   **User Selection:**
        *   A dropdown menu to select a single **Project Owner** from the list of all registered users.
        *   A multi-selection mechanism (e.g., a dialog with checkboxes) to choose **Project Members** from the list of all registered users.

4.  **Update Data Model (Firestore Schema for `projects` collection):**
    *   The project document will be enhanced with the following new fields:
        *   `code`: A randomly generated, unique ID for the project.
        *   `ownerId`: The UID of the user selected as the project owner.
        *   `members`: An array of UIDs for all selected project members.
        *   `startDate`: A `Timestamp` for the project's start date.
        *   `endDate`: A `Timestamp` for the project's expected end date.
        *   `plan`: A string to store the project plan.

5.  **Implement Backend Logic:**
    *   On "Create" button press, the app will:
        *   Validate the form inputs.
        *   Generate a unique random code for the project ID.
        *   Save all the new fields to a new document in the `projects` collection in Firestore.

### Part 2: Enhanced Task Creation & Display

*(To be implemented after Part 1 is complete)*

1.  **Update Task Data Model (Firestore Schema for `tasks` sub-collection):**
    *   Add the following new fields:
        *   `dueDate`: A `Timestamp` for the task's deadline.
        *   `duration`: A number or string to represent the estimated duration.

2.  **Update Task Creation UI:**
    *   When creating a new task, the user will only be able to assign it to a member of the **current project**.
    *   Add a `DatePicker` to set the task's due date.
    *   Add a field to input the estimated duration.

3.  **Update Task Display UI:**
    *   The task view (in the list and details screen) will clearly display:
        *   Who created the task.
        *   When it was created.
        *   The due date.
        *   The estimated duration.
