# EZSUIPackKit

Модуль SwiftUI для построения UI по архитектуре **IMV (Interactor-Mediator-View)**. Обеспечивает то же разделение логики, состояния и представления, что и EZUIPackKit, но с нативными SwiftUI компонентами.

**Платформы:** iOS 14+, macOS 11+, tvOS 14+, watchOS 7+, visionOS

---

## Быстрый старт

### 1. Mediator

Медиатор хранит состояние через view model и определяет интерфейсы для коммуникации интерактора и вью. Когда ViewModel конформит `ObservableObject`, SwiftUI обновляется автоматически.

```swift
import EZSUIPackKit

class ProfilePackM: EZSUIPackM {
    var viewModel: ViewModel
    @MainActor class ViewModel: ObservableObject {
        @Published var name = ""
        @Published var isLoading = false
    }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
    }

    let inputV: Void = ()

    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

### 2. Interactor

Интерактор содержит бизнес-логику и реагирует на lifecycle-события SwiftUI.

```swift
class ProfilePackI: EZSUIPackI {
    let access = ProfilePackM.accessI

    func makeInput() -> Mediator.InputI { self }

    func start() {
        loadProfile()
    }

    func onAppear() {
        refreshProfileIfNeeded()
    }
}

extension ProfilePackI: ProfilePackM.InputIProtocol {
    func loadProfile() {
        viewModel.isLoading = true
        // ... загрузка данных, обновление viewModel
    }

    private func refreshProfileIfNeeded() {
        // ...
    }
}
```

### 3. View

Стандартный SwiftUI `View` с доступом к `viewModel` (RW) и `inputI` (R).

```swift
import SwiftUI

struct ProfileView: EZSUIPackV {
    let access = ProfilePackM.accessV

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.name)
            }
            Button("Обновить") { inputI.loadProfile() }
        }
    }
}
```

### 4. Объединение в Pack

Используйте `EZSUIPack` для сборки всех трёх компонентов:

```swift
struct ProfileScreen: View {
    var body: some View {
        EZSUIPack(
            interactor: { ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { ProfileView() }
        )
    }
}
```

Когда интерактор использует кастомный `Context`, передайте полный closure:

```swift
EZSUIPack(
    interactor: { MyPackI() },
    mediator: { inputI, inputV, context in MyPackM(inputI: inputI, inputV: inputV, context: context) },
    view: { MyView() }
)
```

---

## Основные компоненты

| Компонент | Описание |
|-----------|----------|
| `EZSUIPack` | SwiftUI view, который собирает и управляет IMV паком |
| `EZSUIPackI` / `EZSUIPackInteractorProtocol` | Протокол интерактора с lifecycle `onAppear`/`onDisappear` |
| `EZSUIPackM` / `EZSUIPackMediator` | Базовый класс медиатора (ViewModel опционально конформит `ObservableObject`) |
| `EZSUIPackV` / `EZSUIPackViewProtocol` | Протокол вью, комбинирующий `View` + `EZIMVPackViewProtocol` |

---

## Отличия от EZUIPackKit

| Аспект | EZUIPackKit (UIKit) | EZSUIPackKit (SwiftUI) |
|--------|--------------------|-----------------------|
| База интерактора | `UIViewController` | Обычный класс |
| Lifecycle | `didCreate`, `willOpen`, `didOpen`, `willClose`, `didClose` | `onAppear`, `onDisappear` |
| View | `UIView` или SwiftUI через bridge | Нативный SwiftUI `View` |
| Создание пака | `EZPackMaker.make()` / `EZUIPack.make()` | `EZSUIPack(...)` в SwiftUI body |
| Обновление view model | Вручную через `packBridge` | Автоматически через `ObservableObject` |

---

## Полезные ссылки

- [Быстрый старт](QuickStart/README.md) — пошаговое руководство
- [Документация EZUIPackKit](../EZUIPackKit/README.md) — UIKit-эквивалент
- [EZIMVPackKit](../../../../../Sources/EZUI/EZIMVPack/EZIMVPackKit/) — общие базовые протоколы
- [Исходный код](../../../../../Sources/EZUI/EZIMVPack/EZSUIPackKit/) — реализация модуля
