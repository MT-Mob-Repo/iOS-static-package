# Static Packages — iOS

iOS implementation of **Almatar Static Packages**.

A **Static Package** is a predefined combination of two or more travel components (flights, hotels, cars, experiences, and add-ons) sold to the customer as a single package.

---

## Requirements

| Tool    | Version |
|---------|---------|
| Xcode   | 15.2+   |
| Swift   | 5.8+    |
| iOS     | 16.0+   |

---

## Tech Stack

- Swift
- SwiftUI
- MVVM + Repository Pattern
- Clean Architecture principles

---

## Supported Components

A package contains **two or more** of the following components:

- Flight
- Hotel
- Car
- Ticket / Experience
- Add-ons

Each component is either **mandatory** or **optional**:

| Type      | Description                                                              |
|-----------|--------------------------------------------------------------------------|
| Mandatory | Included in the package price and cannot be removed by the customer.     |
| Optional  | Not included by default; the customer can add it, which updates the price. |

---

## Customer Flow

```
Package Card (Landing Page)
    ↓
Package Details (includes Traveller Selection)
    ↓
Payment
    ↓
Booking Confirmation
```

| Step                 | Description                                                         |
|----------------------|---------------------------------------------------------------------|
| Package Card         | Displayed on the Landing Page; tapping it opens the Package Details. |
| Package Details      | Shows the package content and components. Traveller Selection is done inside this screen. |
| Payment              | The customer completes payment for the package.                     |
| Booking Confirmation | Displays the confirmed booking details.                             |

---

## Architecture

The feature follows **MVVM** with the **Repository Pattern**, organized by Clean Architecture layers.

```
View  →  ViewModel  →  Repository (protocol)  →  Data Source (API / Local)
```

- **View** — SwiftUI UI only. No business logic.
- **ViewModel** — Owns all state and presentation logic; talks to repositories through protocols.
- **Repository** — Abstracts every data source (remote API or local storage) behind a protocol.
- **Model** — Domain and DTO models.

### Project Structure

```
StaticPackage
├── Core            # Shared utilities, extensions, constants
├── Data
│   ├── Network     # API endpoints, requests, DTOs
│   ├── Models      # Domain models
│   └── Repositories# Repository protocols & implementations
├── Features        # Feature-based modules (one folder per screen/flow)
│   └── <Feature>
│       ├── Views
│       └── ViewModels
└── Resources       # Localizable strings, assets
```

---

## Configuration

Package data is configured and provided by the **backend**.
The iOS app consumes this configuration to display:

- Package details and included components
- Mandatory vs. optional components and pricing
- Traveller options
- Payment
- Booking confirmation

No package content should be hardcoded in the app.

---

## Coding Standards

- Write clean, readable, and maintainable code.
- No business logic in Views — ViewModels handle all state and logic.
- Use **protocols** for all Repository interfaces (enables mocking and testing).
- Always use `[weak self]` in escaping closures to avoid retain cycles.
- Handle all error cases explicitly — no silent failures.
- No hardcoded strings — use constants, enums, and localized strings.
- **Arabic localization (RTL) support is required** for every screen.
- Code comments are written in **English**.

---

## Development Guidelines

When implementing the feature:

- Follow the existing Almatar iOS architecture and coding standards.
- Reuse existing **traveller, payment, booking, localization, and analytics** components where applicable.
- Keep package-specific logic isolated and reusable.
