# Быстрый старт EZSUIPackKit

Это руководство покажет как создать первый SwiftUI-экран на архитектуре **IMV (Interactor-Mediator-View)**.

---

## Содержание

- [Архитектура IMV](#архитектура-imv)
- [Создание Pack](#создание-pack)
  - [1. Mediator](#1-mediator)
  - [2. Interactor](#2-interactor)
  - [3. View](#3-view)
  - [4. Сборка Pack](#4-сборка-pack)
- [Передача внешних данных](#передача-внешних-данных)
- [Реактивность](#реактивность)
- [InputV для SwiftUI View](#inputv-для-swiftui-view)
- [Типичные ошибки](#типичные-ошибки)

---

## Архитектура IMV

**Pack** — это экран или модуль приложения, состоящий из трёх компонентов:

| Компонент | Ответственность |
|-----------|-----------------|
| **Interactor** | Бизнес-логика, загрузка данных, lifecycle. Обычный класс (не `UIViewController`). |
| **Mediator** | Хранит `ViewModel` (состояние UI), предоставляет интерфейсы `inputI` и `inputV` для взаимодействия. |
| **View** | Отображение UI с помощью нативного SwiftUI. |

### Как взаимодействуют компоненты

**Важно:** Interactor и View **не имеют прямого доступа** к Mediator. Они взаимодействуют с ним только через специальные объекты доступа (access):

```
┌─────────────┐                         ┌─────────────┐                         ┌─────────────┐
│ Interactor  │                         │  Mediator   │                         │     View    │
│             │                         │             │                         │             │
│ • логика    │                         │ • ViewModel │                         │ • UI        │
│ • загрузка  │   ┌─────────────────┐   │ • inputI    │   ┌─────────────────┐   │ • события   │
│             │   │     AccessI     │   │ • inputV    │   │     AccessV     │   │             │
│  access ------->│ • viewModel(RW) │-->│             │<--│ • viewModel(R)  │<------- access  │
│             │   │ • inputV(R)     │   │             │   │ • inputI(R)     │   │             │
└─────────────┘   └─────────────────┘   └─────────────┘   └─────────────────┘   └─────────────┘
```

---

## Создание Pack

Создадим простой экран профиля пользователя.

### 1. Mediator

Mediator хранит состояние (`ViewModel`) и определяет интерфейсы взаимодействия.

**Ключевое отличие от UIKit:** `ViewModel` должен конформить `ObservableObject`, а его свойства должны использовать `@Published` (или `@EZObservable` с `snapEZObservable()`). SwiftUI автоматически обновляет View при изменении `ObservableObject`.

```swift
import EZSUIPackKit

final class ProfilePackM: EZSUIPackM {
    // MARK: - ViewModel (состояние UI)
    // Должен быть ObservableObject для автоматических обновлений SwiftUI
    var viewModel: ViewModel
    @MainActor class ViewModel: ObservableObject {
        @Published var userName: String = ""
        @Published var isLoading: Bool = false
    }

    // MARK: - InputI (интерфейс для Interactor, вызывается из View)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }

    // MARK: - InputV (интерфейс для View, вызывается из Interactor)
    // Для SwiftUI views (struct) используем struct с замыканиями,
    // потому что struct не может быть weak ссылкой
    let inputV: InputV
    @MainActor struct InputV {
        var showAlert: (String) -> Void = { _ in }
    }

    // MARK: - Init
    // Свободный инициализатор — получает InputI и InputV напрямую
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

**Важно:**
- `inputI` — интерфейс, методы которого **реализует Interactor**, а **вызывает View**
- `inputV` — для SwiftUI View (struct) используйте struct с замыканиями вместо протокола
- `ViewModel` — класс `ObservableObject` со свойствами `@Published`
- **I и V не имеют прямого доступа** к Mediator, только через access объекты

---

### 2. Interactor

Interactor содержит бизнес-логику и реагирует на SwiftUI lifecycle-события.

**Ключевое отличие от UIKit:** Interactor — обычный класс (не `UIViewController`), а lifecycle ограничен `onAppear`/`onDisappear`.

```swift
import EZSUIPackKit

final class ProfilePackI: EZSUIPackI {
    // Объект доступа к Mediator (НЕ прямая ссылка на Mediator!)
    // Предоставляет доступ только к viewModel и inputV
    let access = ProfilePackM.accessI

    // MARK: - Input для Mediator
    // Возвращает self как InputI (по умолчанию когда Mediator.InputI == Self)
    // func makeInput() -> Mediator.InputI { self }

    // MARK: - Жизненный цикл
    func didInitialize() {
        // Вызывается после создания и подключения Pack
    }

    func start() {
        // Вызывается когда Pack готов к работе
        loadProfile()
    }

    func onAppear() {
        // SwiftUI view появился — обновить данные при необходимости
    }

    func onDisappear() {
        // SwiftUI view исчез — отменить задачи при необходимости
    }

    // MARK: - Бизнес-логика
    private func fetchProfile() {
        access.viewModel.isLoading = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            access.viewModel.userName = "Иван Петров"
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
        // Обработка выхода
    }
}
```

---

### 3. View

Стандартный SwiftUI `View` с read-only доступом к `viewModel` и `inputI`.

```swift
import SwiftUI
import EZSUIPackKit

struct ProfileView: EZSUIPackV {
    // Объект доступа к Mediator (НЕ прямая ссылка на Mediator!)
    // Предоставляет доступ только к viewModel и inputI
    let access = ProfilePackM.accessV

    // MARK: - Input для Mediator
    // Возвращает struct с замыканиями для InputV
    func makeInput() -> Mediator.InputV {
        .init(
            showAlert: { message in
                print("Alert: \(message)")
            }
        )
    }

    // MARK: - UI
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.userName)
                    .font(.title)
            }

            Button("Загрузить") {
                inputI?.loadProfile()
            }

            Button("Выйти") {
                inputI?.logout()
            }
        }
        .padding()
    }
}
```

**Примечание:** `viewModel` и `inputI` — удобные свойства из `EZSUIPackViewProtocol`. Они эквивалентны `access.viewModel` и `access.inputI`.

---

### 4. Сборка Pack

Используйте `EZSUIPack` для сборки всех трёх компонентов в SwiftUI body:

```swift
import SwiftUI
import EZSUIPackKit

struct ProfileScreen: View {
    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { _ in ProfileView() }
        )
    }
}
```

`EZSUIPack` создаёт все компоненты, соединяет их и управляет lifecycle. Внутри используется `@StateObject` для сохранения при SwiftUI re-renders.

---

## Передача внешних данных

### Через I.Context

Используйте `I.Context`, когда нужны структурированные данные от Interactor, доступные Mediator:

```swift
final class ProfilePackI: EZSUIPackI {
    let access = ProfilePackM.accessI
    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    typealias Context = ProfileContext
    func makeContext() -> Context { .init(userId: userId) }
}

struct ProfileScreen: View {
    let userId: String

    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI(userId: userId) },
            mediator: { inputI, inputV, context in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: context.userId)
            },
            view: { _ in ProfileView() }
        )
    }
}
```

### Через прямой захват в замыкании

Простейший подход, когда `I.Context` не нужен:

```swift
struct ProfileScreen: View {
    let userId: String

    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI(userId: userId) },
            mediator: { inputI, inputV in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: userId)
            },
            view: { _ in ProfileView() }
        )
    }
}
```

---

## Реактивность

SwiftUI обновляется автоматически при срабатывании `ObservableObject.objectWillChange`. Два варианта:

### @Published (стандарт)

```swift
@MainActor class ViewModel: ObservableObject {
    @Published var name = ""
    @Published var isLoading = false
}
```

### @EZObservable + snapEZObservable()

```swift
@MainActor class ViewModel: ObservableObject {
    @Published var name = ""
    @EZObservable var isLoading = false

