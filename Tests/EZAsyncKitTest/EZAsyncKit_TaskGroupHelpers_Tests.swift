//
//  EZAsyncKit_TaskGroupHelpers_Tests.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import XCTest

import EZAsyncKit

// MARK: - Structured helpers

final class EZAsyncKit_StructuredTaskGroupHelpers_Tests: XCTestCase {
    private enum TestError: Error {
        case boom
    }

    func test_structuredResults_preservesPositionalMapping() async {
        let (r1, r2, r3) = await ezWithTaskGroup(
            result: .results,
            EZTaskItem {
                try await Task.sleep(nanoseconds: 50_000_000)
                return 42
            },
            EZTaskItem {
                try await Task.sleep(nanoseconds: 10_000_000)
                return "hello"
            },
            EZTaskItem {
                true
            }
        )

        switch r1 {
        case .success(let v): XCTAssertEqual(v, 42)
        case .failure(let e): XCTFail("Unexpected error: \(e)")
        }

        switch r2 {
        case .success(let v): XCTAssertEqual(v, "hello")
        case .failure(let e): XCTFail("Unexpected error: \(e)")
        }

        switch r3 {
        case .success(let v): XCTAssertEqual(v, true)
        case .failure(let e): XCTFail("Unexpected error: \(e)")
        }
    }

    func test_structuredValues_throwsGroupErrorAndContainsResults() async {
        do {
            _ = try await ezWithTaskGroup(
                result: .values,
                EZTaskItem {
                    throw TestError.boom
                },
                EZTaskItem {
                    "ok"
                }
            )
            XCTFail("Expected GroupError")
        } catch let e {
            let (a, b) = e.results

            switch a {
            case .success:
                XCTFail("Expected failure for first result")
            case .failure:
                break
            }

            switch b {
            case .success(let v):
                XCTAssertEqual(v, "ok")
            case .failure(let err):
                XCTFail("Unexpected error: \(err)")
            }
        }
    }

    func test_structuredOptionals_returnsNilForFailures() async {
        let result = await ezWithTaskGroup(
            result: .optionals,
            EZTaskItem {
                throw TestError.boom
            },
            EZTaskItem {
                7
            }
        )

        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, 7)
    }

    func test_structuredBuilderOverload_smoke() async {
        let (r1, r2) = await ezWithTaskGroup(result: .results) {
            EZTaskItem {
                try await Task.sleep(nanoseconds: 5_000_000)
                return 2
            }
            EZTaskItem {
                "b"
            }
        }

        XCTAssertEqual(try? r1.get(), 2)
        XCTAssertEqual(r2.get(), "b")
    }
}

// MARK: - Unstructured helpers

final class EZAsyncKit_UnstructuredTaskGroupHelpers_Tests: XCTestCase {
    private enum TestError: Error {
        case boom
    }

    func test_unstructuredValues_direct_returnsValuesForNeverTasks() async {
        let t1 = Task<Int, Never> {
            try? await Task.sleep(nanoseconds: 10_000_000)
            return 3
        }
        let t2 = Task<String, Never> {
            "c"
        }

        let (a, b) = await ezWithUnstructuredTaskGroup(result: .values, t1, t2)
        XCTAssertEqual(a, 3)
        XCTAssertEqual(b, "c")
    }

    func test_unstructuredValues_builderOverload_smoke() async {
        let (a, b) = await ezWithUnstructuredTaskGroup {
            Task { 3 }
            Task { "c" }
        }

        XCTAssertEqual(a, 3)
        XCTAssertEqual(b, "c")
    }

