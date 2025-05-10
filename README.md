<p align="center">
  <img src="Assets/logo.svg" width="200" alt="SerialTaskExecutor Logo">
</p>

# SerialTaskExecutor

A Swift package that provides a mechanism to execute async tasks serially, ensuring one task completely finishes before the next one starts, even across suspension points.

## Features

- Serial execution of async/await tasks
- Proper handling of task suspension points (unlike regular actors)
- Support for return values and error propagation
- Simple and intuitive API

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SerialTaskExecutor.git", from: "1.0.0")
]
```

## Usage

Swift's native concurrency model doesn't guarantee that tasks will execute in the order they were created when using multiple Task blocks. `SerialTaskExecutor` solves this by ensuring tasks are executed one after another, in the exact order they were enqueued.

### Basic Usage

```swift
import SerialTaskExecutor

// Create an executor
let executor = SerialTaskExecutor()

// Execute tasks serially
Task {
    try await executor.enqueue {
        // First task
        try await Task.sleep(for: .seconds(1))
        print("First task completed")
    }
}

Task {
    try await executor.enqueue {
        // Second task (won't start until first task completes)
        try await Task.sleep(for: .seconds(1))
        print("Second task completed")
    }
}
```

### Working with Return Values

```swift
let executor = SerialTaskExecutor()

Task {
    // Get data from first task
    let data = try await executor.enqueue {
        try await networkService.fetchData()
    }
}
```

### Error Handling

Errors thrown by tasks are properly propagated:

```swift
let executor = SerialTaskExecutor()

Task {
    do {
        try await executor.enqueue {
            throw SomeError.failed
        }
    } catch {
        print("Task failed with error: \(error)")
    }
}
```

## Why not just use actors?

Unlike regular Swift actors, which allow multiple tasks to execute concurrently if a task suspends at an `await` point, `SerialTaskExecutor` guarantees that tasks will fully complete before the next one starts, providing true serial execution.

## License

MIT 
