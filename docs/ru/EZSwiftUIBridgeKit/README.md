# EZSwiftUIBridgeKit

Удобные инструменты для встраивания UIKit/AppKit view в SwiftUI и SwiftUI view в платформенные view.

**Платформы:** iOS 13+, macOS 10.15+, tvOS 13+, visionOS

---

## Компоненты

| Тип | Описание |
|-----|----------|
| `EZUIViewWrapper` | Оборачивает `UIView`/`NSView` для использования в SwiftUI |
| `EZView.ezWrap(_:view:)` | Оборачивает SwiftUI `View` в `UIView`/`NSView` |
| `EZObservableObjectGroup` | Комбинирует несколько `ObservableObject` в один |
| `EZViewWrapperObservable` | Минимальный `ObservableObject` для ручного обновления |
| `EZView` | Кроссплатформенный typealias (`UIView` / `NSView`) |

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

- [Исходный код](../../../Sources/EZUI/EZSwiftUIBridgeKit/) — реализация модуля
