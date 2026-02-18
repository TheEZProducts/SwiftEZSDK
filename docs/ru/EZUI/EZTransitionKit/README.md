# EZTransition — Система переходов

Модуль `EZTransitionKit` предоставляет единую систему переходов для управления навигацией между экранами. Точка входа — свойство **`ezTransit`** у `UIViewController` или `EZContainerView`.

---

## Разделы

| Раздел | Описание |
|--------|----------|
| [EZTransition](EZTransition/README.md) | Точка входа: `ezTransit` и `EZTransition<Container>` |
| [EZBaseTransition](EZBaseTransition/README.md) | Модальные переходы: present / dismiss |
| [EZNavigationTransition](EZNavigationTransition/README.md) | Переходы в UINavigationController |
| [EZTabBarTransition](EZTabBarTransition/README.md) | Переходы для UITabBarController |
| [EZPageTransition](EZPageTransition/README.md) | Переходы для UIPageViewController |
| [EZReplaceTransition](EZReplaceTransition/README.md) | Универсальная замена контроллера |
| [EZCustomTransition](EZCustomTransition/README.md) | Кастомные переходы через EZTransitionController |
| [EZTransitionAnimations](EZTransitionAnimations/README.md) | Готовые анимации переходов |

---

## Общие концепции

1. [Fluent API](#fluent-api)
2. [Запуск перехода: transit() и asyncTransit()](#запуск-перехода-transit-и-asynctransit)
3. [Защита от повторного вызова](#защита-от-повторного-вызова)
4. [Кастомные анимации](#кастомные-анимации)
5. [Готовые анимации](#готовые-анимации)

---

## Fluent API

Все переходы настраиваются цепочкой вызовов. Каждый метод возвращает переход с обновлённым контекстом:

```swift
viewController.ezTransit.navigationPush(detailVC)
    .animation(.ezOpen(direction: .right))
    .completion { print("Готово") }
    .transit()
```

---

## Запуск перехода: transit() и asyncTransit()

Каждый переход завершается вызовом одного из двух методов:

- **`transit() -> Bool`** — выполнить переход синхронно; возвращает `true`, если переход запущен, и `false`, если нет (нет контейнера, уже идёт другой переход, некорректные параметры и т.д.).
- **`asyncTransit() async -> Bool`** (iOS 13+) — выполнить переход и дождаться его завершения через `completion`; возвращает `true`, если переход был успешно инициирован.

```swift
let success = await viewController.ezTransit.present(detailVC)
    .animation(.coverVertical)
    .asyncTransit()

if success {
    print("Экран показан")
}
```

Если переход не удалось запустить, `asyncTransit()` вернёт `false` немедленно.

---

## Защита от повторного вызова

По умолчанию повторный вызов `transit()` во время уже идущего перехода не выполняется и возвращает `false`. Для особых случаев можно вызвать **`unsafeTransition()`** (или **`safeTransition(false)`**, где доступно) — тогда проверка игнорируется:

```swift
viewController.ezTransit.navigationPush(detailVC)
    .unsafeTransition()
    .animate()
    .transit()
```

---

## Кастомные анимации

Вместо системных стилей можно передать свою анимацию — класс, реализующий `UIViewControllerAnimatedTransitioning`. Минимальный пример:

```swift
final class FadeAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toView = ctx.view(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }
        toView.alpha = 0
        ctx.containerView.addSubview(toView)
        UIView.animate(withDuration: 0.3, animations: {
            toView.alpha = 1
        }) { _ in
            ctx.completeTransition(!ctx.transitionWasCancelled)
        }
    }
}

// Использование:
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(FadeAnimation())
    .transit()
```

Кастомная анимация передаётся через метод **`.animation(UIViewControllerAnimatedTransitioning)`**, который автоматически включает анимацию (не нужно вызывать `.animate()` дополнительно).

---

## Готовые анимации

В EZTransitionKit доступны встроенные анимации с `ez`-префиксом. Подробнее см. [EZTransitionAnimations](EZTransitionAnimations/README.md).

| Фабрика | Описание |
|---------|----------|
| `.ezOpen(direction:duration:)` | Slide-in: новый экран выезжает из указанного направления, текущий слегка сдвигается в противоположную сторону. |
| `.ezClose(direction:duration:)` | Slide-out: текущий экран уезжает в указанном направлении, нижний экран возвращается на место. |
| `.ezShift(direction:duration:)` | Параллельный сдвиг: новый экран выезжает, старый уезжает в противоположную сторону (для табов и навигации). |
| `.ezAppearance` / `.ezAppearance(duration:)` | Fade-in (alpha 0 → 1). |
| `.ezDisappearance` / `.ezDisappearance(duration:)` | Fade-out (alpha 1 → 0). |

```swift
// Примеры использования:
.animation(.ezOpen(direction: .up))
.animation(.ezClose(direction: .down))
.animation(.ezShift(direction: .left))
.animation(.ezAppearance)
```
