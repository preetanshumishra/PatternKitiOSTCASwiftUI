//
//  TaskListFeature.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//
//  Root feature. Owns the task collection + filter/sort/loading/error, and
//  hierarchically composes two child features it presents: the create/edit
//  `form` (a sheet) and `detail` (a pushed destination). Child→parent
//  communication is via the children's `delegate` actions.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TaskListFeature {
    @ObservableState
    struct State: Equatable {
        var allTasks: IdentifiedArrayOf<TaskItem> = []
        var filter: TaskFilter = .all
        var sort: TaskSort = .dueDate
        var isLoading = false
        var errorMessage: String?

        @Presents var form: TaskFormFeature.State?
        @Presents var detail: TaskDetailFeature.State?

        /// Derived view of the data — filtered then sorted.
        var displayedTasks: [TaskItem] {
            sort.sorted(allTasks.elements.filter(filter.matches))
        }
    }

    enum Action: BindableAction {
        case onAppear
        case toggleTapped(TaskItem)
        case deleteTapped(TaskItem)
        case tasksLoaded([TaskItem])
        case taskUpserted(TaskItem)
        case taskRemoved(UUID)
        case operationFailed(String)
        case addButtonTapped
        case taskTapped(TaskItem)
        case errorDismissed
        case binding(BindingAction<State>)
        case form(PresentationAction<TaskFormFeature.Action>)
        case detail(PresentationAction<TaskDetailFeature.Action>)
    }

    @Dependency(\.taskRepository) var repository

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.allTasks.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    await send(.tasksLoaded(try await repository.fetchAll()))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case let .tasksLoaded(tasks):
                state.isLoading = false
                state.allTasks = IdentifiedArray(uniqueElements: tasks)
                return .none

            case let .toggleTapped(task):
                var toggled = task
                toggled.isCompleted.toggle()
                toggled.updatedAt = Date()
                return .run { [toggled] send in
                    await send(.taskUpserted(try await repository.update(toggled)))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case let .deleteTapped(task):
                let id = task.id
                return .run { send in
                    try await repository.delete(id)
                    await send(.taskRemoved(id))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case let .taskUpserted(task):
                state.allTasks[id: task.id] = task
                return .none

            case let .taskRemoved(id):
                state.allTasks.remove(id: id)
                return .none

            case let .operationFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .addButtonTapped:
                state.form = TaskFormFeature.State(mode: .create)
                return .none

            case let .taskTapped(task):
                state.detail = TaskDetailFeature.State(task: task)
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            // Child → parent: form saved a task.
            case let .form(.presented(.delegate(.saved(task)))):
                state.allTasks[id: task.id] = task
                return .none

            // Child → parent: detail mutated / removed / requested an edit.
            case let .detail(.presented(.delegate(.updated(task)))):
                state.allTasks[id: task.id] = task
                return .none

            case let .detail(.presented(.delegate(.deleted(id)))):
                state.allTasks.remove(id: id)
                return .none

            case let .detail(.presented(.delegate(.editRequested(task)))):
                state.form = TaskFormFeature.State(mode: .edit(task))
                return .none

            case .binding, .form, .detail:
                return .none
            }
        }
        .ifLet(\.$form, action: \.form) { TaskFormFeature() }
        .ifLet(\.$detail, action: \.detail) { TaskDetailFeature() }
    }
}
