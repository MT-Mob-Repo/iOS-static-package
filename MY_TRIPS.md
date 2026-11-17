# My Trips — Static Packages

> Added in commit `50e36a0` — *Expose package My Trips APIs and views*.

The SDK can show the user's **package bookings** in My Trips. A host app can use it in two ways:

- **Use the full screen.** The SDK's My Trips screen has Upcoming / Past tabs, a card per booking, and the booking confirmation when a card is tapped.
- **Merge into its own list.** The app fetches the package trips and shows the SDK's card inside its own My Trips list.

All of these screens use the same setup as the rest of the SDK:

- the shared `defaultToolbar` back button and title
- the `AlmatarSystemDesignSDK` colors, spacing, typography and corner radius
- `NetworkClient` with the configured token and headers providers
- the configured language, including RTL

See the main [README](README.md) for installation and setup.

---

## Public API

All methods are on `AlmatarStaticPackageSDK.shared`.

| Method | Returns | Use |
|--------|---------|-----|
| `fetchPackageTrips(timeframe:offset:limit:years:)` | `PackageTripsPage` | Loads one page of bookings, for apps that build their own list. |
| `getPackageTripsView()` | `some View` | The full My Trips screen. It must be inside a `NavigationStack`. |
| `getPackageTripCardView(trip:isPast:onTap:)` | `some View` | The card for one booking. |
| `getPackageTripConfirmationView(orderId:onBack:)` | `some View` | The booking confirmation opened from My Trips, with the SDK toolbar. |

### `fetchPackageTrips(timeframe:offset:limit:years:)`

```swift
public func fetchPackageTrips(
    timeframe: PackageTripTimeframe,   // .upcoming or .previous
    offset: Int = 0,                   // number of trips already loaded
    limit: Int = 10,                   // page size
    years: [Int]? = nil                // .previous only: booking years to filter by
) async throws -> PackageTripsPage
```

It throws when the SDK is not configured, the request fails, or the response can't be decoded. On API errors, `NetworkError.apiMessages` holds the server's messages.

### `getPackageTripsView()`

The full screen:

- **Upcoming / Past tabs**, with loading, error (with a retry), empty and list states.
- **Paging** (10 trips per page) and pull to refresh.
- **Card taps** push the booking confirmation.
- **Back button** dismisses the screen, through the shared toolbar.

### `getPackageTripCardView(trip:isPast:onTap:)`

| Parameter | Description |
|-----------|-------------|
| `trip` | A `PackageTrip` from `fetchPackageTrips`. |
| `isPast` | `true` in the past-trips list. The badge then reads **Past** instead of the booking status. |
| `onTap` | Called when the card is tapped, for example to open `getPackageTripConfirmationView`. |

The card shows the package title and travellers, plus a status badge:

| Status | Badge color |
|--------|-------------|
| Confirmed | green |
| Pending, partially confirmed | yellow |
| Failed, cancelled | red |
| Past | gray |

Below the header it shows each product in the package:

- **Flights:** the route, flight numbers, and each leg's times, airline logo and stops.
- **Hotels:** check-in and check-out dates, rooms and nights.
- **Activities.**

### `getPackageTripConfirmationView(orderId:onBack:)`

The booking confirmation, with the toolbar titled **Confirmation**.

| Action | Behavior |
|--------|----------|
| Back / **Go to My Trips** | Calls `onBack`. When `onBack` is `nil`, the screen dismisses itself, which pops it from a SwiftUI `NavigationStack`. |
| **Back to Home** | Calls `sdk.onBackToHome`. |

Pass `onBack` when the app pushes the view with UIKit (for example, with a `UIHostingController` on a `UINavigationController`).

---

## Usage

### Full screen (SwiftUI)

```swift
NavigationStack {
    HomeView()
        .navigationDestination(isPresented: $showMyTrips) {
            AlmatarStaticPackageSDK.shared.getPackageTripsView()
        }
}
```

