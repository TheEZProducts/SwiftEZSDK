# EZSwiftUIBridgeKit

Удобные инструменты для встраивания UIKit/AppKit view в SwiftUI и SwiftUI view в платформенные view.

**Платформы:** iOS 13+, macOS 10.15+, tvOS 13+, visionOS

---

## Компоненты

| Тип | Описание |
|-----|----------|
| `EZUIViewWrapper` | Оборачивает `UIView`/`NSView` для использования в SwiftUI |
| `EZViewControllerWrapper` | Оборачивает `UIViewController`/`NSViewController` для использования в SwiftUI |
| `EZView.ezWrap(_:view:)` | Оборачивает SwiftUI `View` в `UIView`/`NSView` |
| `View.ezHostingController()` | Оборачивает SwiftUI `View` в `UIHostingController`/`NSHostingController` |
| `EZObservableObjectGroup` | Комбинирует несколько `ObservableObject` в один |
| `EZViewWrapperObservable` | Минимальный `ObservableObject` для ручного обновления |
| `EZView` | Кроссплатформенный typealias (`UIView` / `NSView`) |
| `EZViewController` | Кроссплатформенный typealias (`UIViewController` / `NSViewController`) |

---

## UIKit/AppKit View в SwiftUI

Используйте `EZUIViewWrapper` для встраивания платформенного view в SwiftUI:

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

Или с существующим экземпляром view:

```swift
let mapView = MKMapView()
let wrapped = EZUIViewWrapper(mapView) { map in
    map.showsUserLocation = true
}
```

---

## SwiftUI View в UIKit/AppKit

Используйте `EZView.ezWrap(_:view:)` для встраивания SwiftUI view в платформенный view:

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
// Добавьте `platformView` в вашу UIKit/AppKit иерархию
```

Без observable (используется встроенный `EZViewWrapperObservable`):

```swift
let view = EZView.ezWrap { _ in
    Text("Статический контент")
}
```

Для ручного обновления:

```swift
let driver = EZViewWrapperObservable()
let view = EZView.ezWrap(driver) { _ in
    Text("Hello")
}

// Позже принудительно обновить SwiftUI:
driver.update()
```

---

## UIViewController/NSViewController в SwiftUI

Используйте `EZViewControllerWrapper` для встраивания view controller в SwiftUI:

```swift
import SwiftUI
import EZSwiftUIBridgeKit

struct ContentView: View {
    var body: some View {
        EZViewControllerWrapper(UIImagePickerController())
    }
}
```

С фабрикой и обработчиком обновления:

```swift
EZViewControllerWrapper({
    let nav = UINavigationController()
    return nav
}, update: { nav in
    nav.isNavigationBarHidden = true
})
```

---

## SwiftUI View как ViewController

Используйте `.ezHostingController()` чтобы превратить любой SwiftUI view в `UIHostingController`/`NSHostingController`:

```swift
let vc = Text("Hello").ezHostingController()
navigationController?.pushViewController(vc, animated: true)
```

---

## Наблюдение за несколькими объектами

`EZObservableObjectGroup` пробрасывает `objectWillChange` от нескольких `ObservableObject`:

```swift
@MainActor
final class A: ObservableObject { @Published var value = 0 }
@MainActor
final class B: ObservableObject { @Published var text = "" }

let group = EZObservableObjectGroup(A(), B())
// Используйте `group` как единый ObservableObject
```

---

## Полезные ссылки

- [Исходный код](../../../../Sources/EZUI/EZSwiftUIBridgeKit/) — реализация модуля
