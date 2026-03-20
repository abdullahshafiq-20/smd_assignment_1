# Group Info
- Group Number : 09
- Roll Number 1: 22k-4489
- Roll Number 2: 22k-4614
- Roll Number 3: 22p-9187

# Folder Structure


```
├── 📁 controllers
│   └── 📄 todo_controller.dart
├── 📁 models
│   ├── 📄 paginated_response.dart
│   └── 📄 todo.dart
├── 📁 screens
│   └── 📄 todo_list_screen.dart
├── 📁 services
│   └── 📄 api_service.dart
├── 📁 widgets
│   ├── 📄 add_todo_sheet.dart
│   └── 📄 todo_card.dart
└── 📄 main.dart
```

### File Explanations

- **main.dart**: The entry point of the Flutter app. It configures the global professional light theme and runs the application.
- **controllers/todo_controller.dart**: State management class (ChangeNotifier) that handles all interactions (loading, adding, editing) with the API.
- **models/paginated_response.dart**: Defines the data shape for decoding paginated wrapper objects (if applicable from the API).
- **models/todo.dart**: The main data model for a Todo item, including JSON serialization methods and field types.
- **screens/todo_list_screen.dart**: The primary user interface screen that displays the feed of todos, the refresh indicator, and empty states.
- **services/api_service.dart**: Centralized network provider for HTTP requests, fetching and patching data to the backend. Includes client-side pagination logic.
- **widgets/add_todo_sheet.dart**: The custom bottom sheet UI that slides up to let users write and submit a new todo.
- **widgets/todo_card.dart**: The UI component that represents an individual Todo item cell in the list.
