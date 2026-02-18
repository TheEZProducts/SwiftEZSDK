# Руководство по миграции EZUIPackKit

> В версиях 2.x–4.x не было breaking changes в EZUIPackKit.
> Миграция необходима начиная с **5.0.0**.

---

## 2-4 → 5

### Обзор

`EZUIPackStorage` удалён — Interactor стал `UIViewController`. Действия на основе структур (`EZUIPackActionProviderProtocol`) заменены явными associated types (`IActionProvider`, `VActionProvider`, `Storage`, `ViewModel`). Введён контроль доступа (`AccessI`, `AccessV`). Специализированные классы Pack (`EZUINavigationPack`, `EZUITabBarPack`) объединены в `EZUIPack` — тип контейнера теперь определяется базовым классом Interactor. Создание Pack перенесено в фабрику `make()`.

### Mediator

**До:**
```swift
class ProfilePackM: EZUIPackM {
    // EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediatorWithActionProviders & EZUIPackMediator
    // Данные хранились прямо на Mediator (без концепции ViewModel)
    var name: String = ""

    // Действия были структурами с замыканиями, конформящими EZUIPackActionProviderProtocol
    var iActions = IAction()
    struct IAction: EZUIPackActionProviderProtocol {
        var load = {}
    }

    var vActions = VAction()
    struct VAction: EZUIPackActionProviderProtocol {
        var refresh = {}
    }
}
```

**После:**
```swift
class ProfilePackM: EZUIPackM {
    // EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator

    // Явные associated types (используйте Void если не нужно)
    typealias IActionProvider = InputIProtocol?
    typealias VActionProvider = InputVProtocol?
    typealias Storage = Void
    typealias ViewModel = ViewModel

    weak var iActions: IActionProvider   // устанавливается фреймворком после setupActions()
    weak var vActions: VActionProvider
    var storage: Storage
    var viewModel: ViewModel

    // Данные перенесены в структуру ViewModel
    @MainActor struct ViewModel { var name: String = "" }
    @MainActor protocol InputIProtocol: AnyObject { func load() }
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init() {
        iActions = nil
        vActions = nil
        viewModel = .init()
    }
}
```

**Ключевые моменты:**
- `EZUIPackMediatorWithActionProviders` и `EZUIPackActionProviderProtocol` больше не существуют
- Перенесите общие данные из свойств Mediator в структуру `ViewModel`
- Объявите `IActionProvider`, `VActionProvider`, `Storage`, `ViewModel` как associated types
- Используйте `Void` для ненужных типов (есть реализации по умолчанию)
- `Storage` — эксклюзивные данные для Interactor (доступ через `access.storage`)
- Action providers могут быть протоколами (для class-based I/V) или структурами с замыканиями (для SwiftUI views)

### Interactor

**До:**
```swift
class ProfilePackI: EZUIPackI {
    // EZUIPackI = EZUIPackInteractorProtocol (обычный класс, НЕ UIViewController)
    // EZUIPackStorage<I,M,V> был фактическим UIViewController

    var mediator: ProfilePackM!

    func setupActions() {  // void — присваивает замыкания в структуры действий
        iActions.load = { [weak self] in self?.load() }
    }

    private func load() { /* ... */ }
}
```

**После:**
```swift
class ProfilePackI: EZUIPackI {
    // EZUIPackI = EZUIPackInteractor & EZUIPackInteractorProtocol
    // Interactor ТЕПЕРЬ является UIViewController

    var access: Mediator.AccessI!  // заменяет прямую ссылку на Mediator

    // setupActions() теперь возвращает action provider
    func setupActions() -> Mediator.IActionProvider {
        self
    }
}
// При возврате self — конформьте протоколу действий:
extension ProfilePackI: ProfilePackM.InputIProtocol {
    func load() { /* ... */ }
}
```

**Ключевые моменты:**
- Interactor теперь `UIViewController` — уберите ручное встраивание VC через `EZUIPackStorage`
- Замените `var mediator: Mediator!` на `var access: Mediator.AccessI!`
- `setupActions()` теперь **возвращает** action provider вместо присваивания замыканий
- При возврате `self` — конформьте протоколу действий Mediator
- `init(mediator:)` удалён — Interactor создаётся через `init(pack:customData:)`

### View

**До:**
```swift
class ProfileIOSV: EZUIPackV {
    var mediator: ProfilePackM!

    func setupActions() {  // void — присваивает замыкания в структуры действий
        vActions.refresh = { [weak self] in self?.refreshUI() }
    }

    private func refreshUI() { /* ... */ }
}
```

**После (на основе протокола, UIKit class view):**
```swift
class ProfileIOSV: EZUIPackV {
    var access: Mediator.AccessV!

    func setupActions() -> Mediator.VActionProvider? {
        self
    }
}
extension ProfileIOSV: ProfilePackM.InputVProtocol {
    func refresh() { /* ... */ }
}
```

**После (на основе struct, SwiftUI view — единственный верный вариант для struct views):**

