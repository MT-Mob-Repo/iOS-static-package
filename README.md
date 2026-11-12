# Static Packages — iOS

iOS implementation of **Almatar Static Packages**.

A **Static Package** is a predefined combination of two or more travel components (flights, hotels, cars, experiences, and add-ons) sold to the customer as a single package.

---

## Requirements

| Tool    | Version |
|---------|---------|
| Xcode   | 15.2+   |
| Swift   | 5.9+    |
| iOS     | 16.0+   |

Dependencies (Swift Package Manager):

| Package | Version |
|---------|---------|
| [AlmatarSystemDesignSDK](https://github.com/MT-Mob-Repo/iOS-Almatar-System-Design-SDK) | 1.0.9+ (up to next major) |

---

## Installation

Add the package with Swift Package Manager (**File → Add Package Dependencies…**) and link the `AlmatarStaticPackageSDK` product to the app target.

The host app must also provide what the design system reads from the app itself:

- **Colors** — the `AlmatarColors` asset catalog in the app's main bundle (colors are loaded with `Color(name, bundle: .main)`).
- **Fonts** — the Almatar fonts (`regular_font`, `medium-font`, `semibold_font`, `bold_font`, …) registered at launch.

The [Example app](#example-app) shows both.

---

## Integration

### 1. Configure the SDK at launch

```swift
import AlmatarStaticPackageSDK

let sdk = AlmatarStaticPackageSDK.shared

sdk.configure(StaticPackageConfiguration(
    baseURL: "https://…",
    language: .english,            // .english or .arabic; the screens follow it, including RTL
    brand: "Almatar",              // sent as the `x-brand` header
    deviceId: UIDevice.current.identifierForVendor?.uuidString,
    currency: "SAR",               // the user's selected currency
    availableCurrencies: [],       // the app's currency list, used to format prices
    useMockData: false             // true serves the bundled mock JSON instead of the API
))

// The logged-in user's token, sent as `Authorization: Bearer …`; return nil for guests.
sdk.setTokenProvider { await session.accessToken }

// Optional extra headers for every request.
sdk.setHeadersProvider { ["x-app-version": appVersion] }
```

Settings can be changed later with `setLanguage(_:)`, `setCurrency(_:)`, `setAvailableCurrencies(_:)` and `setBaseURL(_:)`.

### 2. Show the screens

| Method | Screen |
|--------|--------|
| `getPackagesListView(section:)` | Package cards for a section the app provides. **Book** creates a cart and pushes the Package Details, so the view must be inside a `NavigationStack`. |
| `getStaticPackageDetailsView(packageId:cartId:)` | Package Details, for apps that open it themselves. |
| `presentPackageBookingConfirmation(id:)` | Presents the Booking Confirmation full screen on top of everything. The SDK calls it after a successful payment. |
| `getPackageBookingConfirmationView(id:)` | The Booking Confirmation as a view, for apps that show it themselves. |

### 3. Handle payment and navigation

```swift
// Runs the app's payment flow when the user taps "Go to payment".
// The SDK holds the delegate weakly, so keep a strong reference to it.
sdk.delegate = paymentHandler

sdk.onGoToMyTrips = { /* open My Trips */ }
sdk.onBackToHome = { /* go back to Home */ }
sdk.onViewReceipt = { orderId in /* open the receipt; the button is hidden while this is nil */ }
sdk.onDismiss = { /* close the package flow */ }
```

`paymentHandler` conforms to `AlmatarStaticPackageSDKProtocol`. In `startPayment(bookingId:paymentId:amountInSar:productType:cancellationTiers:completion:)` it opens the payment screen and calls `completion` with `.success(.success)`, `.success(.pending)`, `.success(.failed)` or `.failure(…)`. On success the SDK presents the Booking Confirmation.

---

## Example App

`Example/` contains **AlmatarStaticPackagesDemo**, a small app that uses the SDK from this folder (a local package reference to `..`), so changes to the SDK show up in it right away.

1. Open `Example/AlmatarStaticPackagesDemo.xcodeproj`.
2. Select the **MyApp** scheme and a simulator, then run.

It shows how to:

- configure the SDK and the token provider (`AppDelegate.swift`);
- switch the language between English and Arabic (`HomeView.swift`);
- show the packages list inside a `NavigationStack`, using a sample `PackagesSection`;
- present the Booking Confirmation;
- provide the colors (`AlmatarColors.xcassets`) and register the fonts (`Extensions/AlmatarFonts.swift`).

To try the screens without the API, set `useMockData: true` in `AppDelegate.swift`.

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
Example             # Demo app using the SDK through a local package reference
Sources/AlmatarStaticPackageSDK
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
