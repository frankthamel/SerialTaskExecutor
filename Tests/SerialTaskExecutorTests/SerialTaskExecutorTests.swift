import XCTest
@testable import SerialTaskExecutor

final class SerialTaskExecutorTests: XCTestCase {
    func testSerialExecution() async throws {
        let executor = SerialTaskExecutor()
        var tasksInitiatedOrder: [Int] = []
        var executionOrder: [Int] = []
        
        // Execute tasks in parallel but through the executor to ensure serial execution
        async let first: Void = try executor.enqueue {
            tasksInitiatedOrder.append(1)
            try await Task.sleep(for: .seconds(0.3)) // Longer task first
            executionOrder.append(1)
        }
        
        async let second: Void = try executor.enqueue {
            tasksInitiatedOrder.append(2)
            // This task has no delay but should execute after the first one
            executionOrder.append(2)
        }
        
        async let third: Void = try executor.enqueue {
            tasksInitiatedOrder.append(3)
            try await Task.sleep(for: .seconds(0.1)) // Longer task first
            executionOrder.append(3)
        }
        
        // Wait for all tasks to complete
        _ = try await [first, second, third]
        
        // Check that tasks were executed in the correct order
        XCTAssertEqual(executionOrder, tasksInitiatedOrder)
    }
    
    func testReturnValues() async throws {
        let executor = SerialTaskExecutor()
        
        // Test that return values are passed correctly
        let result1 = try await executor.enqueue {
            return "Hello"
        }
        
        let result2 = try await executor.enqueue {
            return "World"
        }
        
        XCTAssertEqual(result1, "Hello")
        XCTAssertEqual(result2, "World")
    }
    
    func testErrorPropagation() async throws {
        let executor = SerialTaskExecutor()
        
        struct TestError: Error { }
        
        // Test that errors are propagated properly
        do {
            try await executor.enqueue {
                throw TestError()
            }
            XCTFail("Should have thrown an error")
        } catch is TestError {
            // Expected error, test passes
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testMixedTypes() async throws {
        let executor = SerialTaskExecutor()
        
        // Test that different return types work correctly
        let stringResult = try await executor.enqueue {
            return "string"
        }
        
        let intResult = try await executor.enqueue {
            return 42
        }
        
        let boolResult = try await executor.enqueue {
            return true
        }
        
        XCTAssertEqual(stringResult, "string")
        XCTAssertEqual(intResult, 42)
        XCTAssertEqual(boolResult, true)
    }
}
