# SerialTaskExecutor

A Swift package that provides a mechanism to execute tasks serially, ensuring one task completes before the next one starts.

## Features

- Serial execution of tasks
- Thread-safe task management
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

```swift
import SerialTaskExecutor

// Create an executor
let executor = SerialTaskExecutor()

// Add tasks to be executed serially
executor.execute {
    // Task 1
    print("Executing first task")
}

executor.execute {
    // Task 2
    print("Executing second task")
}
```

## License

MIT 