    init() { snapEZObservable() }
}
```

`snapEZObservable()` связывает `@EZObservable` свойства с `objectWillChange`, так что SwiftUI реагирует на их изменения так же, как на `@Published`.

---

## InputV для SwiftUI View

Поскольку SwiftUI `View` — это `struct`, он не может конформить `@MainActor protocol` с `weak` ссылками. Используйте struct с замыканиями для `InputV`:

```swift
// В Mediator:
let inputV: InputV
@MainActor struct InputV {
    var showAlert: (String) -> Void = { _ in }
}

// В View:
func makeInput() -> Mediator.InputV {
    .init(showAlert: { message in /* ... */ })
}
```

Если `InputV` не нужен, используйте `Void`:

```swift
// В Mediator:
let inputV: Void = ()
// Никаких InputV протоколов или struct не нужно

// В View:
// makeInput() имеет реализацию по умолчанию, возвращающую ()
```

---

## Типичные ошибки

| Ошибка | Решение |
|--------|---------|
| ViewModel — struct, а не class | ViewModel должен быть `class`, конформящим `ObservableObject` |
| Использование `@State` во View для общих данных | Используйте `viewModel` из access объекта |
| Хранение Interactor в `@State`/`@ObservedObject` | `EZSUIPack` управляет lifecycle компонентов через `@StateObject` |
| `weak let` для InputV struct | `weak` только для class типов; используйте `let` для struct-based InputV |
| Обращение к Mediator до `didInitialize()` | Access объект подключается только после инициализации |

---

## Следующие шаги

- [Обзор EZSUIPackKit](../README.md) — основные компоненты и сравнение с UIKit
- [Быстрый старт EZUIPackKit](../../EZUIPackKit/QuickStart/README.md) — эквивалентный гайд для UIKit
