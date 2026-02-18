# Xcode File Templates for IMV

Templates for quickly creating Pack structures (Interactor + Mediator + View) in Xcode.

Two templates are available:
- **IMV** — UIKit pack (EZUIPackKit)
- **SUI IMV** — SwiftUI pack (EZSUIPackKit)

---

## Installation

1. Navigate to the repository root and copy the templates folder to the Xcode directory:

```bash
# From the SwiftEZSDK repository root:
cp -R "File Templates/EZSDK" ~/Library/Developer/Xcode/Templates/
```

Or create the directory if it doesn't exist:

```bash
mkdir -p ~/Library/Developer/Xcode/Templates/
cp -R "File Templates/EZSDK" ~/Library/Developer/Xcode/Templates/
```

2. Restart Xcode

---

## UIKit Template (IMV)

### Usage

1. In Xcode: **File -> New -> File...** (or `Cmd+N`)
2. In the templates section, find **EZSDK**
3. Select **IMV**
4. Specify the target platforms (iPhone, iPad, Mac, or combinations)
5. Enter the Pack name (e.g., `Profile`)
6. Click **Create**

### Generated File Structure

When creating a Pack named `Profile` with the `IPhone` platform:

```
Profile/
├── Profile.swift        # enum factory + platform View
├── ProfileI.swift       # Interactor (UIViewController)
├── ProfileM.swift       # Mediator
└── ProfileV/
    └── ProfileIOSV.swift   # View for iOS (UIView)
```

For multi-platform configurations (e.g., `IPhoneIPadMac`), Views will be created for each platform.

### What to Do After Creation

1. Open `*M.swift` (Mediator) and add:
   - Properties to `ViewModel`
   - Methods to `InputIProtocol` and `InputVProtocol`

2. Open `*I.swift` (Interactor) and:
   - Implement lifecycle methods
   - Add business logic
   - Implement `InputIProtocol`

3. Open `*V.swift` (View) and:
   - Create the UI in the `create()` method
   - Implement `InputVProtocol`

---

## SwiftUI Template (SUI IMV)

### Usage

1. In Xcode: **File -> New -> File...** (or `Cmd+N`)
2. In the templates section, find **EZSDK**
3. Select **SUI IMV**
4. Enter the Pack name (e.g., `Profile`)
5. Click **Create**

### Generated File Structure

When creating a Pack named `Profile`:

```
Profile/
├── Profile.swift        # enum factory returning some View
├── ProfileI.swift       # Interactor (plain class)
├── ProfileM.swift       # Mediator with ObservableObject ViewModel
└── ProfileV.swift       # View (SwiftUI)
```

### What to Do After Creation

1. Open `*M.swift` (Mediator) and add:
   - `@Published` properties to `ViewModel`
   - Methods to `InputIProtocol`

2. Open `*I.swift` (Interactor) and:
   - Implement `start()`, `onAppear()`, `onDisappear()`
   - Add business logic
   - Implement `InputIProtocol`

3. Open `*V.swift` (View) and:
   - Build the UI in `body`
   - Use `viewModel` for state and `inputI` for actions

---

## See Also

- [EZUIPackKit Quick Start](../QuickStart/README.md) — step-by-step UIKit Pack creation
- [EZSUIPackKit Quick Start](../../EZSUIPackKit/QuickStart/README.md) — step-by-step SwiftUI Pack creation
