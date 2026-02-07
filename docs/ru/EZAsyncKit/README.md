# EZAsyncKit

## Гайд по **Swift Concurrency**

1. [Гайд](AsyncGuide/README.md) - Небольшой гайд по безопасной работе с Swift Concurrency

## Services

1. [EZChannel](Services/EZChannel/EZChannel/README.md) - Безбуферный асинхронный канал
2. [EZBufferedChannel](Services/EZChannel/EZBufferedChannel/README.md) - Буферизированный асинхронный канал
3. [EZAsyncValue](Services/EZAsyncValue/README.md) - Async контейнер для результата

---

## Extensions

1. [Actor](Extensions/Actor%20%2B%20EZ/README.md) - Утилиты для работы с изоляцией акторов и удобного запуска задач с isolated Self
2. [AsyncStream](Extensions/AsyncStream%20%2B%20EZ/README.md) - Хелперы для AsyncStream.Continuation: таймауты, автозавершение и привязка к жизненному циклу
3. [Task](Extensions/Task%20%2B%20EZ/README.md) - Якоря для авто-отмены задач и прокидывание отмены текущей задачи внутрь Task
4. [MainActor](Extensions/MainActor%20%2B%20EZ/README.md) - Unsafe-синхронный вызов @MainActor замыканий из nonisolated контекста


---

## Functions

1. [ezWithCheckedStoppableContinuation](Functions/ezWithCheckedStoppableContinuation/README.md) - Continuation-обёртка с авто-резюмом CancellationError при отмене задачи
2. [ezWithTaskGroup](Functions/ezWithTaskGroup/README.md) - Запуск нескольких EZTaskItem в TaskGroup с возвратом результатов кортежем 
3. [ezWithTaskGroupFirstCompleted](Functions/ezWithTaskGroupFirstCompleted/README.md) - Гонка задач в TaskGroup, возврат первого завершившегося результата (успех или ошибка)
4. [ezWithTaskGroupFirstSuccess](Functions/ezWithTaskGroupFirstSuccess/README.md) - Гонка задач в TaskGroup, возврат первого успешного значения, ошибки игнорируются
5. [ezWithUnstructuredTaskGroup](Functions/ezWithUnstructuredTaskGroup/README.md) - Ожидание набора неструктурированных Task с возвратом результатов кортежем и корректной отменой

---

## Helpers

1. [EZContinuations](Helpers/EZContinuations/README.md) - Унификация resume(...) + безопасные continuation-обёртки для one-shot сценариев

---

## Wrappers

1. [EZActorWrapper](Wrappers/EZActorWrapper/README.md) - Простой actor-контейнер для безопасного хранения и обновления состояния
2. [EZThreadSafety](Wrappers/EZThreadSafety/README.md) - Тред-сейф доступ к значению с sync+async API (actor-изоляция + семафор-мост)
3. [EZSendableWrapper](Wrappers/EZSendableWrapper/README.md) - Semaphored property-wrapper для потокобезопасного доступа к значению + @unchecked обёртка
4. [EZWeakWrapper](Helpers/EZWeakWrapper/README.md) - Weak-обёртка для AnyObject (Sendable, если объект тоже Sendable)
