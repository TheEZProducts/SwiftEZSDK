# Xcode File Template for IMV

The template allows you to quickly create a Pack structure (Interactor + Mediator + View) in Xcode.

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

## Usage

1. In Xcode: **File -> New -> File...** (or `Cmd+N`)
2. In the templates section, find **EZSDK**
3. Select **IMV**
4. Specify the target platforms (iPhone, iPad, Mac, or combinations)
5. Enter the Pack name (e.g., `Profile`)
6. Click **Create**

---

## Generated File Structure

When creating a Pack named `Profile` with the `IPhone` platform, the following structure will be generated:

```
Profile/
├── Profile.swift        # typealias + platform View
├── ProfileI.swift       # Interactor
├── ProfileM.swift       # Mediator
└── ProfileV/
    └── ProfileIOSV.swift   # View for iOS
```

For multi-platform configurations (e.g., `IPhoneIPadMac`), Views will be created for each platform.

---

## What to Do After Creation

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

## See Also

- [Quick Start](../QuickStart/README.md) — step-by-step manual Pack creation
- [Module Main Page](../README.md) — full list of features