Когда V — SwiftUI view (struct), он не может быть weak ссылкой. Используйте struct с замыканиями для `VActionProvider`:
```swift
// В Mediator — объявите struct вместо протокола:
var vActions: InputV = .init(refresh: {})
struct InputV {
    var refresh: () -> Void
}

// В SwiftUI view:
func setupActions() -> Mediator.VActionProvider? {
    .init(refresh: { /* ... */ })
}
```

**Ключевые моменты:**
- Замените `var mediator` на `var access: Mediator.AccessV!`
- `setupActions()` возвращает `Mediator.VActionProvider?` вместо присваивания замыканий
- Для UIKit views (классы): возвращайте `self` и конформьте протоколу действий
- Для SwiftUI views (структуры): используйте struct с замыканиями как `VActionProvider`

### Создание Pack

**До:**
```swift
// Специализированные типы Pack: EZUINavigationPack, EZUITabBarPack, EZUIPack
typealias ProfilePack = EZUINavigationPack<ProfilePackI, ProfilePackM, ProfilePackV>

let pack = ProfilePack()
// EZUIPackStorage был UIViewController
```

**После:**
```swift
// Унифицировано в EZUIPack — тип контейнера определяется базовым классом Interactor:
// EZUIPackI (обычный), EZUINavigationPackI (навигация), EZUITabBarPackI (tab bar)
typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>

// Interactor ЯВЛЯЕТСЯ UIViewController — make() возвращает его напрямую
let interactor = ProfilePack.make()
navigationController.pushViewController(interactor, animated: true)
```

### Доступ к данным (шпаргалка)

| До | После |
|---|---|
| `mediator.someProperty` (прямой) | `viewModel.someProperty` |
| `iActions.load()` (замыкание в struct) | `iActions?.load()` (метод протокола, в V) |
| `vActions.refresh()` (замыкание в struct) | `vActions?.refresh()` (метод протокола, в I) |
| `var mediator: Mediator!` | `var access: Mediator.AccessI!` / `.AccessV!` |
| `pack.storage` (UIViewController) | Interactor является UIViewController |
| `EZUINavigationPack` / `EZUITabBarPack` | `EZUIPack` + базовый класс Interactor |

---

## 5 → 6

### Обзор

`IActionProvider`/`VActionProvider` заменены на `InputI`/`InputV`. `Storage` удалён — Interactor теперь хранит свои данные. `setupActions()` удалён — inputs передаются через систему контекстов (`makeContext()`). Mediator получает явный `init(contextI:contextV:)`. Access объекты стали class-based (`let`) с поддержкой `AccessMap`. `.transit` переименован в `.ezTransit`.

### Переименование Transit

```swift
// До:
self.transit.navigationPush(otherVC).transit()

// После:
self.ezTransit.navigationPush(otherVC).transit()
```

Свойства точки входа `.transit` на `UIViewController` и `EZContainerView` переименованы в `.ezTransit`. Метод выполнения `.transit()` на цепочках переходов **не** переименован.

### Mediator

**До:**
```swift
class ProfilePackM: EZUIPackM {
    typealias IActionProvider = InputIProtocol?
    typealias VActionProvider = InputVProtocol?
    typealias Storage = Void
    typealias ViewModel = ViewModel

    weak var iActions: IActionProvider
    weak var vActions: VActionProvider
    var storage: Storage
    var viewModel: ViewModel

    @MainActor struct ViewModel { var name: String = "" }
    @MainActor protocol InputIProtocol: AnyObject { func load() }
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init() {
        iActions = nil
        vActions = nil
        viewModel = .init()
    }
}
```

**После:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
```

**Ключевые моменты:**
- Удалите `IActionProvider`/`VActionProvider`/`Storage` — используйте `InputI`/`InputV`/`ViewModel` напрямую
- `Storage` полностью удалён — Interactor должен хранить свои эксклюзивные данные как обычные свойства
- Замените `required init()` на `required init(contextI:contextV:)`
- `contextI.actions` = InputI, `contextI.viewModel` = начальный ViewModel, `contextV.actions` = InputV
- Используйте `weak let` вместо `weak var` для ссылок на input

### Interactor

**До:**
```swift
class ProfilePackI: EZUIPackI {
    var access: Mediator.AccessI!  // устанавливается фреймворком

    func setupActions() -> Mediator.IActionProvider { self }
}
```

**После:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI  // теперь let, инициализируется статически

    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
}
```

**Ключевые моменты:**
- `access` теперь `let`, создаётся через `ProfilePackM.accessI` (статическая фабрика)
- Замените `setupActions()` на `makeContext()`, возвращающий `Mediator.ContextI`
- Контекст оборачивает `actions` (= InputI) и `viewModel` (начальное состояние)
- Mediator **ещё не доступен** при вызове `makeContext()` (в отличие от `setupActions()`, где Mediator был доступен)

### View

**До:**
```swift
class ProfileIOSV: EZUIPackV {
    var access: Mediator.AccessV!

    func setupActions() -> Mediator.VActionProvider? { self }
}
```

