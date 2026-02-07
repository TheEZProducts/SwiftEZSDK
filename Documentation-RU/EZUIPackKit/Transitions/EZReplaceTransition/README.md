# EZReplaceTransition — Универсальная замена контроллера

`EZReplaceTransition` — универсальный переход, который автоматически определяет способ замены контроллера в зависимости от типа родительского контейнера.

---

## Использование

```swift
viewController.ezTransit.replace(newVC)
    .animate()
    .transit()
```

Метод **`replace`** проверяет `controller.parent`:

- Если родитель — `UINavigationController` → используется [`navigationReplace`](../EZNavigationTransition/README.md).
- Иначе → используется [`tabBarReplace`](../EZTabBarTransition/README.md).

Возвращаемый тип — `any EZReplaceTransitionProtocol<EZChildTransitionContext>`, поэтому доступны все параметры [EZChildTransitionContext](../README.md#fluent-api): `animation()`, `animate()`, `completion()`, `safeTransition()`, `unsafeTransition()`, `interactive()`.

---

## Когда использовать

`replace` удобен, если вы не знаете заранее, в каком контейнере находится контроллер. Если контейнер известен, рекомендуется вызывать конкретный переход напрямую:

```swift
// Navigation
viewController.ezTransit.navigationReplace(newVC).animate().transit()

// TabBar
viewController.ezTransit.tabBarReplace(newVC).animate().transit()
```

---

## Связанные темы

- [EZNavigationTransition](../EZNavigationTransition/README.md) — `navigationReplace`, `navigationReplaceTop`.
- [EZTabBarTransition](../EZTabBarTransition/README.md) — `tabBarReplace`.
- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit().
