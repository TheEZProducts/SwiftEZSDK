# EZNavigationTransition — Переходы в UINavigationController

`EZNavigationTransition` — набор переходов для `UINavigationController`: push, pop, popTo, popToRoot, set, replace, replaceTop. Точка входа — свойство **`ezTransit`** у `UIViewController`. Лучше всего вызывать **`ezTransit`** у самого навигационного контроллера; при необходимости можно вызвать и у дочернего VC — навигация будет найдена по стеку (`navigationController`).

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

Доступны семь типов переходов:

- **Движение по стеку:** push, pop, popTo, popToRoot.
- **Замена стека:** set, replace, replaceTop.

Для всех переходов доступны:

- кастомные анимации через `UIViewControllerAnimatedTransitioning`;
- completion по завершении перехода;
- интерактивные переходы (свайп и т.п.);
- асинхронный запуск через `asyncTransit()` (async/await).

Контейнер — только **`UIViewController`**. Рекомендуемый вариант — вызывать переход у самого **`UINavigationController`** (`navigationController.ezTransit.navigationPush(...)`). Дополнительно поддерживается вызов у дочернего контроллера стека — навигация подставится сама (`childVC.ezTransit.navigationPush(...)` найдёт родителя по `childVC.navigationController`).

Контекст — **`EZChildTransitionContext`**: без стилей модальной презентации, только кастомная анимация или `animate()`.

---

## Базовый пример

Во всех примерах ниже **`ezTransit`** вызывается у навигационного контроллера — это основной и самый удобный вариант. При необходимости тот же вызов можно сделать у дочернего VC (например, у текущего экрана): навигация подставится автоматически.

**Push экрана:**

```swift
let detailVC = DetailViewController()
navigationController.ezTransit.navigationPush(detailVC)
    .animation(.ezOpen(direction: .right))
    .transit()
```

**Pop текущего экрана:**

```swift
navigationController.ezTransit.navigationPop()
    .animate()
    .completion { print("Экран закрыт") }
    .transit()
```

**Полная замена стека (popToRoot или set):**

```swift
navigationController.ezTransit.navigationPopToRoot()
    .animate()
    .transit()

// или задать новый стек явно:
navigationController.ezTransit.navigationSet([rootVC, vc1, vc2])
    .animate()
    .transit()
```

Цепочка настраивает переход; **`transit()`** выполняет его и возвращает `true`, если переход запущен, и `false`, если нет (нет UINavigationController, уже идёт другой переход, некорректный стек и т.д.).

---

## Доступные переходы через ezTransit

Переход лучше вызывать у **`UINavigationController`** (`navigationController.ezTransit....`). Можно вызвать и у дочернего VC — навигация будет найдена по стеку. Далее к цепочке применяются методы из раздела [Параметры перехода](#параметры-перехода), в конце — **`transit()`** или **`asyncTransit()`**.

### Движение по стеку

| Вызов | Описание |
|-------|----------|
| `navigationController.ezTransit.navigationPush(_ controller)` | Положить контроллер на вершину стека. В аргументе не должен быть `UINavigationController`. |
| `navigationController.ezTransit.navigationPop()` | Убрать верхний контроллер со стека. |
| `navigationController.ezTransit.navigationPopTo(_ controller)` | Pop до указанного контроллера (он должен быть в стеке). |
| `navigationController.ezTransit.navigationPopToRoot()` | Pop до корневого контроллера стека. |

### Замена стека

| Вызов | Описание |
|-------|----------|
| `navigationController.ezTransit.navigationSet(_ controllers: [UIViewController])` | Полная замена стека массивом контроллеров. В массиве не должно быть `UINavigationController`. |
| `replacedVC.ezTransit.navigationReplace(_ controller)` | Заменить **текущий** контроллер на другой. Вызывается у **заменяемого** VC (навигация подставится по стеку); на его место подставляется переданный контроллер. |
| `navigationController.ezTransit.navigationReplaceTop(_ controller)` | Заменить только **верхний** экран стека. |

---

## Параметры перехода

Все методы возвращают тот же переход (или новый с обновлённым контекстом), поэтому их можно объединять в цепочку.

| Метод | Влияние на переход |
|-------|--------------------|
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Кастомная анимация (своя реализация или готовые `.ezOpen(direction:)` / `.ezClose(direction:)`). Включает анимацию (как будто вызван `animate()`). |
| **`animate()`** | Включить анимацию перехода. Без него переход выполняется без анимации. |
| **`completion(_ value: () -> Void)`** | Closure, вызываемый по завершении перехода (через `transitionCoordinator.animate(..., completion:)`). |
| **`safeTransition(_ value: Bool)`** | По умолчанию переход безопасный (`safeTransition(true)`): повторный вызов во время другого перехода блокируется. Явный «небезопасный» режим — `unsafeTransition()` или `safeTransition(false)`. |
| **`unsafeTransition()`** | Разрешить запуск перехода во время другого перехода. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Обработчик интерактивного перехода: в closure передаётся объект для управления прогрессом (свайп назад и т.п.). |

Методы **`animation(...)`** и **`animate()`** ведут себя согласованно: `animation(UIViewControllerAnimatedTransitioning)` автоматически включает анимацию, отдельно вызывать `animate()` после него не нужно.

**Запуск** — см. [transit() и asyncTransit()](../README.md#запуск-перехода-transit-и-asynctransit).

---

## Дополнительные сценарии

Общие для всех переходов концепции (кастомные анимации, async/await, защита от повторного вызова) описаны в [Общие концепции переходов](../README.md).

### Когда transit() возвращает false

`transit()` возвращает `false`, если:

- нет доступного `UINavigationController`;
- уже идёт другой переход и не использован `unsafeTransition()`;
- для push/set/replace: в стек или в аргумент передаётся `UINavigationController` (пушить NC нельзя);
- для popTo: целевой контроллер не найден в стеке;
- для replace: текущий контроллер не в стеке навигации (replace вызывается у заменяемого VC);
- для replaceTop: нет `topViewController` и т.п.

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) — готовые анимации (ezOpen, ezClose, ezShift и др.).
- [EZBaseTransition](../EZBaseTransition/README.md) — базовые модальные переходы (present/dismiss).
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
- [EZCustomTransition](../EZCustomTransition/README.md) — кастомные переходы через EZTransitionController.
