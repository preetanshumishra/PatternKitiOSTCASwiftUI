//
//  TaskDetailFeature.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//
//  Child feature for the detail screen. Toggling / deleting run the repository
//  and surface the outcome to the parent via `delegate`, so the list stays the
//  single source of truth. Edit just asks the parent to present the form.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TaskDetailFeature {
    @ObservableState
    struct State: Equatable {
        var task: TaskItem
    }

    enum Action {
        case toggleButtonTapped
        case deleteButtonTapped
        case editButtonTapped
        case taskUpdated(TaskItem)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case updated(TaskItem)
            case deleted(UUID)
            case editRequested(TaskItem)
        }
    }

    @Dependency(\.taskRepository) var repository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleButtonTapped:
                var toggled = state.task
                toggled.isCompleted.toggle()
                toggled.updatedAt = Date()
                return .run { send in
                    await send(.taskUpdated(try await repository.update(toggled)))
                }

            case let .taskUpdated(task):
                state.task = task
                return .send(.delegate(.updated(task)))

            case .deleteButtonTapped:
                let id = state.task.id
                return .run { send in
                    try await repository.delete(id)
                    await send(.delegate(.deleted(id)))
                    await dismiss()
                }

            case .editButtonTapped:
                return .send(.delegate(.editRequested(state.task)))

            case .delegate:
                return .none
            }
        }
    }
}
