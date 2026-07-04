//
//  LazyContainer.swift
//  CommonFeature
//
//  © 2025-2026 Swift Craft Launcher Team. All rights reserved.
//

import Foundation

/// Thread-safe lazy initialization wrapper. Creates the instance on first access, then caches it.
final class LazyContainer<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var instance: T?
    private let factory: () -> T

    init(_ factory: @escaping () -> T) {
        self.factory = factory
    }

    /// Lazily creates or returns cached instance.
    func value() -> T {
        lock.lock()
        defer { lock.unlock() }
        if let instance {
            return instance
        }
        let created = factory()
        instance = created
        return created
    }

    /// Safe reset: clears cached instance, keeps factory intact.
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        instance = nil
    }
}

final class MainActorLazyContainer<T> {
    private let factory: @MainActor () -> T
    private var storage: T?

    init(factory: @escaping @MainActor () -> T) {
        self.factory = factory
    }

    @MainActor
    func value() -> T {
        if let storage { return storage }
        let v = factory()
        storage = v
        return v
    }
}
