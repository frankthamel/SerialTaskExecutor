// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A task executor that processes async tasks in a strictly serial manner.
///
/// `SerialTaskExecutor` ensures that async tasks run one after another, even across
/// suspension points. This behavior differs from regular Swift actors, which can
/// process multiple tasks concurrently if a task suspends at an `await` point.
///
/// Use this when you need to guarantee that async operations complete in the exact
/// order they were enqueued, such as:
/// - Maintaining a local cache that requires operations in a specific order
/// - Implementing a wizard-like flow where steps depend on previous results
/// - Supporting offline-first functionality with a strict write sequence
///
/// ## Example: Sequential API calls
///
/// ```swift
/// let executor = SerialTaskExecutor()
///
/// Task {
///     // Each operation will fully complete before the next begins
///     try await executor.enqueue { 
///         try await dataService.fetchData(id: 1)
///     }
///     
///     try await executor.enqueue {
///         try await dataService.createData(name: "New Item")
///     }
///     
///     try await executor.enqueue {
///         try await dataService.updateData(id: 1, name: "Updated Item")
///     }
/// }
/// ```
///
/// ## Example: Handling return values
///
/// ```swift
/// let executor = SerialTaskExecutor()
///
/// Task {
///     // Get result from the first operation
///     let notes = try await executor.enqueue {
///         try await notesService.fetchNotes()
///     }
///     
///     // Use the result in the next operation
///     if let firstNote = notes.first {
///         try await executor.enqueue {
///             try await notesService.updateNote(id: firstNote.id, text: "Updated")
///         }
///     }
/// }
/// ```
///
/// > Note: Unlike concurrent task execution, where tasks might complete in any order,
/// > `SerialTaskExecutor` guarantees that tasks finish in the same order they were enqueued.
public actor SerialTaskExecutor {
    /// Indicates whether the executor is currently processing tasks
    private var isExecuting = false
    
    /// The queue of tasks waiting to be executed
    private var taskQueue: [(() async throws -> Any, CheckedContinuation<Any, Error>)] = []

    /// Creates a new serial task executor with an empty queue.
    public init() {}
    
    /// Enqueues an async task for serial execution.
    ///
    /// This method adds the provided task to the execution queue and returns a value
    /// only after the task has been executed to completion. If the task throws an
    /// error, that error will be propagated to the caller.
    ///
    /// - Parameter task: An async throwing closure that performs the work and returns a value.
    /// - Returns: The value produced by the task.
    /// - Throws: Any error thrown by the task during execution.
    ///
    /// ## Example:
    ///
    /// ```swift
    /// let executor = SerialTaskExecutor()
    ///
    /// // Enqueue a task that returns a value
    /// let result = try await executor.enqueue {
    ///     try await apiClient.fetchData()
    /// }
    ///
    /// // Use the result
    /// print("Received \(result.count) items")
    /// ```
    public func enqueue<T>(_ task: @escaping () async throws -> T) async throws -> T {
        // Use a continuation returning Any, then cast back to T
        let anyResult = try await withCheckedThrowingContinuation { continuation in
            // Wrap the task into an Any-producing closure
            let wrapped: () async throws -> Any = { try await task() as Any }
            taskQueue.append((wrapped, continuation))

            if !isExecuting {
                isExecuting = true
                Task {
                    await processQueue()
                }
            }
        }
        // Safe to force-cast because we wrapped the correct type
        return anyResult as! T
    }

    /// Processes the task queue, executing each task in sequence.
    ///
    /// This method runs tasks one after another, ensuring that each task fully
    /// completes (including any async operations) before the next one begins.
    private func processQueue() async {
        while !taskQueue.isEmpty {
            let (task, continuation) = taskQueue.removeFirst()
            do {
                let result = try await task()
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
        isExecuting = false
    }
}