### Merging package trips into the app's My Trips

```swift
let sdk = AlmatarStaticPackageSDK.shared

let page = try await sdk.fetchPackageTrips(timeframe: .upcoming, offset: 0, limit: 10)

ForEach(page.trips) { trip in
    sdk.getPackageTripCardView(trip: trip, isPast: false) {
        selectedOrderId = trip.orderId
    }
}
```

Load the next page when `trips.count < page.total`, passing `offset: trips.count`.

### Opening the confirmation from UIKit

```swift
let view = AlmatarStaticPackageSDK.shared.getPackageTripConfirmationView(orderId: trip.orderId) { [weak nav] in
    nav?.popViewController(animated: true)
}
nav.pushViewController(UIHostingController(rootView: view), animated: true)
```

---

## Models

| Type | Description |
|------|-------------|
| `PackageTripTimeframe` | `.upcoming` or `.previous`. |
| `PackageTripsPage` | `trips`, `total`, `page`, `limit` and `totalPages`. |
| `PackageTrip` | One booking: `orderId`, `bookingReference`, `status`, `bookedAt`, `travellersCount` and `paymentStatus`. Computed fields: `title`, `destination`, `imageUrl`, `startDate`, `endDate`, `priceAmount`, `priceCurrency`, `departureDate` and `tripStatus`. |
| `PackageTripStatus` | `.confirmed`, `.partiallyConfirmed`, `.pending`, `.failed` or `.cancelled`. `confirmed` and `payment_confirmed` map to `.confirmed`. Unknown values map to `.pending`. |

Decoding is lenient. A product that can't be decoded is skipped rather than failing the whole page. `stops` is accepted either as a number or as a list of stops.

---

## API

```
GET {baseURL}/api/v1/packages/orders?timeframe=upcoming|previous&limit=10&offset=0[&year=2025,2026]
```

`year` is sent only for `previous`.

Response:

```json
{
  "status": 200,
  "data": {
    "data": [ { "orderId": "…", "status": "confirmed", "package": { … }, "sections": { … } } ],
    "total": 2,
    "page": 1,
    "limit": 10,
    "totalPages": 1
  }
}
```

With `useMockData: true`, the request is served from `Resources/Mocks/package_trips.json`.

---

## Localization

The texts use keys under `package_trips.*` in `Localizable.xcstrings`, in English and Arabic. Examples:

- `package_trips.title`
- `package_trips.upcoming` and `package_trips.past`
- `package_trips.status_confirmed`
- `package_trips.travellers_count`

---

## Example App

`HomeView.swift` in the demo has an **Open My Trips (packages)** button that pushes `getPackageTripsView()`.

---

## Files

| File | Role |
|------|------|
| `AlmatarStaticPackageSDK.swift` | The public My Trips methods. |
| `Data/Models/PackageTrip.swift` | Trip models and decoding. |
| `Data/Repositories/StaticPackagesRepository.swift` | `fetchPackageTrips` and the `packageTrips` endpoint. |
| `Data/Network/Mock/MockURLProtocol.swift` | The mock route for `package_trips`. |
| `Features/PackageTrips/ViewModels/PackageTripsViewModel.swift` | Tabs, paging and loading state. |
| `Features/PackageTrips/ViewModels/PackageTripCardModel.swift` | Maps a trip to the card's texts (route, stops, nights, dates). |
| `Features/PackageTrips/Views/PackageTripsView.swift` | The My Trips screen. |
| `Features/PackageTrips/Views/PackageTripCardView.swift` | The trip card. |
| `Features/PackageTrips/Views/PackageTripConfirmationView.swift` | The confirmation screen opened from My Trips. |
| `Core/Localization/LocalizedKey.swift` and `Resources/Localizable.xcstrings` | The `package_trips.*` strings. |
| `Resources/Mocks/package_trips.json` | Mock bookings. |
