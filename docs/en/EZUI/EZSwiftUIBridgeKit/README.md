# EZSwiftUIBridgeKit

Convenient tools to embed UIKit/AppKit views in SwiftUI and embed SwiftUI views into platform views.

**Platforms:** iOS 13+, macOS 10.15+, tvOS 13+, visionOS

---

## Components

| Type | Description |
|------|-------------|
| `EZUIViewWrapper` | Wraps a `UIView`/`NSView` for use in SwiftUI |
| `EZViewControllerWrapper` | Wraps a `UIViewController`/`NSViewController` for use in SwiftUI |
| `EZView.ezWrap(_:view:)` | Wraps a SwiftUI `View` into a `UIView`/`NSView` |
| `View.ezHostingController()` | Wraps a SwiftUI `View` into a `UIHostingController`/`NSHostingController` |
| `EZObservableObjectGroup` | Combines multiple `ObservableObject`s into one |
| `EZViewWrapperObservable` | Minimal `ObservableObject` for manual refresh triggers |
| `EZView` | Cross-platform typealias (`UIView` / `NSView`) |
| `EZViewController` | Cross-platform typealias (`UIViewController` / `NSViewController`) |

---

## UIKit/AppKit View in SwiftUI

Use `EZUIViewWrapper` to embed a platform view inside a SwiftUI hierarchy:

```swift
import SwiftUI
import EZSwiftUIBridgeKit

struct ContentView: View {
    var body: some View {
        EZUIViewWrapper({
            let label = UILabel()
            label.textAlignment = .center
            return label
        }) { label in
            label.text = "Hello from UIKit"
        }
        .frame(height: 44)
    }
}
```

Or with an existing view instance:

```swift
let mapView = MKMapView()
let wrapped = EZUIViewWrapper(mapView) { map in
    map.showsUserLocation = true
}
```

---

## SwiftUI View in UIKit/AppKit

Use `EZView.ezWrap(_:view:)` to embed a SwiftUI view into a platform view:

```swift
import EZSwiftUIBridgeKit

@MainActor
final class VM: ObservableObject {
    @Published var count = 0
}

let vm = VM()
let platformView: EZView = EZView.ezWrap(vm) { vm in
    Text("Count: \(vm.count)")
}
// Add `platformView` to your UIKit/AppKit hierarchy
```

Without an observable (uses the built-in `EZViewWrapperObservable`):

```swift
let view = EZView.ezWrap { _ in
    Text("Static content")
}
```

To refresh manually:

```swift
let driver = EZViewWrapperObservable()
let view = EZView.ezWrap(driver) { _ in
    Text("Hello")
}

// Later, force a SwiftUI refresh:
driver.update()
```

---

## UIViewController/NSViewController in SwiftUI

Use `EZViewControllerWrapper` to embed a view controller inside a SwiftUI hierarchy:

```swift
import SwiftUI
import EZSwiftUIBridgeKit

struct ContentView: View {
    var body: some View {
        EZViewControllerWrapper(UIImagePickerController())
    }
}
```

With a factory closure and update handler:

```swift
EZViewControllerWrapper({
    let nav = UINavigationController()
    return nav
}, update: { nav in
    nav.isNavigationBarHidden = true
})
```

---

## SwiftUI View as ViewController

Use `.ezHostingController()` to turn any SwiftUI view into a `UIHostingController`/`NSHostingController`:

```swift
let vc = Text("Hello").ezHostingController()
navigationController?.pushViewController(vc, animated: true)
```

---

## Multi-Object Observation

`EZObservableObjectGroup` forwards `objectWillChange` from multiple `ObservableObject`s:

```swift
@MainActor
final class A: ObservableObject { @Published var value = 0 }
@MainActor
final class B: ObservableObject { @Published var text = "" }

let group = EZObservableObjectGroup(A(), B())
// Use `group` as a single ObservableObject dependency
```

---

## Useful Links

- [Source Code](../../../../Sources/EZUI/EZSwiftUIBridgeKit/) — module implementation
