# EZUIPackKit Quick Start

This guide shows how to create your first screen using the **IMV (Interactor-Mediator-View)** architecture.

---

## Table of Contents

- [IMV Architecture](#imv-architecture)
- [Creating a Pack Manually](#creating-a-pack-manually)
  - [1. Mediator](#1-mediator)
  - [2. Interactor](#2-interactor)
  - [3. View (UIKit)](#3-view-uikit)
  - [4. Combining into a Pack](#4-combining-into-a-pack)
- [Launching a Pack](#launching-a-pack)
- [SwiftUI View](#swiftui-view)
- [Transitions Between Screens](#transitions-between-screens)
- [Shared Data Between Packs](#shared-data-between-packs)
- [Common Mistakes](#common-mistakes)

---

## IMV Architecture

A **Pack** is a screen or application module consisting of three components:

| Component | Responsibility |
|-----------|----------------|
| **Interactor** | Business logic, lifecycle, navigation. Inherits from `UIViewController`. |
| **Mediator** | Stores the `ViewModel` (UI state), provides `inputI` and `inputV` interfaces for interaction. |
| **View** | UI rendering, responding to user events. |

### How Components Interact

**Important:** Interactor and View **do not have direct access** to Mediator. They interact with it only through special access objects:

```
┌─────────────┐                         ┌─────────────┐                         ┌─────────────┐
│ Interactor  │                         │  Mediator   │                         │     View    │
│             │                         │             │                         │             │
│ • logic     │                         │ • ViewModel │                         │ • UI        │
│ • navigation│   ┌─────────────────┐   │ • inputI    │   ┌─────────────────┐   │ • events    │
│             │   │     AccessI     │   │ • inputV    │   │     AccessV     │   │             │
│  access ------->│ • viewModel(RW) │-->│             │<--│ • viewModel(RW) │<------- access  │
│             │   │ • inputV(R)     │   │             │   │ • inputI(R)     │   │             │
└─────────────┘   └─────────────────┘   └─────────────┘   └─────────────────┘   └─────────────┘
```

**Access mechanism:**
- **Interactor** uses `access = ProfilePackM.accessI` to access `viewModel` and `inputV`
- **View** uses `access = ProfilePackM.accessV` to access `viewModel` and `inputI`
- **Access objects** provide **controlled access** only to specific parts of the Mediator
- **There is no direct access** to the Mediator itself from I and V -- this ensures encapsulation and safety

**Benefits of this approach:**
- Encapsulation: I and V cannot directly modify the internal state of M
- Controlled access: you can restrict which parts of M are available to each component
- Safety: access is only available after initialization (`didInitialize()`)
- Flexibility: access can be extended through `AccessMap` for additional properties

---

## Creating a Pack Manually

Let's create a simple user profile screen.

### 1. Mediator

Mediator stores state (`ViewModel`) and defines interaction interfaces. **Mediator creates access objects** (`accessI` and `accessV`) through which I and V get controlled access to its data.

```swift
import EZUIPackKit

final class ProfilePackM: EZUIPackM {
    // MARK: - ViewModel (UI state)
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        // Use @EZObservable for automatic reactivity
        // View can subscribe to changes via $userName and $isLoading
        // All subscribers are notified when these properties change
        @EZObservable var userName: String = ""
        @EZObservable var isLoading: Bool = false

        // Note: for simple cases without reactivity you can use
        // plain properties and call updateUI() manually where needed
    }

    // MARK: - InputI (interface for Interactor, called from View)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }

    // MARK: - InputV (interface for View, called from Interactor)
    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject {
        func showError(_ message: String)
    }

    // MARK: - Init
    // Free-form initializer — receives InputI and InputV directly
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }

    // MARK: - Access objects
    // These static properties create access objects for I and V
    // Interactor uses: let access = ProfilePackM.accessI
    // View uses: let access = ProfilePackM.accessV
    //
    // Access objects provide controlled access to:
    // - viewModel (read and write)
    // - inputI / inputV (read only)
    //
    // I and V have no direct access to the Mediator itself!
}
```

**Important:**
- `inputI` -- an interface whose methods are **implemented by the Interactor** and **called by the View**
- `inputV` -- an interface whose methods are **implemented by the View** and **called by the Interactor**
- `ViewModel` -- a struct containing data for display
- **`accessI` and `accessV`** -- static properties that create access objects for I and V
- **I and V do not have direct access** to the Mediator, only through these access objects

---

### 2. Interactor

Interactor contains business logic and responds to lifecycle events.

**Important:** Interactor **does not have direct access** to the Mediator. Instead, it uses the access object `access`, which provides controlled access only to `viewModel` and `inputV`.

```swift
import EZUIPackKit

final class ProfilePackI: EZUIPackI {
    // Access object to Mediator (NOT a direct reference to Mediator!)
    // Provides access only to viewModel and inputV
    // No direct access to the Mediator itself
    let access = ProfilePackM.accessI

    // MARK: - Input for Mediator
    // Returns self as InputI (default when Mediator.InputI == Self)
    // func makeInput() -> Mediator.InputI { self }

    // MARK: - Lifecycle
    func didInitialize() {
        // Called after Pack is created
    }

    func start() {
        // Called when Pack is ready to work
        fetchProfile()
    }

    func willOpen() {
        // Before open animation
    }

    func didOpen() {
        // After open animation
    }

    func willClose() {
        // Before close animation
    }

    func didClose() {
        // After close animation
    }

    // MARK: - Business logic
    private func fetchProfile() {
        // Access viewModel via access (NOT directly to Mediator!)
        // access.viewModel is controlled access to ViewModel in Mediator
        // Changing @EZObservable properties automatically notifies subscribers
        // Plain assignment via wrappedValue automatically triggers notifications
        access.viewModel.isLoading = true

        // Simulate loading
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            access.viewModel.userName = "John Doe"
            access.viewModel.isLoading = false
        }
    }
}

// MARK: - InputIProtocol
extension ProfilePackI: ProfilePackM.InputIProtocol {
    func loadProfile() {
        fetchProfile()
    }

    func logout() {
        // Dismiss current screen
        ezTransit.dismiss().animate().transit()
    }
}
```

---

### 3. View (UIKit)

View is responsible for UI rendering.

**Important:** View **does not have direct access** to the Mediator. Instead, it uses the access object `access`, which provides controlled access only to `viewModel` and `inputI`.

```swift
import UIKit
import EZUIPackKit

final class ProfilePackV: EZUIPackV {
    // Access object to Mediator (NOT a direct reference to Mediator!)
    // Provides access only to viewModel and inputI
    // No direct access to the Mediator itself
    let access = ProfilePackM.accessV

    // MARK: - UI Elements
    private let nameLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let logoutButton = UIButton(type: .system)

    // MARK: - Input for Mediator
    // Returns self as InputV (default when Mediator.InputV == Self)
    // func makeInput() -> Mediator.InputV { self }

    // MARK: - Creating UI
    func create() {
        view.backgroundColor = .systemBackground

        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        logoutButton.setTitle("Log out", for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20)
        ])
    }

    // MARK: - Lifecycle
    /// Called after Mediator is created and connected, but BEFORE `create()`.
    ///
    /// **Important:** Access object is only available after `didInitialize()`.
    /// Use this method for:
    /// - Subscribing to viewModel changes
    /// - Setup that requires access to Mediator
    /// - Initializing observers
    func didInitialize() {
        // Subscribe to viewModel changes for automatic UI updates
        // Access viewModel via access (NOT directly to Mediator!)
        // Use $userName and $isLoading (projected values from @EZObservable)
        access.viewModel.$userName.add { [weak self] _ in
            self?.updateUI()
        }

        access.viewModel.$isLoading.add { [weak self] _ in
            self?.updateUI()
        }
    }

    func willOpen() {
        // Prepare for screen appearance
    }

    func animateOpen() {
        // Called in the context of transition animation to the screen
    }

    func didOpen() {
        // View has fully appeared and is ready
    }

    func didInstall() {
        // Layout completed
    }

    func willClose() {
        // Prepare for screen disappearance
    }


    func animateClose() {
        // Called in the context of transition animation from the screen
    }

    func didClose() {
        // View has fully disappeared, can release resources
    }


    func viewDidLoad() {
        // Additional setup after View is loaded
    }

    func viewWillAppear(_ animated: Bool) {
        // Prepare before appearance
    }

    func viewDidAppear(_ animated: Bool) {
        // Actions after appearance
    }

    func viewWillDisappear(_ animated: Bool) {
        // Prepare before disappearance
    }

    func viewDidDisappear(_ animated: Bool) {
        // Actions after disappearance
    }

    // MARK: - UI update
    private func updateUI() {
        // Access viewModel via access (NOT directly to Mediator!)
        // access.viewModel is controlled access to ViewModel in Mediator
        nameLabel.text = access.viewModel.userName

        if access.viewModel.isLoading {
            loadingIndicator.startAnimating()
            nameLabel.isHidden = true
        } else {
            loadingIndicator.stopAnimating()
            nameLabel.isHidden = false
        }
    }

    // MARK: - Actions
    @objc private func logoutTapped() {
        // Access inputI via access (NOT directly to Mediator!)
        // access.inputI is controlled access to InputI in Mediator
        access.inputI?.logout()
    }
}

// MARK: - InputVProtocol
extension ProfilePackV: ProfilePackM.InputVProtocol {
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        packBridge.pack?.interactor?.present(alert, animated: true)
    }
}
```

---

### 4. Combining into a Pack

**Option A — typealias (compact):**

```swift
import EZUIPackKit

typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
```

**Option B — enum factory (flexible, allows custom parameters):**

```swift
import EZUIPackKit

enum ProfilePack {
    @MainActor
    static func make() -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { ProfilePackV() }
        )
    }
}
```

Done! Now `ProfilePack` is a fully functional screen.

Both approaches support the same `.make()` API below.

---

## Launching a Pack

### As Root Controller

```swift
import UIKit
import EZUIPackKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        // Option A (typealias):
        window?.rootViewController = ProfilePack.make(
            interactor: { ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { ProfilePackV() }
        )

        // Option B (enum factory):
        window?.rootViewController = ProfilePack.make()

        window?.makeKeyAndVisible()
    }
}
```

### Modal Presentation

```swift
let interactor = ProfilePack.make()
present(interactor, animated: true)
```

### Push in NavigationController

```swift
let interactor = ProfilePack.make()
navigationController?.pushViewController(interactor, animated: true)
```

### Using the Transition System

```swift
// From any UIViewController
ezTransit.present(ProfilePack.make()).animate().transit()

// Or navigation push
ezTransit.navigationPush(ProfilePack.make()).animate().transit()
```

---

## SwiftUI View

If you prefer SwiftUI, use `EZUIPackSV`:

**Important:** The SwiftUI View also **does not have direct access** to the Mediator and uses the same `access` object as the UIKit View (`let access = M.accessV`). When the view model conforms to `ObservableObject`, the stored access acts as a `DynamicProperty` — it registers the view as a SwiftUI dependency of the view model, so updates are delivered at the point of use.

```swift
import SwiftUI
import EZUIPackKit

struct ProfileSwiftUIPackV: EZUIPackSV {
    // Access object to Mediator (NOT a direct reference to Mediator!)
    // Provides access only to viewModel and inputI
    // No direct access to the Mediator itself
    let access = ProfilePackM.accessV

    // For SwiftUI View we use a struct with closures instead of a protocol,
    // because SwiftUI View is a struct and cannot be weak
    func makeInput() -> Mediator.InputV {
        .init(
            showError: { message in
                // Handle error
                print("Error: \(message)")
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // Access viewModel via access (NOT directly to Mediator!)
            if access.viewModel.isLoading {
                ProgressView()
            } else {
                Text(access.viewModel.userName)
                    .font(.title)
            }

            Button("Log out") {
                // Access inputI via access (NOT directly to Mediator!)
                access.inputI?.logout()
            }
        }
    }
}
```

**Important for SwiftUI:** since a SwiftUI View is a `struct`, it cannot be `weak`. Therefore, `InputV` is best defined as a struct with closures:
If ViewModel conforms to `ObservableObject`, SwiftUI will automatically update the View on changes. There is also support for EZObservable -- they behave the same way as @Published if you call the `snapEZObservable()` method. In this case, the View itself does not need any additional declarations; everything will update automatically.

```swift
import EZUIPackKit

final class ProfileSwiftUIPackM: EZUIPackM {
    // MARK: - ViewModel
    var viewModel: ViewModel
    @MainActor class ViewModel: ObservableObject {
        @Published var userName: String = ""
        @EZObservable var isLoading: Bool = false

        init() { snapEZObservable() }
    }

    // MARK: - InputI (protocol, because Interactor is a class)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }

    // MARK: - InputV (struct with closures, because SwiftUI View is a struct)
    let inputV: InputV
    @MainActor struct InputV {
        var showError: (String) -> Void
    }

    // MARK: - Init
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

**How it works:**
- `@EZObservable` creates observable properties with a `$propertyName` projection for subscribing
- `snapEZObservable($userName, $isLoading)` subscribes to changes and calls `objectWillChange.send()` on each change
- SwiftUI automatically updates the View when `ObservableObject` changes
- Subscriptions are automatically removed when `ObservableObject` is deallocated thanks to `snapToObject(self)`

---

## Transitions Between Screens

### Navigation

```swift
// Push
ezTransit.navigationPush(OtherPack.make()).animate().transit()

// Pop
ezTransit.navigationPop().animate().transit()

// Pop to root
ezTransit.navigationPopToRoot().animate().transit()
```

### Modal

```swift
// Present
ezTransit.present(OtherPack.make())
    .presentationStyle(.fullScreen)
    .animation(.coverVertical)
    .transit()

// Dismiss
ezTransit.dismiss().animate().transit()
```

### Tab Bar

```swift
// Select by index
ezTransit.tabBarSelect(1).animate().transit()

// Next tab
ezTransit.tabBarNext().animate().transit()

// Previous tab
ezTransit.tabBarBack().animate().transit()
```

### Custom Transitions

```swift
// Via transitionController
ezTransit.custom()
    .transitionType(.ezOpen)
    .animate()
    .transit()
```

---

## Shared Data Between View Controllers

Use `EZSharedStorage` to pass data between a parent and its child view controllers. Works with any `UIViewController` that implements the `EZSharingProtocol` protocol.

### Defining Keys

```swift
// 1. Define keys for shared storage view controller
extension EZSharedKeyChain<OnboardingViewController> {
    var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
    var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
}

// 2. Create static var for convenient access to the chain
extension EZSharedKey {
    static var onboardingChain: EZSharedKeyChain<OnboardingViewController> { .init() }
}
```

### In the Parent View Controller

```swift
// Any UIViewController that implements EZSharingProtocol
class OnboardingViewController: UIViewController, EZSharingProtocol {
    var shared: EZSharedStorage? {
        .init([
            .init(key: .onboardingChain.onboardingStatus, value: currentStatus),
            .init(key: .onboardingChain.onboardingActions, value: actions)
        ])
    }
}
```

### In the Child View Controller

```swift
class OnboardingStepViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Get data from parent (hierarchy is already built)
        if let status = ezParentShared[.onboardingChain.onboardingStatus] {
            // Use onboarding status from parent
        }

        // Call parent actions
        ezParentShared[.onboardingChain.onboardingActions]?.next()
    }
}
```

### In a Pack Interactor (Convenience)

If you are using the Pack API, `EZUIPackInteractorProtocol` already provides the `shared` property:

```swift
final class OnboardingPackI: EZUINavigationPackI {
    var shared: EZSharedStorage? {
        .init([
            .init(key: .onboardingChain.onboardingStatus, value: currentStatus),
            .init(key: .onboardingChain.onboardingActions, value: actions)
        ])
    }
}
```

---

## Next Steps

- [Template Installation](../Templates/README.md) — automatic Pack generation
- [Module Main Page](../README.md) — full list of features