    func test_unstructuredResults_returnsValuesForCompletion() async {
        let t1 = Task<Int, Error> {
            try await Task.sleep(nanoseconds: 10_000_000)
            return 1
        }
        let t2 = Task<String, Error> {
            try await Task.sleep(nanoseconds: 20_000_000)
            return "a"
        }

        let (r1, r2) = await ezWithUnstructuredTaskGroup(result: .results, t1, t2)

        switch r1 {
        case .success(let v): XCTAssertEqual(v, 1)
        case .failure(let e): XCTFail("Unexpected error: \(e)")
        }

        switch r2 {
        case .success(let v): XCTAssertEqual(v, "a")
        case .failure(let e): XCTFail("Unexpected error: \(e)")
        }
    }

    func test_unstructuredResults_builderOverload_smoke() async {
        let (r1, r2) = await ezWithUnstructuredTaskGroup(result: .results) {
            Task<Int, Error> { 11 }
            Task<String, Error> { "bb" }
        }

        XCTAssertEqual(try? r1.get(), 11)
        XCTAssertEqual(try? r2.get(), "bb")
    }

    func test_unstructuredOptionals_direct_returnsNilForFailures() async {
        let t1 = Task<Int, Error> {
            throw TestError.boom
        }
        let t2 = Task<String, Error> {
            "ok"
        }

        let (a, b) = await ezWithUnstructuredTaskGroup(result: .optionals, t1, t2)
        XCTAssertNil(a)
        XCTAssertEqual(b, "ok")
    }

    func test_unstructuredOptionals_builderOverload_smoke() async {
        let result = await ezWithUnstructuredTaskGroup(result: .optionals) {
            Task { throw TestError.boom }
            Task { 7 }
        }

        XCTAssertNil(result.0)
        XCTAssertEqual(result.1, 7)
    }

    func test_unstructuredValuesThrowing_direct_throwsGroupErrorAndContainsResults() async {
        let t1 = Task<Int, Error> {
            throw TestError.boom
        }
        let t2 = Task<String, Error> {
            "ok"
        }

        do {
            _ = try await ezWithUnstructuredTaskGroup(result: .values, t1, t2)
            XCTFail("Expected GroupError")
        } catch let e {
            let (a, b) = e.results

            switch a {
            case .success:
                XCTFail("Expected failure for first result")
            case .failure:
                break
            }

            switch b {
            case .success(let v):
                XCTAssertEqual(v, "ok")
            case .failure(let err):
                XCTFail("Unexpected error: \(err)")
            }
        }
    }

    func test_unstructuredValuesThrowing_builderOverload_throwsGroupError() async {
        do {
            _ = try await ezWithUnstructuredTaskGroup(result: .values) {
                Task<Int, Error> { throw TestError.boom }
                Task<String, Error> { "ok" }
            }
            XCTFail("Expected GroupError")
        } catch let e {
            let (a, b) = e.results
            XCTAssertNotNil(try? b.get())
            switch a {
            case .success:
                XCTFail("Expected failure for first result")
            case .failure:
                break
            }
        }
    }

    func test_unstructuredCancellation_cancelsUnderlyingTasks() async {
        let e1 = expectation(description: "task1 cancelled")
        let e2 = expectation(description: "task2 cancelled")

        let t1 = Task<Int, Error> {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return 1
            } catch {
                e1.fulfill()
                throw error
            }
        }

        let t2 = Task<String, Error> {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return "never"
            } catch {
                e2.fulfill()
                throw error
            }
        }

        let parent = Task {
            await ezWithUnstructuredTaskGroup(result: .results, t1, t2)
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        parent.cancel()

        let (r1, r2) = await parent.value

        switch r1 {
        case .success:
            XCTFail("Expected cancellation failure")
        case .failure(let err):
            XCTAssertTrue(err is CancellationError)
        }

        switch r2 {
        case .success:
            XCTFail("Expected cancellation failure")
        case .failure(let err):
            XCTAssertTrue(err is CancellationError)
        }

        await fulfillment(of: [e1, e2], timeout: 2.0)
    }
}

// MARK: - First-completed / first-success helpers

final class EZAsyncKit_TaskGroupFirstResult_Success_Tests: XCTestCase {
    private enum TestError: Error { case boom }

