# PatternKit — The Composable Architecture (SwiftUI)

Part of **PatternKit**, a side-by-side reference codebase where the same small **Tasks** CRUD app is implemented once per architecture pattern across iOS and Android. Every module ships identical behaviour — the same domain model, the same three screens, the same mock data layer — so the only thing that varies is the architecture itself.

This module is the **TCA (The Composable Architecture)** flavour on **SwiftUI**. Each screen is a `Reducer` with a `State` + `Action` + `Store` model: views send actions, the reducer mutates state and returns effects, and the store drives the view. Its mental model is closer to **Elm / Point-Free's reducer composition** than to JavaScript-flavoured Redux. TCA carries the most boilerplate and the steepest learning curve of the iOS modules in exchange for exhaustive testability and composable, predictable state — the trade-off this module exists to make concrete.

## Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Architecture:** TCA — `State` / `Action` / `Reducer` / `Store` per feature
- **Dependency:** [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.15.0+ (Swift Package Manager)
- **DI:** TCA's `@Dependency` system — the repository is exposed as a `TaskRepositoryClient`
- **Navigation:** modelled as state in the reducers (`@Presents` + `.ifLet`) — no separate Coordinator
- **Deployment target:** iOS 17.0 minimum (built against the iOS 26.5 SDK)
- **Bundle ID:** `com.preetanshumishra.PatternKitiOSTCASwiftUI`

## The Tasks feature

A single-user task list. One entity (`TaskItem`: title, optional notes, optional due date, priority, completion). Three screens:

1. **List** (`TaskListFeature`) — filter (All / Active / Completed), sort by due date or priority, swipe-to-delete, `+` to create.
2. **Detail** (`TaskDetailFeature`) — read-only fields, toggle completion, edit, delete.
3. **Form** (`TaskFormFeature`) — create or edit (mode-driven), title validation (≤ 80 chars), due-date validation (not in the past), 600 ms mock async save.

Data is provided through `TaskRepositoryClient` — a TCA dependency client backed by an in-memory store seeded with ~12 tasks, with configurable artificial latency and failure rate. No real network, no local persistence — intentionally, so the architecture stays the focus.

## TCA-specific shape

- **Features over view models** — each screen's logic is a `Reducer` (`TaskListFeature`, `TaskDetailFeature`, `TaskFormFeature`) holding its `State` and `Action` enum; views are thin and send actions to a `Store`.
- **Dependencies as clients** — instead of a hand-wired container, the repository is a `TaskRepositoryClient` registered with TCA's `@Dependency`, which also makes it trivial to override in tests.
- **Navigation is state, so there's no Coordinator** — the sibling MVVM, Clean, and UIKit modules extract flow into a separate Coordinator object. TCA doesn't need one: the parent reducer (`TaskListFeature`) drives presentation declaratively with `@Presents` child state and `.ifLet`, and reacts to child `delegate` actions. The reducer already *is* the single place that owns navigation, so adding a Coordinator would duplicate that role and fight the framework.

## Project layout

```
PatternKitiOSTCASwiftUI/
├── Domain/        # TaskItem, Priority, TaskFilter, TaskSort
├── Data/          # TaskRepositoryClient, seed data
├── Features/      # TaskListFeature, TaskDetailFeature, TaskFormFeature (reducers)
├── Views/         # TaskListView, TaskDetailView, TaskFormView
└── PatternKitiOSTCASwiftUIApp.swift
```

## Build & run

Open `PatternKitiOSTCASwiftUI.xcodeproj` in Xcode — SPM resolves the Composable Architecture package automatically — then ⌘R to build and run (⌘U for tests).

### First build: enable the macros

TCA ships Swift macros (`ComposableArchitectureMacros`, `CasePathsMacros`, and others). On the **first** build Xcode blocks them pending approval, and command-line builds fail with:

> Macro "ComposableArchitectureMacros" … must be enabled before it can be used

- **In Xcode:** when prompted, choose **Trust & Enable** for the package's macro targets (or right-click the package → *Trust & Enable Macros*).
- **From the command line:** pass `-skipMacroValidation`, e.g.

  ```bash
  xcodebuild -project PatternKitiOSTCASwiftUI.xcodeproj -scheme PatternKitiOSTCASwiftUI \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -skipMacroValidation build
  ```

This is a one-time trust prompt, not a code issue — the project builds cleanly once the macros are enabled.
