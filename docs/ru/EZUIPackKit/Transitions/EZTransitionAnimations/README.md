# EZTransitionAnimations — Готовые анимации переходов

EZUIPackKit содержит набор готовых анимаций, реализующих `UIViewControllerAnimatedTransitioning`. Все они доступны через фабричные методы с `ez`-префиксом.

---

## Содержание

1. [EZAnimationDirection](#ezanimationdirection)
2. [EZOpenAnimation](#ezopenanimation)
3. [EZCloseAnimation](#ezcloseanimation)
4. [EZShiftAnimation](#ezshiftanimation)
5. [EZAppearanceAnimation](#ezappearanceanimation)
6. [EZDisappearanceAnimation](#ezdisappearanceanimation)
7. [Связанные темы](#связанные-темы)

---

## EZAnimationDirection

Перечисление направлений для анимаций:

| Значение | Описание |
|----------|----------|
| `.up` | Сверху |
| `.down` | Снизу |
| `.right` | Справа |
| `.left` | Слева |

---

## EZOpenAnimation

Slide-in анимация: новый экран выезжает из указанного направления, текущий слегка сдвигается (на 30%) в противоположную сторону.

| Свойство | Значение по умолчанию |
|----------|-----------------------|
| `direction` | `.up` |
| `duration` | `0.5` сек |

**Фабрики:**

```swift
.ezOpen                                    // direction: .up, duration: 0.5
.ezOpen(direction: .right)                 // direction: .right, duration: 0.5
.ezOpen(direction: .left, duration: 0.3)   // direction: .left, duration: 0.3
```

**Пример:**

```swift
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(.ezOpen(direction: .up))
    .transit()
```

---

## EZCloseAnimation

Slide-out анимация: текущий экран уезжает в указанном направлении, нижний экран возвращается на место (из позиции 30% смещения).

| Свойство | Значение по умолчанию |
|----------|-----------------------|
| `direction` | `.up` |
| `duration` | `0.5` сек |

**Фабрики:**

```swift
.ezClose                                    // direction: .up, duration: 0.5
.ezClose(direction: .down)                   // direction: .down, duration: 0.5
.ezClose(direction: .left, duration: 0.3)    // direction: .left, duration: 0.3
```

**Пример:**

```swift
presentedVC.ezTransit.dismiss()
    .animation(.ezClose(direction: .down))
    .transit()
```

> **Совет:** Обычно `EZOpenAnimation` и `EZCloseAnimation` используются парой: open для present, close для dismiss (с тем же направлением).

---

## EZShiftAnimation

Параллельный сдвиг: новый экран выезжает из указанного направления, старый уезжает в противоположную сторону (полное смещение на 100%). Подходит для переключения табов и навигации.

| Свойство | Значение по умолчанию |
|----------|-----------------------|
| `direction` | `.left` |
| `duration` | `0.5` сек |

**Фабрика:**

```swift
.ezShift(direction: .left)                  // direction: .left, duration: 0.5
.ezShift(direction: .right, duration: 0.3)  // direction: .right, duration: 0.3
```

**Пример:**

```swift
tabBarController.ezTransit.tabBarNext()
    .animation(.ezShift(direction: .left))
    .transit()
```

---

## EZAppearanceAnimation

Fade-in анимация: новый экран появляется с alpha 0 → 1.

| Свойство | Значение по умолчанию |
|----------|-----------------------|
| `duration` | `0.2` сек |

**Фабрики:**

```swift
.ezAppearance                    // duration: 0.2
.ezAppearance(duration: 0.5)     // duration: 0.5
```

**Пример:**

```swift
viewController.ezTransit.present(detailVC)
    .presentationStyle(.overFullScreen)
    .animation(.ezAppearance)
    .transit()
```

---

## EZDisappearanceAnimation

Fade-out анимация: текущий экран исчезает с alpha 1 → 0.

| Свойство | Значение по умолчанию |
|----------|-----------------------|
| `duration` | `0.2` сек |

**Фабрики:**

```swift
.ezDisappearance                    // duration: 0.2
.ezDisappearance(duration: 0.5)     // duration: 0.5
```

**Пример:**

```swift
presentedVC.ezTransit.dismiss()
    .animation(.ezDisappearance)
    .transit()
```

> **Совет:** `EZAppearanceAnimation` и `EZDisappearanceAnimation` используются парой: appearance для present, disappearance для dismiss.

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), создание своих анимаций.
- [EZBaseTransition](../EZBaseTransition/README.md) — модальные переходы (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController.
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