    func test_firstCompleted_variadic_successReturnsFirstCompletion() async {
        let result = await ezWithTaskGroupFirstCompleted(
            result: .results,
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 40_000_000)
                return 1
            },
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 10_000_000)
                return 2
            }
        )

        XCTAssertEqual(try? result?.get(), 2)
    }

    func test_firstCompleted_arrayOverload_successReturnsFirstCompletion() async {
        let ops: [EZTaskItem<Int, Error>] = [
            EZTaskItem {
                try await Task.sleep(nanoseconds: 30_000_000)
                return 10
            },
            EZTaskItem {
                try await Task.sleep(nanoseconds: 5_000_000)
                return 20
            }
        ]

        let result = await ezWithTaskGroupFirstCompleted(result: .results, ops)
        XCTAssertEqual(try? result?.get(), 20)
    }

    func test_firstCompleted_builderOverload_successReturnsFirstCompletion() async {
        let result = await ezWithTaskGroupFirstCompleted(result: .results) {
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 25_000_000)
                return 100
            }
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 5_000_000)
                return 200
            }
        }

        XCTAssertEqual(try? result?.get(), 200)
    }

    func test_firstSuccess_arrayOverload_returnsFirstSuccessfulValue() async {
        let ops: [EZTaskItem<Int, Error>] = [
            EZTaskItem {
                try await Task.sleep(nanoseconds: 5_000_000)
                throw TestError.boom
            },
            EZTaskItem {
                try await Task.sleep(nanoseconds: 15_000_000)
                return 7
            },
            EZTaskItem {
                try await Task.sleep(nanoseconds: 30_000_000)
                return 9
            }
        ]

        let value = await ezWithTaskGroupFirstSuccess(ops)
        XCTAssertEqual(value, 7)
    }

    func test_firstSuccess_builderOverload_returnsFirstSuccessfulValue() async {
        let value = await ezWithTaskGroupFirstSuccess {
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 5_000_000)
                throw TestError.boom
            }
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 15_000_000)
                return 77
            }
        }

        XCTAssertEqual(value, 77)
    }
}

final class EZAsyncKit_TaskGroupFirstResult_Any_Tests: XCTestCase {
    private enum TestError: Error { case boom }

    func test_firstCompleted_returnsFailureIfFirstTaskFails() async {
        let result = await ezWithTaskGroupFirstCompleted(
            result: .results,
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 5_000_000)
                throw TestError.boom
            },
            EZTaskItem<Int, Error> {
                try await Task.sleep(nanoseconds: 20_000_000)
                return 1
            }
        )

        guard let result else {
            XCTFail("Expected non-nil result")
            return
        }

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure:
            break
        }
    }

    func test_firstSuccess_returnsNilWhenAllFail_arrayOverload() async {
        let ops: [EZTaskItem<Int, Error>] = [
            EZTaskItem { throw TestError.boom },
            EZTaskItem { throw TestError.boom }
        ]

        let value = await ezWithTaskGroupFirstSuccess(ops)
        XCTAssertNil(value)
    }

    func test_firstCompleted_returnsNilOnCancellation() async {
        let e1 = expectation(description: "op1 cancelled")
        let e2 = expectation(description: "op2 cancelled")

        let op1 = EZTaskItem<Int, Error> {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return 1
            } catch {
                e1.fulfill()
                throw error
            }
        }

        let op2 = EZTaskItem<Int, Error> {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return 2
            } catch {
                e2.fulfill()
                throw error
            }
        }

        let parent = Task {
            await ezWithTaskGroupFirstCompleted(result: .results, [op1, op2])
        }

        try? await Task.sleep(nanoseconds: 50_000_000)
        parent.cancel()

        let result = await parent.value
        XCTAssertNil(result)

        await fulfillment(of: [e1, e2], timeout: 2.0)
    }
}

