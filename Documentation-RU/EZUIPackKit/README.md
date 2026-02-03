# EZUIPackKit

Модуль для построения UI по архитектуре **IMV (Interactor–Mediator–View)**. Обеспечивает чёткое разделение логики, состояния и представления, а также удобную систему переходов между экранами.

---

## Быстрый старт

1. [Быстрый старт](QuickStart/README.md) — Создание первого Pack с нуля

---

## Шаблоны Xcode

1. [Установка и использование шаблона](Templates/README.md) — Как установить и использовать Xcode File Template для IMV

---

## Основные компоненты

| Компонент | Описание |
|-----------|----------|
| `EZUIPack` | Контейнер, объединяющий Interactor, Mediator и View |
| `EZUIPackI` / `EZUIPackInteractor` | Базовый класс Interactor (наследует `UIViewController`) |
| `EZUIPackM` / `EZUIPackMediator` | Базовый класс Mediator (хранит состояние и связывает I и V) |
| `EZUIPackV` / `EZUIPackView` | Базовый класс View (UIKit) |
| `EZUIPackSV` / `EZUIPackSView` | Базовый класс View (SwiftUI) |
| `EZUIPackPlatformsV` | Мультиплатформенный View (iOS, iPadOS, macCatalyst и др.) |

---

## Специализированные Interactor'ы

| Тип | Описание |
|-----|----------|
| `EZUINavigationPackI` | Interactor на базе `UINavigationController` |
| `EZUITabBarPackI` | Interactor на базе `UITabBarController` |
| `EZUIPagePackI` | Interactor на базе `UIPageViewController` |

---

## Wrapper-паки

| Тип | Описание |
|-----|----------|
| `EZUINavigationWrapperPack` | Обёртка для `UINavigationController` без собственной логики |
| `EZUITabBarWrapperPack` | Обёртка для `UITabBarController` без собственной логики |

---

## Переходы

| Класс / Метод | Описание |
|---------------|----------|
| `ezTransit` | Точка входа для системы переходов |
| `navigationPush` / `navigationPop` | Переходы в navigation stack |
| `tabBarSelect` / `tabBarNext` / `tabBarBack` | Переходы между табами |
| `present` / `dismiss` | Модальные переходы |
| `custom` | Кастомные переходы через `EZTransitionController` |

---

## Анимации переходов

| Класс | Описание |
|-------|----------|
| `EZOpenAnimation` | Slide-in анимация с указанием направления |
| `EZCloseAnimation` | Slide-out анимация с указанием направления |
| `EZShiftAnimation` | Сдвиг (для tab bar переходов) |
| `EZAppearanceAnimation` | Fade-in |
| `EZDisappearanceAnimation` | Fade-out |

---

## Полезные ссылки

- [Package.swift](../../Package.swift) — описание модуля в SPM
- [Исходный код](../../Sources/EZUIPackKit/) — реализация модуля
