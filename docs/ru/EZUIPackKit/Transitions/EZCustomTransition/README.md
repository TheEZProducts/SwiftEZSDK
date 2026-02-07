# EZCustomTransition - Кастомные переходы

`EZCustomTransition` предоставляет механизм делегирования переходов родительским контроллерам в иерархии ViewController'ов. Дочерние экраны могут отправлять события о своем состоянии и передавать параметры, а родительские контроллеры обрабатывают эти события и выполняют соответствующие переходы.

---

## Содержание

1. [Введение](#введение)
2. [Быстрый старт](#быстрый-старт)
3. [Основные компоненты](#основные-компоненты)
4. [Методы настройки](#методы-настройки)
5. [Примеры](#примеры)

---

## Введение

Кастомные переходы (`EZCustomTransition`) позволяют дочерним экранам делегировать управление переходами своим родительским контроллерам. Это особенно полезно для:

- **Модальных окон** — дочерний экран может сообщить родителю о необходимости закрытия или перехода к следующему экрану
- **Навигационных стеков** — дочерний экран может запросить переход к следующему экрану или возврат назад
- **Онбординга** — каждый экран онбординга может отправлять события (`ezNext`, `ezBack`), а родительский навигационный контроллер обрабатывает их и управляет потоком

**Как это работает:**

1. **Дочерний экран** отправляет событие через `ezTransit.custom()` с указанием типа перехода (`.ezNext`, `.ezBack` и т.д.)
2. **Система ищет** `transitionController` в иерархии ViewController'ов согласно `transitionDelegateSearchType`
3. **Родительский контроллер** получает событие через реализацию `EZTransitionControllerDelegateProtocol` и выполняет соответствующий переход

---

## Быстрый старт

Рассмотрим полный пример использования с онбордингом:

```swift
// Родительский контроллер реализует протокол обработки переходов
class OnboardingNavigationController: UINavigationController, EZTransitionControllerDelegateProtocol {
    private let onboardingSteps: [UIViewController.Type] = [
        OnboardingStep1ViewController.self,
        OnboardingStep2ViewController.self,
        OnboardingStep3ViewController.self
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Создаем и настраиваем первый экран онбординга с transition controller
        let step1 = OnboardingStep1ViewController()
            .apply(template: .custom {
                $0.transitionController = .delegate(self)
            })
        
        self.setViewControllers([step1], animated: false)
    }
    
    // Реализуем обработку переходов
    func transit(context: EZCustomTransitionContext) -> Bool {
        switch context.transitionType {
        case .ezNext:
            return handleNext(context: context)
        case .ezBack:
            return handleBack(context: context)
        default:
            return false
        }
    }
    
    private func handleNext(context: EZCustomTransitionContext) -> Bool {
        // Определяем текущий индекс экрана по количеству экранов в стеке
        let currentIndex = self.viewControllers.count - 1
        
        // Проверяем, есть ли следующий экран
        if currentIndex + 1 < onboardingSteps.count {
            // Переходим к следующему экрану
            let nextVCType = onboardingSteps[currentIndex + 1]
            let nextVC = nextVCType.init()
                .apply(template: .custom {
                    $0.transitionController = .delegate(self)
                })
            self.pushViewController(nextVC, animated: context.animate)
            return true
        } else {
            // Если это был последний экран - закрываем онбординг
            self.dismiss(animated: context.animate)
            return true
        }
    }
    
    private func handleBack(context: EZCustomTransitionContext) -> Bool {
        if self.viewControllers.count > 1 {
            self.popViewController(animated: context.animate)
            return true
        }
        return false
    }
}

// Дочерние экраны просто отправляют события
class OnboardingStep1ViewController: UIViewController {
    func nextButtonTapped() {
        // Отправляем событие родителю (навигационному контроллеру)
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }
}

class OnboardingStep2ViewController: UIViewController {
    func nextButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }
    
    func backButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezBack)
            .transit()
    }
}

class OnboardingStep3ViewController: UIViewController {
    func finishButtonTapped() {
        // Отправляем .ezNext - родитель сам определит, что это последний экран и закроет онбординг
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }
    
    func backButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezBack)
            .transit()
    }
}
```

**Ключевые моменты:**

1. **Родительский контроллер** (`OnboardingNavigationController`) реализует `EZTransitionControllerDelegateProtocol` напрямую
2. **Transition controller устанавливается дочерним экранам** через `.apply(template: .custom { $0.transitionController = .delegate(self) })`
3. **Обработка закрытия** объединена с обработкой `.ezNext` — если это последний экран, родитель сам закрывает онбординг
4. **Дочерние экраны** просто отправляют события через `ezTransit.custom()` с указанием поиска родителя

---

## Основные компоненты

### EZTransitionControllerProtocol

Протокол для объектов, которые могут обрабатывать кастомные переходы. Основной метод:

```swift
@MainActor
public protocol EZTransitionControllerProtocol: AnyObject {
    @discardableResult
    func transit(context: EZCustomTransitionContext) -> Bool
}
```

Метод `transit(context:)` анализирует `context.transitionType` и выполняет соответствующую логику. Возвращает `true`, если переход был обработан, `false` — если нет.

### EZTransitionController

Базовая реализация `EZTransitionControllerProtocol`. Может быть создан с использованием closure или delegate:

```swift
// С closure
let controller = EZTransitionController { context in
    // Обработка переходов
    return true
}

// С delegate
let controller = EZTransitionController(delegate: myDelegate)
```

Для удобной установки на дочерний экран используйте:

```swift
childVC.apply(template: .custom {
    $0.transitionController = .delegate(self)
})
```

### EZCustomTransitionContext

Контекст перехода содержит всю информацию, необходимую для обработки:

- `transitionType` — тип перехода (`.ezNext`, `.ezBack`, `.ezClose` и т.д.)
- `customData` — произвольные данные для передачи
- `fromController` — контроллер, откуда происходит переход
- `toController` — целевой контроллер (если указан)
- `toIndex` — целевой индекс (для переходов по индексу)
- `animate` — нужно ли анимировать переход
- `animation` — кастомная анимация
- `completion` — обработчик завершения

### EZCustomTransitionType

Тип перехода идентифицируется строковым ключом. Предопределенные типы:

- `.ezNext` — переход к следующему элементу
- `.ezBack` — возврат к предыдущему элементу
- `.ezToController` — переход к конкретному контроллеру
- `.ezToIndex` — переход к конкретному индексу
- `.ezOpen` — открытие/презентация
- `.ezClose` — закрытие/дисмисс
- `.ezSuccess` — успешное завершение операции
- `.ezFail` — неудачное завершение операции

Также можно создать кастомный тип через extension:

```swift
extension EZCustomTransitionType {
    static var myCustomType: Self {
        .init(key: "myCustomType")
    }
    
    static func myCustomType(customData: Any) -> Self {
        .init(key: "myCustomType", customData: customData)
    }
}

// Использование
viewController.ezTransit.custom()
    .transitionType(.myCustomType)
    .transit()
```

### Поиск transition controller

Система ищет `transitionController` в иерархии ViewController'ов согласно `transitionDelegateSearchType`:

- **`.selfDelegate`** — поиск только в самом контроллере
- **`.parent`** — поиск в родительском контроллере
- **`.hierarchy`** (по умолчанию) — поиск во всей иерархии (self, parent, presenting и т.д.)

---

## Методы настройки

Все методы настройки возвращают новый экземпляр перехода с обновлёнными параметрами (fluent interface).

| Метод | Описание |
|-------|----------|
| `transitionType(_:)` | Устанавливает тип кастомного перехода (`.ezNext`, `.ezBack` и т.д.) |
| `customData(_:)` | Устанавливает произвольные данные для передачи |
| `transitionDelegateSearchType(_:)` | Устанавливает стратегию поиска transition controller'а (`.parent`, `.hierarchy`, `.selfDelegate`) |
| `animation(_ value: UIViewControllerAnimatedTransitioning)` | Устанавливает кастомную анимацию и автоматически включает анимацию |
| `animation(_ value: UIModalTransitionStyle)` | Устанавливает системную анимацию (`.coverVertical`, `.crossDissolve` и т.д.) и автоматически включает анимацию |
| `animate()` | Включает анимацию для перехода |
| `presentationStyle(_:)` | Устанавливает стиль модальной презентации |
| `completion(_:)` | Устанавливает обработчик завершения перехода |
| `safeTransition(_ value: Bool)` | `true` — блокировать переход во время другого перехода (по умолчанию). `false` — разрешить |
| `unsafeTransition()` | Разрешить запуск перехода во время другого перехода |

**Важно:** Методы `.animation()` автоматически включают анимацию, поэтому после них не нужно вызывать `.animate()`.

**Запуск** — см. [transit() и asyncTransit()](../README.md#запуск-перехода-transit-и-asynctransit).

---

## Примеры

### Пример с модальным окном

Модальное окно запрашивает закрытие у родителя:

```swift
// Родительский контроллер
class ParentViewController: UIViewController, EZTransitionControllerDelegateProtocol {
    func showModal() {
        let modal = ModalViewController()
            .apply(template: .custom {
                $0.transitionController = .delegate(self)
            })
        self.present(modal, animated: true)
    }
    
    func transit(context: EZCustomTransitionContext) -> Bool {
        switch context.transitionType {
        case .ezClose:
            // Закрываем модальное окно (ребенка)
            context.fromController?.dismiss(animated: context.animate)
            return true
        case .ezSuccess:
            // Обрабатываем успешное сохранение
            if let data = context.customData as? [String: Any] {
                // Используем данные
            }
            // Закрываем модальное окно (ребенка)
            context.fromController?.dismiss(animated: context.animate)
            return true
        default:
            return false
        }
    }
}

// Модальное окно
class ModalViewController: UIViewController {
    func closeButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezClose)
            .transit()
    }
    
    func saveButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezSuccess)
            .customData(["saved": true])
            .transit()
    }
}
```

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZBaseTransition](../EZBaseTransition/README.md) — базовые модальные переходы (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController.
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
