//
//  TaskDetailView.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//

import ComposableArchitecture
import SwiftUI

struct TaskDetailView: View {
    let store: StoreOf<TaskDetailFeature>

    var body: some View {
        List {
            Section {
                HStack {
                    Text(store.task.title)
                        .font(.title3.weight(.semibold))
                        .strikethrough(store.task.isCompleted)
                    Spacer()
                    priorityLabel(store.task.priority)
                }
            }

            if let notes = store.task.notes, !notes.isEmpty {
                Section("Notes") { Text(notes) }
            }

            Section {
                if let due = store.task.dueDate {
                    LabeledContent("Due", value: due.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("Status", value: store.task.isCompleted ? "Completed" : "Active")
            }

            Section {
                Button {
                    store.send(.toggleButtonTapped)
                } label: {
                    Label(
                        store.task.isCompleted ? "Mark as active" : "Mark as completed",
                        systemImage: store.task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle"
                    )
                }
                Button(role: .destructive) {
                    store.send(.deleteButtonTapped)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { store.send(.editButtonTapped) }
            }
        }
    }

    private func priorityLabel(_ priority: Priority) -> some View {
        Text(priority.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color(priority).opacity(0.15))
            .foregroundStyle(color(priority))
            .clipShape(Capsule())
    }

    private func color(_ priority: Priority) -> Color {
        switch priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .blue
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(
            store: Store(
                initialState: TaskDetailFeature.State(
                    task: TaskItem(title: "Review PR for auth refactor", priority: .high)
                )
            ) { TaskDetailFeature() }
        )
    }
}
