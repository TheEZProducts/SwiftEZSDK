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

**Запуск** — см. [transit() и asyncTransit()](../README.md#запуск-перехода-transit-и-asynctransit).

---

## Дополнительные сценарии

Общие для всех переходов концепции (кастомные анимации, async/await, защита от повторного вызова) описаны в [Общие концепции переходов](../README.md).

### Present из контейнера (EZContainerView)

При present из `EZContainerView` стиль презентации фиксирован (контекст контейнера), зато можно использовать те же методы анимации и completion. Удобно для вложенных экранов внутри одного контейнера.

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) — готовые анимации (ezOpen, ezClose, ezShift и др.).
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController (push/pop и др.).
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
- [EZCustomTransition](../EZCustomTransition/README.md) — кастомные переходы через EZTransitionController.
