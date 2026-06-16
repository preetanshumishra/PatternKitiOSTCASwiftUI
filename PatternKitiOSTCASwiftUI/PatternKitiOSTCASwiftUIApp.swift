//
//  PatternKitiOSTCASwiftUIApp.swift
//  PatternKitiOSTCASwiftUI
//
//  Created by Preetanshu Mishra on 2026-05-28.
//

import ComposableArchitecture
import SwiftUI

@main
struct PatternKitiOSTCASwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            TaskListView(
                store: Store(initialState: TaskListFeature.State()) {
                    TaskListFeature()
                }
            )
        }
    }
}