**После:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV  // теперь let, инициализируется статически

    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
}
```

**Ключевые моменты:**
- `access` теперь `let`, создаётся через `ProfilePackM.accessV`
- Замените `setupActions()` на `makeContext()`, возвращающий `Mediator.ContextV`
- Mediator **ещё не доступен** при вызове `makeContext()`

### Создание Pack

Без изменений — `ProfilePack.make()` работает как прежде.

### Доступ к данным (шпаргалка)

| До | После |
|---|---|
| `access.iActions` (в V) | `access.inputI` или `inputI` |
| `access.vActions` (в I) | `access.inputV` или `inputV` |
| `access.storage` (в I) | удалено — храните данные как свойства Interactor |
| `access.viewModel` | `access.viewModel` или `viewModel` (то же) |
| `.transit` | `.ezTransit` |

---

## 6 → 7

### Обзор

Обёртки контекстов (`ContextI`/`ContextV`) удалены. I и V предоставляют inputs напрямую через `makeInput()`. Mediator имеет свободный инициализатор. Создание Pack использует `EZPackMaker.make(interactor:mediator:view:)` с явными замыканиями. Interactor может по-прежнему предоставлять дополнительный контекст через `associatedtype Context` + `makeContext()`, но теперь это отдельно от системы input.

### Mediator

**До:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
```

**После:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    // Свободный init — получает InputI и InputV напрямую
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

**Ключевые моменты:**
- Удалите `required init(contextI:contextV:)` — это больше не требование протокола
- Замените на любой init, принимающий `InputI` и `InputV` напрямую (+ любые доп. параметры)
- ViewModel больше не передаётся извне — инициализируйте его внутри `init`
- Типы `ContextI`/`ContextV`/`BaseContextI`/`BaseContextV` больше не существуют

### Interactor

**До:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
}
```

**После:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    func makeInput() -> Mediator.InputI { self }
    // Реализация по умолчанию когда Mediator.InputI == Self — можно опустить
}
```

Контекст по-прежнему существует, но теперь это отдельная концепция Interactor:

```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    // associatedtype Context = Void по умолчанию — typealias не нужен когда Void
    // Переопределяйте только если нужно передать доп. данные в Mediator:
    typealias Context = ProfileContext  // объявляйте только когда Context != Void
    func makeContext() -> Context { .init(userId: userId) }
}
```

Контекст передаётся как 3-й параметр в замыкание Mediator в `EZPackMaker.make()`.

**Ключевые моменты:**
- Замените `makeContext() -> Mediator.ContextI` на `makeInput() -> Mediator.InputI`
- Реализация по умолчанию когда `Mediator.InputI == Self` или `Mediator.InputI == Void`
- `makeContext()` по-прежнему существует, но возвращает `I.Context` (не `Mediator.ContextI`), по умолчанию `Void`

### View

**До:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV

    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
}
```

**После:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV

    func makeInput() -> Mediator.InputV { self }
    // Реализация по умолчанию когда Mediator.InputV == Self — можно опустить
}
```

**Ключевые моменты:**
- Замените `makeContext()` на `makeInput()`, возвращающий `Mediator.InputV`
- Реализация по умолчанию когда `Mediator.InputV == Self` или `Mediator.InputV == Void`

### Создание Pack

**До:**
```swift
typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
let interactor = ProfilePack.make()
```

**После:**
```swift
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

### Передача внешних данных

**До:** внешние данные передавались через `ContextI` в `init(contextI:contextV:)` Mediator.

**После:** два подхода:

**Через I.Context** (структурированные данные от Interactor, получаемые как 3-й параметр в замыкании Mediator):
```swift
// Interactor определяет Context:
class ProfilePackI: EZUIPackI {
    // ...
    typealias Context = ProfileContext  // объявляйте только когда Context != Void
    func makeContext() -> Context { .init(userId: userId) }
}

// Context получается как 3-й параметр в замыкании Mediator:
enum ProfilePack {
    @MainActor
    static func make(userId: String) -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI(userId: userId) },
            mediator: { inputI, inputV, context in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: context.userId)
            },
            view: { ProfilePackV() }
        )
    }
}
```

**Через прямой захват в замыкании** (проще всего, когда I.Context не нужен):
```swift
enum ProfilePack {
    @MainActor
    static func make(userId: String) -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI(userId: userId) },
            mediator: { inputI, inputV in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: userId)
            },
            view: { ProfilePackV() }
        )
    }
}
```

### Чеклист быстрой конвертации

1. **Mediator**: `init(contextI:contextV:)` → `init(inputI:inputV:)`, инициализируйте ViewModel внутри
2. **Interactor**: `makeContext() -> Mediator.ContextI` → `makeInput() -> Mediator.InputI`
3. **View**: `makeContext() -> Mediator.ContextV` → `makeInput() -> Mediator.InputV`
4. **Создание Pack**: `ProfilePack.make()` → `EZPackMaker.make(interactor:mediator:view:)`
5. Удалите все ссылки на `ContextI`/`ContextV`/`BaseContextI`/`BaseContextV`
