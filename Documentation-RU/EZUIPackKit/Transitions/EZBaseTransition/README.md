# EZBaseTransition — Базовые переходы

`EZBaseTransition` — это набор базовых переходов для модального открытия и закрытия экранов. Работает как с полноэкранной презентацией от `UIViewController`, так и с показом контроллера внутри `EZContainerView`.

---

## Содержание

1. [Введение](#введение)
2. [Базовый пример](#базовый-пример)
3. [Доступные переходы через ezTransit](#доступные-переходы-через-eztransit)
4. [Параметры перехода](#параметры-перехода)
5. [Дополнительные сценарии](#дополнительные-сценарии)
6. [Связанные темы](#связанные-темы)

---

## Введение

Базовые переходы включают два типа:

- **EZPresentTransition** — модальное открытие экрана (present).
- **EZDismissTransition** — модальное закрытие экрана (dismiss).

Для обоих доступны:

- стиль презентации (fullScreen, pageSheet и др.);
- системные или кастомные анимации;
- completion-обработчик по завершении;
- интерактивные переходы (свайп и т.п.);
- асинхронный запуск через `asyncTransit()` (async/await).

Точка входа — свойство **`ezTransit`**: у `UIViewController` и у `EZContainerView`. От него вызываются `present(...)` или `dismiss()`.

---

## Базовый пример

**Открытие экрана от ViewController:**

```swift
let detailVC = DetailViewController()
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(.coverVertical)
    .transit()
```

**Закрытие текущего экрана:**

```swift
presentedVC.ezTransit.dismiss()
    .animate()
    .completion { print("Экран закрыт") }
    .transit()
```

**Открытие в контейнере (EZContainerView):**

```swift
containerView.ezTransit.present(childVC)
    .animate()
    .transit()
```

Цепочка вызовов настраивает переход; **`transit()`** выполняет его и возвращает `true`, если переход запущен, и `false`, если нет (например, уже идёт другой переход).

---

## Доступные переходы через ezTransit

### От UIViewController

| Вызов | Описание |
|-------|----------|
| `viewController.ezTransit.present(otherVC)` | Модально показать другой ViewController поверх текущего. Стиль и анимация задаются методами контекста. |
| `viewController.ezTransit.dismiss()` | Закрыть текущий модально представленный экран. Вызывается у того контроллера, который нужно закрыть. |

### От EZContainerView

| Вызов | Описание |
|-------|----------|
| `containerView.ezTransit.present(vc)` | Показать ViewController внутри контейнера. Презентация идёт в контексте контейнера (без полноэкранных стилей вроде pageSheet). |

У созданного перехода затем вызываются методы из раздела [Параметры перехода](#параметры-перехода), а в конце — **`transit()`** (или **`asyncTransit()`**).

---

## Параметры перехода

Все методы возвращают тот же переход (или новый с обновлённым контекстом), поэтому их можно объединять в цепочку.

| Метод | Влияние на переход |
|-------|--------------------|
| **`presentationStyle(_ value: UIModalPresentationStyle)`** | Стиль модальной презентации: `.fullScreen`, `.pageSheet`, `.formSheet`, `.overFullScreen` и т.д. Только для present от `UIViewController`. |
| **`animation(_ value: UIModalTransitionStyle)`** | Системная анимация появления/исчезновения: `.coverVertical`, `.crossDissolve`, `.flipHorizontal`. Включает анимацию (как будто вызван `animate()`). |
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Кастомная анимация (своя реализация или готовые `.ezOpen(direction:)` / `.ezClose(direction:)`). Также включает анимацию. |
| **`animate()`** | Включить анимацию перехода. Без него present/dismiss выполняется без анимации. |
| **`completion(_ value: () -> Void)`** | Closure, вызываемый по завершении перехода (успешном или отменённом). |
| **`unsafeTransition()`** | Разрешить запуск перехода во время другого перехода. По умолчанию повторный вызов в такой ситуации блокируется и `transit()` вернёт `false`. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Обработчик интерактивного перехода: в closure передаётся объект, которым можно управлять прогрессом (свайп назад и т.п.). |

**Запуск:**

- **`transit() -> Bool`** — выполнить переход на текущем потоке; возвращает `true`, если переход запущен.
- **`asyncTransit() async -> Bool`** (iOS 13+) — выполнить переход и дождаться его завершения; возвращает `true`, если переход был успешно инициирован.

---

## Дополнительные сценарии

### Кастомная анимация

Вместо системного стиля можно передать свою анимацию — класс, реализующий `UIViewControllerAnimatedTransitioning`. Минимальный пример:

```swift
final class FadeAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        toView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toView.alpha = 1
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// Использование:
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(FadeAnimation())
    .transit()
```

В EZUIPackKit по умолчанию доступны анимации кастомные анимации, для удобства они помечены ez префиксом. Пример:

```swift
.animation(.ezOpen(direction: .up))
.animation(.ezClose(direction: .down))
```

### Ожидание завершения перехода (async/await)

Если нужно дождаться окончания present/dismiss:

```swift
let success = await viewController.ezTransit.present(detailVC)
    .animation(.coverVertical)
    .asyncTransit()

if success {
    print("Экран показан")
}
```

Если переход не удалось запустить (например, уже идёт другой), `asyncTransit()` вернёт `false`.

### Защита от повторного вызова

По умолчанию повторный вызов `transit()` во время уже идущего перехода не выполняется и возвращает `false`. Для особых случаев можно вызвать **`unsafeTransition()`** — тогда проверка игнорируется.

### Present из контейнера (EZContainerView)

При present из `EZContainerView` стиль презентации фиксирован (контекст контейнера), зато можно использовать те же методы анимации и completion. Удобно для вложенных экранов внутри одного контейнера.

---

## Связанные темы

- [EZCustomTransition](../EZCustomTransition/README.md) — кастомные переходы через EZTransitionController.
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController (push/pop и др.).

Кастомные анимации переходов (в том числе ezOpen/ezClose) описываются в документации по анимациям EZUIPackKit.
