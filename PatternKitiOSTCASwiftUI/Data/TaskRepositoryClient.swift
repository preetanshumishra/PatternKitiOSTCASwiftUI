//
//  TaskRepositoryClient.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//
//  TCA models dependencies as plain structs of closures rather than protocols.
//  This is the data layer's "client"; its live value is backed by an in-memory
//  actor (the same mock-store role as the other modules' MockTaskRepository),
//  and it's registered with the @Dependency system so reducers can pull it in.
//

import ComposableArchitecture
import Foundation

struct TaskRepositoryClient: Sendable {
    var fetchAll: @Sendable () async throws -> [TaskItem]
    var create: @Sendable (TaskItem) async throws -> TaskItem
    var update: @Sendable (TaskItem) async throws -> TaskItem
    var delete: @Sendable (UUID) async throws -> Void
}

enum TaskRepositoryError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "Task not found."
        }
    }
}

extension TaskRepositoryClient: DependencyKey {
    static let liveValue: TaskRepositoryClient = {
        let store = InMemoryTaskStore()
        return TaskRepositoryClient(
            fetchAll: { try await store.fetchAll() },
            create: { try await store.create($0) },
            update: { try await store.update($0) },
            delete: { try await store.delete($0) }
        )
    }()
}

extension DependencyValues {
    var taskRepository: TaskRepositoryClient {
        get { self[TaskRepositoryClient.self] }
        set { self[TaskRepositoryClient.self] = newValue }
    }
}

/// In-memory backing store. An actor so concurrent effects can't race on the
/// task array. Configurable latency exercises the loading state.
private actor InMemoryTaskStore {
    private var tasks: [TaskItem] = TaskSeedData.tasks
    private let latency: Duration = .milliseconds(600)

    func fetchAll() async throws -> [TaskItem] {
        try await Task.sleep(for: latency)
        return tasks
    }

    func create(_ task: TaskItem) async throws -> TaskItem {
        try await Task.sleep(for: latency)
        tasks.append(task)
        return task
    }

    func update(_ task: TaskItem) async throws -> TaskItem {
        try await Task.sleep(for: latency)
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw TaskRepositoryError.notFound
        }
        tasks[index] = task
        return task
    }

    func delete(_ id: UUID) async throws {
        try await Task.sleep(for: latency)
        guard tasks.contains(where: { $0.id == id }) else {
            throw TaskRepositoryError.notFound
        }
        tasks.removeAll { $0.id == id }
    }
}
