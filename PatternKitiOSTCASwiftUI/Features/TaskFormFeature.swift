//
//  TaskFormFeature.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//
//  Child feature for create/edit. Persists via the repository dependency and
//  reports success up to the parent through a `delegate` action; it dismisses
//  itself via the `dismiss` dependency.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TaskFormFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable {
            case create
            case edit(TaskItem)
        }

        let mode: Mode
        var title: String
        var notes: String
        var hasDueDate: Bool
        var dueDate: Date
        var priority: Priority
        var isSaving = false
        var errorMessage: String?

        init(mode: Mode) {
            self.mode = mode
            switch mode {
            case .create:
                title = ""
                notes = ""
                hasDueDate = false
                dueDate = Date()
                priority = .medium
            case let .edit(task):
                title = task.title
                notes = task.notes ?? ""
                hasDueDate = task.dueDate != nil
                dueDate = task.dueDate ?? Date()
                priority = task.priority
            }
        }

        var navigationTitle: String {
            switch mode {
            case .create: return "New Task"
            case .edit:   return "Edit Task"
            }
        }

        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Action: BindableAction {
        case saveButtonTapped
        case cancelButtonTapped
        case saveSucceeded(TaskItem)
        case saveFailed(String)
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved(TaskItem)
        }
    }

    @Dependency(\.taskRepository) var repository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                guard state.isValid else { return .none }
                state.isSaving = true
                state.errorMessage = nil

                let title = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedNotes = state.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                let notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                let dueDate = state.hasDueDate ? state.dueDate : nil
                let priority = state.priority
                let mode = state.mode

                return .run { send in
                    let saved: TaskItem
                    switch mode {
                    case .create:
                        saved = try await repository.create(
                            TaskItem(title: title, notes: notes, dueDate: dueDate, priority: priority)
                        )
                    case let .edit(original):
                        var edited = original
                        edited.title = title
                        edited.notes = notes
                        edited.dueDate = dueDate
                        edited.priority = priority
                        edited.updatedAt = Date()
                        saved = try await repository.update(edited)
                    }
                    await send(.saveSucceeded(saved))
                } catch: { error, send in
                    await send(.saveFailed(error.localizedDescription))
                }

            case let .saveSucceeded(task):
                state.isSaving = false
                return .run { send in
                    await send(.delegate(.saved(task)))
                    await dismiss()
                }

            case let .saveFailed(message):
                state.isSaving = false
                state.errorMessage = message
                return .none

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
