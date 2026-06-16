//
//  TaskListView.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//

import ComposableArchitecture
import SwiftUI

struct TaskListView: View {
    @Bindable var store: StoreOf<TaskListFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                taskList
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.send(.addButtonTapped) } label: { Image(systemName: "plus") }
                }
            }
            .task { store.send(.onAppear) }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.send(.errorDismissed) } }
                ),
                presenting: store.errorMessage
            ) { _ in
                Button("OK", role: .cancel) { store.send(.errorDismissed) }
            } message: { Text($0) }
            .sheet(item: $store.scope(state: \.form, action: \.form)) { formStore in
                TaskFormView(store: formStore)
            }
            .navigationDestination(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
                TaskDetailView(store: detailStore)
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $store.filter) {
            ForEach(TaskFilter.allCases) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $store.sort) {
                ForEach(TaskSort.allCases) { sort in
                    Text(sort.displayName).tag(sort)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    @ViewBuilder
    private var taskList: some View {
        if store.isLoading && store.displayedTasks.isEmpty {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.displayedTasks.isEmpty {
            ContentUnavailableView("No tasks", systemImage: "checklist", description: Text("Tap + to add one."))
        } else {
            List {
                ForEach(store.displayedTasks) { task in
                    Button { store.send(.taskTapped(task)) } label: {
                        TaskRow(task: task) { store.send(.toggleTapped(task)) }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.send(.deleteTapped(task)) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                HStack(spacing: 8) {
                    PriorityBadge(priority: task.priority)
                    if let due = task.dueDate {
                        Text(due, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

private struct PriorityBadge: View {
    let priority: Priority
    var body: some View {
        Text(priority.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    private var color: Color {
        switch priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .blue
        }
    }
}

#Preview {
    TaskListView(
        store: Store(initialState: TaskListFeature.State()) { TaskListFeature() }
    )
}
