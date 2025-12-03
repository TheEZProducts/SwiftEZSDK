//
//  EZThreadSafetyTest.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import XCTest
import EZAsyncKit

final class EZAsyncKitTest: XCTestCase, @unchecked Sendable {
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ThreadSafety_Async() async{
        @EZThreadSafety var testValue: String = "Hello"
        
        print("test_ThreadSafety_Async start")
        let t1 = Task.detached {[testValue = $testValue, weak self] in
            print("t1", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t1", "end")
            return testValue
        }
        let t2 = Task.detached {[testValue = $testValue, weak self] in
            print("t2", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t2", "end")
            return testValue
        }
        let t3 = Task.detached {[testValue = $testValue, weak self] in
            print("t3", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t3", "end")
            return testValue
        }
        _ = await (t1.value, t2.value, t3.value)
        print("test_ThreadSafety_Async end")
    }
    
    private func addTestValueAsync(value: EZThreadSafety<String>, i: Int) async {
        await value.update{ $0 + "\(i)" }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ThreadSafety_Sync() async{
        @EZThreadSafety var testValue: String = "Hello"
        
        print("test_ThreadSafety_Sync start")
        let t1 = Task.detached {[testValue = $testValue, weak self] in
            print("t1", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t1", "end")
            return testValue
        }
        let t2 = Task.detached {[testValue = $testValue, weak self] in
            print("t2", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t2", "end")
            return testValue
        }
        let t3 = Task.detached {[testValue = $testValue, weak self] in
            print("t3", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t3", "end")
            return testValue
        }
        _ = await (t1.value, t2.value, t3.value)
        print("test_ThreadSafety_Sync end")
    }

    private func addTestValueSync(value: EZThreadSafety<String>, i: Int) {
        value.update{ $0 + "\(i)" }
    }
    
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ezWithCheckedStoppableContinuation_cancelBuforeStart() async {
        let task: Task<Int?, Never> = Task {
            try? await Task.sleep(for: .seconds(1))
            XCTAssertEqual(Task.isCancelled, true, "Task.isCancelled != true")
            if Task.isCancelled != true { return 1 }
            let continuationContainer = EZSendableWrapper<EZSafeContinuation<Int>?>(wrappedValue: nil)
            let result = try? await ezWithCheckedStoppableContinuation { continuation in
                continuationContainer.wrappedValue = continuation
            }
            _ = continuationContainer.wrappedValue
            return result
        }
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, nil, "Task.isCancelled != true")
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ezWithCheckedStoppableContinuation_cancelAfterStart() async {
        let task: Task<Int?, Never> = Task {
            XCTAssertEqual(Task.isCancelled, false, "Task.isCancelled != true")
            if Task.isCancelled == true { return 1 }
            let continuationContainer = EZSendableWrapper<EZSafeContinuation<Int>?>(wrappedValue: nil)
            let result = try? await ezWithCheckedStoppableContinuation { continuation in
                continuationContainer.wrappedValue = continuation
            }
            _ = continuationContainer.wrappedValue
            return result
        }
        try? await Task.sleep(for: .seconds(1))
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result, nil, "Task.isCancelled != true")
    }
    
    
    func test_EZChannel_setBeforeGet() async throws {
        let channel = EZChannel<Int>()
        
        // Запускаем set в отдельном таске, чтобы он не блокировал текущий поток
        let setTask = Task {
            try await channel.set(42)
        }
        
        // Дальше сразу вызываем get — он должен получить 42 без ожидания
        let value = try await channel.get()
        XCTAssertEqual(value, 42, "get() должен сразу вернуть значение, установленное ранее через set()")
        
        // Ждём, чтобы set-таск корректно завершился
        _ = try await setTask.value
    }
    
    /// 2) Сценарий: сначала get, затем set.
    func test_EZChannel_GetBeforeSet() async throws {
        let channel = EZChannel<String>()
        
        // Запускаем get в отдельном таске — он приостановится в ожидании set
        let getTask = Task<String, Error> {
            try await channel.get()
        }
        
        // Дадим чуть времени, чтобы точно войти в состояние ожидания
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 с
        
        // Теперь устанавливаем значение
        try await channel.set("hello")
        
        // getTask должен вернуться сразу после set
        let result = try await getTask.value
        XCTAssertEqual(result, "hello", "get() должен вернуть значение, установленное через set()")
    }
    
    /// 3) Несколько последовательных пар set/get.
    func test_EZChannel_MultipleValues() async throws {
        let channel = EZChannel<Int>()
        let count = 5
        
        for i in 0..<count {
            // для каждого i сначала запускаем get, потом даём set
            let getTask = Task<Int, Error> { try await channel.get() }
            
            // чуть задержимся, имитируя асинхронность
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 с
            
            try await channel.set(i)
            
            let value = try await getTask.value
            XCTAssertEqual(value, i, "Для итерации \(i) канал должен корректно передать и вернуть число \(i)")
        }
    }

    
    func testConcurrentStress() async throws {
        let channel = EZChannel<Int>()
        let totalPairs = 100_000
        
        // Актор-коллектор для безопасного накопления результатов
        actor Collector {
            var values: [Int] = []
            func append(_ v: Int) { values.append(v) }
            func allValues() -> [Int] { values }
        }
        let collector = Collector()
        
//        let t = Task.detached {
//            for i in (0..<totalPairs) {
//                let v = try await channel.get()
//                await collector.append(v)
//                print(i, v)
//            }
//            print("end")
//        }
        
//        let t = Task.detached {
//            for i in (0..<totalPairs) {
//                try await channel.set(i)
//            }
//        }
        // Запускаем 2*totalPairs тасков: попарно set(i) и get()->i
        var tasks: [Task<Void, Error>] = (0..<totalPairs).flatMap { i in
            [
                // producer
                Task.detached {
                    try await channel.set(i)
                },
                // consumer
                Task.detached {
                    let v = try await channel.get()
                    await collector.append(v)
                }
            ]
        }
//        tasks.append(t)
        
        // Ждём завершения всех тасков
        for task in tasks {
            try await task.value
        }
        
        // Сравниваем полученные результаты
        let received = await collector.allValues()
        XCTAssertEqual(received.count, totalPairs,
                       "Должно быть ровно \(totalPairs) полученных значений")
        
        // Проверяем, что набор полученных совпадает с 0..<totalPairs
        let sorted = received.sorted()
        XCTAssertEqual(sorted, Array(0..<totalPairs),
                       "Все значения 0..<\(totalPairs) должны быть получены ровно по одному разу")
    }
    
    /// (Опционально) Измеряем пропускную способность канала.
    func testPerformanceUnderLoad() async throws {
        let channel = EZChannel<Int>()
        let totalOps = 50_000
        
        measure {
            let group = DispatchGroup()
            for i in 0..<totalOps {
                group.enter()
                Task.detached {
                    try await channel.set(i)
                    group.leave()
                }
                group.enter()
                Task.detached {
                    _ = try? await channel.get()
                    group.leave()
                }
            }
            // ждём на Concurrent DispatchGroup
            group.wait()
        }
    }
}
