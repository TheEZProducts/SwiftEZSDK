# EZTabBarTransition — Переходы для UITabBarController

`EZTabBarTransition` — набор переходов для `UITabBarController`: установка табов (set), выбор по контроллеру или индексу (select), следующий/предыдущий таб (next, back), замена таба (replace). Точка входа — свойство **`ezTransit`** у `UIViewController`. Рекомендуемый вызов — у самого таббара; при необходимости можно вызвать у дочернего VC — таббар подставится по `tabBarController`.

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

- **Установка табов:** set (массив или один контроллер).
- **Переключение таба:** select по контроллеру, select по индексу, next, back.
- **Замена:** replace — если контроллер уже в таббаре, выбирается этот таб; иначе заменяется текущий выбранный таб.

Для всех переходов доступны:

- кастомные анимации через `UIViewControllerAnimatedTransitioning`;
- completion по завершении перехода;
- интерактивные переходы (свайп и т.п.);
- асинхронный запуск через `asyncTransit()` (async/await).

Контейнер — только **`UIViewController`**. Рекомендуемый вариант — вызывать переход у самого **`UITabBarController`** (`tabBarController.ezTransit....`). Дополнительно поддерживается вызов у дочернего контроллера (например, у текущего экрана в табе) — таббар подставится сам по `container.tabBarController`.

Контекст — **`EZChildTransitionContext`**: без стилей модальной презентации, только кастомная анимация или `animate()`.

---

## Базовый пример

Во всех примерах ниже **`ezTransit`** вызывается у таббар-контроллера — это основной и самый удобный вариант. При необходимости тот же вызов можно сделать у дочернего VC: таббар подставится автоматически.

**Установка табов:**

```swift
tabBarController.ezTransit.tabBarSet([homeVC, profileVC, settingsVC])
    .animation(.ezShift(direction: .left))
    .transit()
```

**Выбор таба по индексу:**

```swift
tabBarController.ezTransit.tabBarSelect(2)
    .animate()
    .completion { print("Таб выбран") }
    .transit()
```

**Следующий / предыдущий таб:**

```swift
tabBarController.ezTransit.tabBarNext()
    .animate()
    .transit()

// или
tabBarController.ezTransit.tabBarBack()
    .animate()
    .transit()
```

Цепочка настраивает переход; **`transit()`** выполняет его и возвращает `true`, если переход запущен, и `false`, если нет (нет таббара, уже идёт другой переход, next/back на границе и т.д.).

---

## Доступные переходы через ezTransit

Переход лучше вызывать у **`UITabBarController`** (`tabBarController.ezTransit....`). Можно вызвать и у дочернего VC — таббар будет найден по `tabBarController`. Далее к цепочке применяются методы из раздела [Параметры перехода](#параметры-перехода), в конце — **`transit()`** или **`asyncTransit()`**.

### Установка табов

| Вызов | Описание |
|-------|----------|
| `tabBarController.ezTransit.tabBarSet(_ controllers: [UIViewController])` | Заменить все табы массивом контроллеров. |
| `tabBarController.ezTransit.tabBarSet(_ controller: UIViewController)` | Удобный вариант: один контроллер как единственный таб. |

### Переключение и замена таба

| Вызов | Описание |
|-------|----------|
| `tabBarController.ezTransit.tabBarSelect(_ controller: UIViewController)` | Выбрать таб по контроллеру. Контроллер должен входить в `viewControllers` таббара. |
| `tabBarController.ezTransit.tabBarSelect(_ index: Int)` | Выбрать таб по индексу. |
| `tabBarController.ezTransit.tabBarNext()` | Выбрать следующий таб. На последнем табе `transit()` вернёт `false`. |
| `tabBarController.ezTransit.tabBarBack()` | Выбрать предыдущий таб. На первом табе `transit()` вернёт `false`. |
| `tabBarController.ezTransit.tabBarReplace(_ controller: UIViewController)` | Если контроллер уже в таббаре — выбор этого таба; иначе замена **текущего выбранного** таба на этот контроллер. Вызов у дочернего VC (у контейнера должен быть `tabBarController`). |

---

## Параметры перехода

Все методы возвращают тот же переход (или новый с обновлённым контекстом), поэтому их можно объединять в цепочку.

| Метод | Влияние на переход |
|-------|--------------------|
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Кастомная анимация (своя реализация или готовые `.ezShift(direction:)` и др.). Включает анимацию (как будто вызван `animate()`). |
| **`animate()`** | Включить анимацию перехода. Без него переход выполняется без анимации. |
| **`completion(_ value: () -> Void)`** | Closure, вызываемый по завершении перехода. |
| **`safeTransition(_ value: Bool)`** | По умолчанию переход безопасный: повторный вызов во время другого перехода блокируется. Явный «небезопасный» режим — `unsafeTransition()` или `safeTransition(false)`. |
| **`unsafeTransition()`** | Разрешить запуск перехода во время другого перехода. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Обработчик интерактивного перехода: в closure передаётся объект для управления прогрессом (свайп и т.п.). |

Метод **`animation(...)`** автоматически включает анимацию, отдельно вызывать `animate()` после него не нужно.

**Запуск** — см. [transit() и asyncTransit()](../README.md#запуск-перехода-transit-и-asynctransit).

---

## Дополнительные сценарии

Общие для всех переходов концепции (кастомные анимации, async/await, защита от повторного вызова) описаны в [Общие концепции переходов](../README.md).

### Когда transit() возвращает false

`transit()` возвращает `false`, если:

- нет доступного `UITabBarController` (ни сам контейнер, ни `container.tabBarController`);
- уже идёт другой переход и не использован `unsafeTransition()`;
- **tabBarNext:** уже выбран последний таб (`(selectedIndex + 1) >= viewControllers.count`);
- **tabBarBack:** уже выбран первый таб (`selectedIndex - 1 < 0`);
- **tabBarSelect(controller):** переданный контроллер не найден в `viewControllers` таббара;
- **tabBarReplace:** у контейнера нет `tabBarController`; либо контроллер не найден в табах и массив табов пуст или индекс выбранного таба некорректен для замены.

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) — готовые анимации (ezOpen, ezClose, ezShift и др.).
- [EZBaseTransition](../EZBaseTransition/README.md) — базовые модальные переходы (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController (push/pop и др.).
- [EZCustomTransition](../EZCustomTransition/README.md) — кастомные переходы через EZTransitionController.
