# EZPageTransition — Переходы для UIPageViewController

`EZPageTransition` — переход для `UIPageViewController`: установка отображаемых контроллеров с указанием направления навигации. Точка входа — свойство **`ezTransit`** у `UIViewController`.

---

## Содержание

1. [Введение](#введение)
2. [Базовый пример](#базовый-пример)
3. [Доступные переходы через ezTransit](#доступные-переходы-через-eztransit)
4. [Параметры перехода](#параметры-перехода)
5. [Когда transit() возвращает false](#когда-transit-возвращает-false)
6. [Связанные темы](#связанные-темы)

---

## Введение

Переход для UIPageViewController устанавливает набор контроллеров с указанием направления (`.forward` / `.reverse`).

Для перехода доступны:

- направление навигации;
- анимация;
- completion по завершении;
- асинхронный запуск через `asyncTransit()` (async/await).

Контейнер — **`UIViewController`**. Рекомендуемый вариант — вызывать переход у самого `UIPageViewController`. Дополнительно поддерживается вызов у дочернего контроллера — page-контроллер подставится автоматически.

Контекст — **`EZPageTransitionContext`**: направление, анимация и completion; без стилей модальной презентации и интерактивных переходов.

---

## Базовый пример

```swift
pageController.ezTransit.pageSet([page1, page2, page3])
    .direction(.forward)
    .animate()
    .transit()
```

Цепочка настраивает переход; **`transit()`** выполняет его и возвращает `true`, если переход запущен, и `false`, если нет.

---

## Доступные переходы через ezTransit

| Вызов | Описание |
|-------|----------|
| `pageController.ezTransit.pageSet(_ controllers: [UIViewController])` | Установить отображаемые контроллеры. |

Далее к цепочке применяются методы из раздела [Параметры перехода](#параметры-перехода), в конце — **`transit()`** или **`asyncTransit()`**.

---

## Параметры перехода

Все методы возвращают переход с обновлённым контекстом, поэтому их можно объединять в цепочку.

| Метод | Влияние на переход |
|-------|--------------------|
| **`direction(_ value: UIPageViewController.NavigationDirection)`** | Направление навигации: `.forward` (по умолчанию) или `.reverse`. |
| **`animate()`** | Включить анимацию перехода. Без него переход выполняется без анимации. |
| **`completion(_ value: () -> Void)`** | Closure, вызываемый по завершении перехода. |
| **`safeTransition(_ value: Bool)`** | По умолчанию переход безопасный: повторный вызов во время другого перехода блокируется. `safeTransition(false)` эквивалентен `unsafeTransition()`. |
| **`unsafeTransition()`** | Разрешить запуск перехода во время другого перехода. |

**Запуск** — см. [transit() и asyncTransit()](../README.md#запуск-перехода-transit-и-asynctransit).

---

## Когда transit() возвращает false

`transit()` возвращает `false`, если:

- нет доступного `UIPageViewController` (ни сам контейнер, ни через `pageController`).

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController.
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
