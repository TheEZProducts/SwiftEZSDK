# Быстрый старт EZUIPackKit

Это руководство покажет как создать первый экран на архитектуре **IMV (Interactor–Mediator–View)**.

---

## Содержание

- [Архитектура IMV](#архитектура-imv)
- [Создание Pack вручную](#создание-pack-вручную)
  - [1. Mediator](#1-mediator)
  - [2. Interactor](#2-interactor)
  - [3. View (UIKit)](#3-view-uikit)
  - [4. Объединение в Pack](#4-объединение-в-pack)
- [Запуск Pack](#запуск-pack)
- [SwiftUI View](#swiftui-view)
- [Переходы между экранами](#переходы-между-экранами)
- [Общие данные между Pack'ами](#общие-данные-между-pacками)
- [Типичные ошибки](#типичные-ошибки)

---

## Архитектура IMV

**Pack** — это экран или модуль приложения, состоящий из трёх компонентов:

| Компонент | Ответственность |
|-----------|-----------------|
| **Interactor** | Бизнес-логика, жизненный цикл, навигация. Наследует `UIViewController`. |
| **Mediator** | Хранит `ViewModel` (состояние UI), предоставляет интерфейсы `inputI` и `inputV` для взаимодействия. |
| **View** | Отображение UI, реакция на события пользователя. |

### Как взаимодействуют компоненты

**Важно:** Interactor и View **не имеют прямого доступа** к Mediator. Они взаимодействуют с ним только через специальные объекты доступа (access):

```
┌─────────────┐                         ┌─────────────┐                         ┌─────────────┐
│ Interactor  │                         │  Mediator   │                         │     View    │
│             │                         │             │                         │             │
│ • логика    │                         │ • ViewModel │                         │ • UI        │
│ • навигация │   ┌─────────────────┐   │ • inputI    │   ┌─────────────────┐   │ • события   │
│             │   │     AccessI     │   │ • inputV    │   │     AccessV     │   │             │
│  access ------->│ • viewModel(RW) │-->│             │<--│ • viewModel(RW) │<------- access  │
│             │   │ • inputV(R)     │   │             │   │ • inputI(R)     │   │             │ 
└─────────────┘   └─────────────────┘   └─────────────┘   └─────────────────┘   └─────────────┘
```

**Механизм доступа:**
- **Interactor** использует `access = ProfilePackM.accessI` для доступа к `viewModel` и `inputV`
- **View** использует `access = ProfilePackM.accessV` для доступа к `viewModel` и `inputI`
- **Access объекты** предоставляют **контролируемый доступ** только к определенным частям Mediator
- **Прямого доступа** к самому Mediator у I и V **нет** — это обеспечивает инкапсуляцию и безопасность

**Преимущества такого подхода:**
- Инкапсуляция: I и V не могут напрямую изменять внутреннее состояние M
- Контролируемый доступ: можно ограничить, какие части M доступны каждому компоненту
- Безопасность: доступ доступен только после инициализации (`didInitialize()`)
- Гибкость: можно расширить доступ через `AccessMap` для дополнительных свойств

---

## Создание Pack вручную

Создадим простой экран профиля пользователя.

### 1. Mediator

Mediator хранит состояние (`ViewModel`) и определяет интерфейсы взаимодействия. **Mediator создает объекты доступа** (`accessI` и `accessV`), через которые I и V получают контролируемый доступ к его данным.

```swift
import EZUIPackKit

final class ProfilePackM: EZUIPackM {
    // MARK: - ViewModel (состояние UI)
    var viewModel: ViewModel
    @MainActor struct ViewModel {
        // Используем @EZObservable для автоматической реактивности
        // View может подписаться на изменения через $userName и $isLoading
        // При изменении этих свойств автоматически уведомляются все подписчики
        @EZObservable var userName: String = ""
        @EZObservable var isLoading: Bool = false
        
        // Примечание: для простых случаев без реактивности можно использовать
        // обычные свойства и вызывать updateUI() вручную в нужных местах
    }
    
    // MARK: - InputI (интерфейс для Interactor, вызывается из View)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }
    
    // MARK: - InputV (интерфейс для View, вызывается из Interactor)
    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject {
        func showError(_ message: String)
    }
    
    // MARK: - Init
    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
    
    // MARK: - Access объекты
    // Эти статические свойства создают объекты доступа для I и V
    // Interactor использует: let access = ProfilePackM.accessI
    // View использует: let access = ProfilePackM.accessV
    // 
    // Access объекты предоставляют контролируемый доступ к:
    // - viewModel (чтение и запись)
    // - inputI / inputV (только чтение)
    // 
    // Прямого доступа к самому Mediator у I и V нет!
}
```

**Важно:**
- `inputI` — интерфейс, методы которого **реализует Interactor**, а **вызывает View**
- `inputV` — интерфейс, методы которого **реализует View**, а **вызывает Interactor**
- `ViewModel` — структура с данными для отображения
- **`accessI` и `accessV`** — статические свойства, создающие объекты доступа для I и V
- **I и V не имеют прямого доступа** к Mediator, только через эти access объекты

---

### 2. Interactor

Interactor содержит бизнес-логику и реагирует на события жизненного цикла.

**Важно:** Interactor **не имеет прямого доступа** к Mediator. Вместо этого он использует объект доступа `access`, который предоставляет контролируемый доступ только к `viewModel` и `inputV`.

```swift
import EZUIPackKit

final class ProfilePackI: EZUIPackI {
    // Объект доступа к Mediator (НЕ прямая ссылка на Mediator!)
    // Предоставляет доступ только к viewModel и inputV
    // Прямого доступа к самому Mediator нет
    let access = ProfilePackM.accessI
    
    // MARK: - Создание контекста для Mediator
    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
    
    // MARK: - Жизненный цикл
    func didInitialize() {
        // Вызывается после создания Pack
    }
    
    func start() {
        // Вызывается когда Pack готов к работе
        fetchProfile()
    }
    
    func willOpen() {
        // Перед анимацией открытия
    }
    
    func didOpen() {
        // После анимации открытия
    }
    
    func willClose() {
        // Перед анимацией закрытия
    }
    
    func didClose() {
        // После анимации закрытия
    }
    
    // MARK: - Бизнес-логика
    private func fetchProfile() {
        // Доступ к viewModel через access (НЕ напрямую к Mediator!)
        // access.viewModel - это контролируемый доступ к ViewModel в Mediator
        // Изменение @EZObservable свойств автоматически уведомит подписчиков
        // Обычное присваивание через wrappedValue автоматически вызывает уведомления
        access.viewModel.isLoading = true
        
        // Имитация загрузки
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
        // Закрыть текущий экран
        ezTransit.dismiss().animate().transit()
    }
}
```

---

### 3. View (UIKit)

View отвечает за отображение UI.

**Важно:** View **не имеет прямого доступа** к Mediator. Вместо этого он использует объект доступа `access`, который предоставляет контролируемый доступ только к `viewModel` и `inputI`.

```swift
import UIKit
import EZUIPackKit

final class ProfilePackV: EZUIPackV {
    // Объект доступа к Mediator (НЕ прямая ссылка на Mediator!)
    // Предоставляет доступ только к viewModel и inputI
    // Прямого доступа к самому Mediator нет
    let access = ProfilePackM.accessV
    
    // MARK: - UI Elements
    private let nameLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let logoutButton = UIButton(type: .system)
    
    // MARK: - Создание контекста для Mediator
    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
    
    // MARK: - Создание UI
    func create() {
        view.backgroundColor = .systemBackground
        
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        logoutButton.setTitle("Выйти", for: .normal)
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
    
    // MARK: - Жизненный цикл
    /// Вызывается после создания Mediator и подключения, но ДО `create()`.
    /// 
    /// **Важно:** Access объект доступен только после `didInitialize()`.
    /// Используйте этот метод для:
    /// - Подписки на изменения viewModel
    /// - Настройки, требующей доступа к Mediator
    /// - Инициализации наблюдателей
    func didInitialize() {
        // Подписываемся на изменения viewModel для автоматического обновления UI
        // Доступ к viewModel через access (НЕ напрямую к Mediator!)
        // Используем $userName и $isLoading (projected values от @EZObservable)
        access.viewModel.$userName.add { [weak self] _ in
            self?.updateUI()
        }
        
        access.viewModel.$isLoading.add { [weak self] _ in
            self?.updateUI()
        }
    }

    func willOpen() {
        // Подготовка к появлению экрана
    }
    
    func animateOpen() {
        // Вызывается в контексте анамиции перехода на экран
    }
    
    func didOpen() {
        // View полностью появился и готов к работе
    }
    
    func didInstall() {
        // Layout завершен
    }
    
    func willClose() {
        // Подготовка к исчезновению экрана
    }
    

    func animateClose() {
        // Вызывается в контексте анамиции перехода с экрана
    }
    
    func didClose() {
        // View полностью исчез, можно освобождать ресурсы
    }
    
  
    func viewDidLoad() {
        // Дополнительная настройка после загрузки View
    }
  
    func viewWillAppear(_ animated: Bool) {
        // Подготовка перед появлением
    }
    
    func viewDidAppear(_ animated: Bool) {
        // Действия после появления
    }
    
    func viewWillDisappear(_ animated: Bool) {
        // Подготовка перед исчезновением
    }
    
    func viewDidDisappear(_ animated: Bool) {
        // Действия после исчезновения
    }
    
    // MARK: - Обновление UI
    private func updateUI() {
        // Доступ к viewModel через access (НЕ напрямую к Mediator!)
        // access.viewModel - это контролируемый доступ к ViewModel в Mediator
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
        // Доступ к inputI через access (НЕ напрямую к Mediator!)
        // access.inputI - это контролируемый доступ к InputI в Mediator
        access.inputI?.logout()
    }
}

// MARK: - InputVProtocol
extension ProfilePackV: ProfilePackM.InputVProtocol {
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        packBridge.pack?.interactor?.present(alert, animated: true)
    }
}
```

---

### 4. Объединение в Pack

```swift
import EZUIPackKit

typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
```

Готово! Теперь `ProfilePack` — это полноценный экран.

---

## Запуск Pack

### Как корневой контроллер

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
        window?.rootViewController = ProfilePack.make()
        window?.makeKeyAndVisible()
    }
}
```

### Модальное открытие

```swift
let profilePack = ProfilePack.make()
present(profilePack.interactor, animated: true)
```

### Push в NavigationController

```swift
let profilePack = ProfilePack.make()
navigationController?.pushViewController(profilePack.interactor, animated: true)
```

### Через систему переходов

```swift
// Из любого UIViewController
ezTransit.present(ProfilePack.make().interactor).animate().transit()

// Или navigation push
ezTransit.navigationPush(ProfilePack.make().interactor).animate().transit()
```

---

## SwiftUI View

Если предпочитаете SwiftUI, используйте `EZUIPackSV`:

**Важно:** SwiftUI View также **не имеет прямого доступа** к Mediator и использует объект доступа `access`, как и UIKit View.

```swift
import SwiftUI
import EZUIPackKit

struct ProfileSwiftUIPackV: EZUIPackSV {
    // Объект доступа к Mediator (НЕ прямая ссылка на Mediator!)
    // Предоставляет доступ только к viewModel и inputI
    // Прямого доступа к самому Mediator нет
    let access = ProfilePackM.accessV
    
    // Для SwiftUI View используем struct с замыканиями вместо протокола,
    // потому что SwiftUI View — это struct, и не может быть weak
    func makeContext() -> Mediator.ContextV {
        .init(actions: .init(
            showError: { [weak access] message in
                // Обработка ошибки
                print("Error: \(message)")
            }
        ))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Доступ к viewModel через access (НЕ напрямую к Mediator!)
            if access.viewModel.isLoading {
                ProgressView()
            } else {
                Text(access.viewModel.userName)
                    .font(.title)
            }
            
            Button("Выйти") {
                // Доступ к inputI через access (НЕ напрямую к Mediator!)
                access.inputI?.logout()
            }
        }
    }
}
```

**Важно для SwiftUI:** так как SwiftUI View — это `struct`, он не может быть `weak`. Поэтому `InputV` лучше определить как структуру с замыканиями:
Если ViewModel конформит к `ObservableObject`, SwiftUI автоматически будет обновлять View при изменениях. Так же есть поддержка EZObservable, они будут вести себя так же как @Published, если вызвать метод `snapEZObservable()`. При этом, в самом View не нужна ни какая дополнительная диклорация, все будет обновляться автоматически. 

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
    
    // MARK: - InputI (протокол, т.к. Interactor — класс)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }
    
    // MARK: - InputV (struct с замыканиями, т.к. SwiftUI View — struct)
    let inputV: InputV
    @MainActor struct InputV {
        var showError: (String) -> Void
    }
    
    // MARK: - Init
    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
```

**Как это работает:**
- `@EZObservable` создает наблюдаемые свойства с проекцией `$propertyName` для подписки
- `snapEZObservable($userName, $isLoading)` подписывается на изменения и вызывает `objectWillChange.send()` при каждом изменении
- SwiftUI автоматически обновляет View при изменении `ObservableObject`
- Подписки автоматически удаляются при деинициализации `ObservableObject` благодаря `snapToObject(self)`

---

## Переходы между экранами

### Navigation

```swift
// Push
ezTransit.navigationPush(OtherPack.make().interactor).animate().transit()

// Pop
ezTransit.navigationPop().animate().transit()

// Pop to root
ezTransit.navigationPopToRoot().animate().transit()
```

### Modal

```swift
// Present
ezTransit.present(OtherPack.make().interactor)
    .presentationStyle(.fullScreen)
    .animation(.coverVertical)
    .transit()

// Dismiss
ezTransit.dismiss().animate().transit()
```

### Tab Bar

```swift
// Выбор по индексу
ezTransit.tabBarSelect(1).animate().transit()

// Следующий таб
ezTransit.tabBarNext().animate().transit()

// Предыдущий таб
ezTransit.tabBarBack().animate().transit()
```

### Кастомные переходы

```swift
// Через transitionController
ezTransit.custom()
    .transitionType(.ezOpen)
    .animate()
    .transit()
```

---

## Общие данные между view controllers

Используйте `EZSharedStorage` для передачи данных между родительским и дочерними view controllers. Работает с любыми `UIViewController`, которые реализуют протокол `EZSharingProtocol`.

### Определение ключей

```swift
// 1. Определяем ключи для shared storage view controller'а
extension EZSharedKeyChain<OnboardingViewController> {
    var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
    var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
}

// 2. Создаём static var для удобного доступа к chain
extension EZSharedKey {
    static var onboardingChain: EZSharedKeyChain<OnboardingViewController> { .init() }
}
```

### В родительском view controller

```swift
// Любой UIViewController, который реализует EZSharingProtocol
class OnboardingViewController: UIViewController, EZSharingProtocol {
    var shared: EZSharedStorage? {
        .init([
            .init(key: .onboardingChain.onboardingStatus, value: currentStatus),
            .init(key: .onboardingChain.onboardingActions, value: actions)
        ])
    }
}
```

### В дочернем view controller

```swift
class OnboardingStepViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Получаем данные от родителя (иерархия уже построена)
        if let status = ezParentShered[.onboardingChain.onboardingStatus] {
            // Используем статус онбординга от родителя
        }
        
        // Вызываем действия родителя
        ezParentShered[.onboardingChain.onboardingActions]?.next()
    }
}
```

### В Pack Interactor (для удобства)

Если вы используете Pack API, то `EZUIPackInteractorProtocol` уже предоставляет свойство `shared`:

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

## Следующие шаги

- [Установка шаблона](../Templates/README.md) — автоматическая генерация Pack
- [Главная страница модуля](../README.md) — полный список возможностей
