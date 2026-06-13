# Nutrix Project Rules & Coding Standards

This document defines the architectural guidelines, coding standards, and project structure for the Nutrix project. All future development must strictly adhere to these rules.

## 1. Architecture: MVVM (Model-View-ViewModel)

The project follows a strict MVVM pattern with a dedicated Service layer.

### 1.1. Views (SwiftUI)
- Use `SwiftUI` for all UI components.
- Use `@ObservedObject` or `@StateObject` for the associated ViewModel.
- Avoid business logic in Views. Keep Views focused on layout and presentation.
- Use `ViewBuilder` for sub-views to keep the `body` property clean.
- Use `withAnimation` for state changes that impact the UI significantly.
- Access the router via `@EnvironmentObject var router: AppRouter`.

### 1.2. ViewModels
- Class name suffix: `ViewModel` (e.g., `LoginViewModel`).
- Inherit from `ObservableObject`.
- Use `@Published` for properties that the View needs to observe.
- Use `Combine` for data flow and bindings.
- Inject Services and the `AppRouter`.
- Handle all business logic and state management.
- Use `[weak self]` in closures to avoid memory leaks.

### 1.3. Services
- Class/Struct name suffix: `Service` or `Firebase` (e.g., `FirebaseAuthService`, `FirebaseService`).
- Use the Singleton pattern (`static let shared`).
- Handle all data persistence (Firebase) and external API calls (Gemini, Edamam, Google Vision).
- Return results via completion handlers (`Result<T, Error>`) or Combine publishers.

### 1.4. Models
- Define in `Sources/Shared/Models/`.
- Use `Codable` for Firebase/API integration.
- Use `Identifiable` for models used in lists.

## 2. Project Structure

Adhere to the following directory structure:

- `Sources/Core/`: Base utilities, Design System (AppFont, ColorApp), and global extensions.
- `Sources/Features/`: Feature-specific code organized by sub-folders.
  - `[Feature]/View/`: SwiftUI Views.
  - `[Feature]/ViewModel/`: Associated ViewModels.
- `Sources/Router/`: Navigation logic (`AppRouter`, `AppDestination`).
- `Sources/Services/`: Singleton service classes.
- `Sources/Shared/`: Reusable components and data models.
  - `Components/`: Global UI components (e.g., `TopBar`, `LoadingOverlay`).
  - `Models/`: Domain models.

## 3. Design System & UI

- **Colors:** Use `Color.App` namespace (defined in `ColorApp.swift`).
  - Example: `Color.App.primary`, `Color.App.background`, `Color.App.lightGray`.
- **Fonts:** Use `.App` font extensions (defined in `AppFont.swift`).
  - Example: `.font(.App.large)`, `.font(.App.headline)`.
- **Images:** Use `CustomImage` or system icons where appropriate.
- **Loading & Toasts:** Use `AppRouter` methods:
  - `router.showLoading()` / `router.hideLoading()`
  - `router.showToast(message: String, type: ToastType)`

## 4. Coding Style & Conventions

- **Naming:**
  - Variables and functions: `camelCase`.
  - Classes, Structs, Enums: `PascalCase`.
  - Constants: `camelCase`.
- **Organization:** Use `MARK: -` to group related methods and properties (e.g., `MARK: - Properties`, `MARK: - Methods`, `MARK: - Private Methods`).
- **Comments:** Use descriptive comments for complex logic. Use Vietnamese for UI strings but maintain English for code symbols and documentation where possible.
- **Safety:** Always use `guard let` or `if let` for unwrapping optionals. Avoid forced unwrapping (`!`).
- **Async:** Prefer Swift Concurrency (`async/await`) for new asynchronous code. For legacy code or specific requirements, use `DispatchQueue.main.async` for UI updates from background threads.

## 5. Navigation

- Navigation is managed by `AppRouter` using `NavigationPath`.
- Define destinations in `AppDestination.swift`.
- Use `router.push(.destination)` and `router.pop()` for navigation within a tab.
- Use `router.changeRoot(to: .root)` for major transitions (e.g., Splash -> Login -> Main).

## 6. Firebase Integration

- Use `FirebaseFirestoreSwift` for decoding documents directly into Models.
- Follow the existing pattern for `dateKey` and hierarchical collections under `users/{userId}/`.
- Always handle potential decoding errors when fetching documents.

## 7. Quality Assurance & Verification

- **Mandatory Compile Checks:** Every time code is modified, run a text analysis/compilation check (e.g., using `xcodebuild build` or checking Xcode directly) to ensure there are no compilation errors (`lỗi biên dịch`). Do not assume code is correct without verification.

---
*Note: This file is a living document and should be updated as the project evolves.*
