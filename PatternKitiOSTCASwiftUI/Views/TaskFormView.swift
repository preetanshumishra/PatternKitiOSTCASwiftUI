//
//  TaskFormView.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//

import ComposableArchitecture
import SwiftUI

struct TaskFormView: View {
    @Bindable var store: StoreOf<TaskFormFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs doing?", text: $store.title)
                }
                Section("Notes") {
                    TextField("Optional", text: $store.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Due date") {
                    Toggle("Has due date", isOn: $store.hasDueDate.animation())
                    if store.hasDueDate {
                        DatePicker("Date", selection: $store.dueDate, displayedComponents: .date)
                    }
                }
                Section("Priority") {
                    Picker("Priority", selection: $store.priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.cancelButtonTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.send(.saveButtonTapped) }
                        .disabled(!store.isValid || store.isSaving)
                }
            }
            .alert(
                "Couldn't save",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { _ in }
                ),
                presenting: store.errorMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { Text($0) }
        }
    }
}

#Preview("Create") {
    TaskFormView(
        store: Store(initialState: TaskFormFeature.State(mode: .create)) { TaskFormFeature() }
    )
}

#Preview("Edit") {
    let sample = TaskItem(
        title: "Plan Q3 roadmap",
        notes: "Draft the high-level themes first.",
        dueDate: Date(),
        priority: .high
    )
    return TaskFormView(
        store: Store(initialState: TaskFormFeature.State(mode: .edit(sample))) { TaskFormFeature() }
    )
}
