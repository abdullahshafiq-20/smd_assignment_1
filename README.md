# Group Info
- Group Name: [Insert Group Name]
- Roll Number 1: [Insert Roll Number 1]
- Roll Number 2: [Insert Roll Number 2]
- Roll Number 3: [Insert Roll Number 3]

# Folder Structure

Here is the structured overview of the lib folder along with a small explanation for each file's responsibilities:

``text
lib/
├── main.dart
├── setup.sh
├── controllers/
│   └── todo_controller.dart
├── models/
│   ├── paginated_response.dart
│   └── todo.dart
├── screens/
│   └── todo_list_screen.dart
├── services/
│   └── api_service.dart
└── widgets/
    ├── add_todo_sheet.dart
    └── todo_card.dart
``

### File Explanations

- **main.dart**: The entry point of the Flutter app. It configures the global professional light theme and runs the application.
- **setup.sh**: A shell script used for initial project setup or build automations.
- **controllers/todo_controller.dart**: State management class (ChangeNotifier) that handles all interactions (loading, adding, editing) with the API.
- **models/paginated_response.dart**: Defines the data shape for decoding paginated wrapper objects (if applicable from the API).
- **models/todo.dart**: The main data model for a Todo item, including JSON serialization methods and field types.
- **screens/todo_list_screen.dart**: The primary user interface screen that displays the feed of todos, the refresh indicator, and empty states.
- **services/api_service.dart**: Centralized network provider for HTTP requests, fetching and patching data to the backend. Includes client-side pagination logic.
- **widgets/add_todo_sheet.dart**: The custom bottom sheet UI that slides up to let users write and submit a new todo.
- **widgets/todo_card.dart**: The UI component that represents an individual Todo item cell in the list.
