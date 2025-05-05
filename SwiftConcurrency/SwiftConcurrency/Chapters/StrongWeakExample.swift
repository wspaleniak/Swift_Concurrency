//
//  StrongWeakExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 14/02/2025.
//



// MARK: - NOTES

// MARK: 13 - How to manage strong & weak references with Async Await
///
/// - nie musimy zarządzać `weak` i `strong` referencjami w obiekcie `Task {...}` w momencie gdy zarządzamy ich kończeniem
/// - jeśli używamy metody `cancel()` na wszystkich obiektach `Task` jakie przechowujemy w `View` lub `ViewModel` to nie musimy używać `[weak self]` ponieważ cały blok kodu wewnątrz `Task` jest usuwany łącznie z referencjami - więc nie ma ryzyka wycieków pamięci
/// - jeśli na widoku używamy modyfikatora `.task {...}` to wszystkie taski w nim odpalone są kończone w momencie gdy wychodzimy z widoku



// MARK: - CODE

import SwiftUI

final class StrongWeakExampleManager {
    
    // MARK: - Methods
    
    func downloadTitle() async -> String {
        return "NEW TITLE"
    }
}



final class StrongWeakExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var title: String = "Default title"
    
    private let manager = StrongWeakExampleManager()
    
    private var task: Task<Void, Never>?
    
    private var tasks: [Task<Void, Never>] = []
    
    // MARK: - Methods
    
    // STRONG reference
    func updateTitle1() {
        Task {
            title = await manager.downloadTitle()
        }
    }
    
    // STRONG reference
    func updateTitle2() {
        Task {
            self.title = await self.manager.downloadTitle()
        }
    }
    
    // STRONG reference
    func updateTitle3() {
        Task { [self] in
            self.title = await self.manager.downloadTitle()
        }
    }
    
    // WEAK reference
    func updateTitle4() {
        Task { [weak self] in
            guard let self else { return }
            title = await manager.downloadTitle()
        }
    }
    
    // Nie musimy zarządzać STRONG/WEAK w Tasku ponieważ możemy zarządzać Taskiem
    // W momencie gdy kończymy Taska to usuwa się wszystko co ma w swoim bloku wykonywania
    // A więc również referencje do obiektów klas więc nie ma problemu z wyciekami pamięci
    func updateTitle5() {
        task = Task {
            title = await manager.downloadTitle()
        }
    }
    
    // Wiele tasków w jednej tablicy
    func updateTitle6() {
        let task1 = Task {
            title = await manager.downloadTitle()
        }
        let task2 = Task {
            title = await manager.downloadTitle()
        }
        tasks.append(contentsOf: [task1, task2])
    }
    
    // Kończenie działania tasków
    func cancelTasks() {
        task?.cancel()
        task = nil
        tasks.forEach { $0.cancel() }
        tasks = []
    }
}



struct StrongWeakExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = StrongWeakExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Text(viewModel.title)
            .onAppear {
                viewModel.updateTitle1()
            }
            .onDisappear {
                viewModel.cancelTasks()
            }
    }
}

// MARK: - Preview

#Preview {
    StrongWeakExample()
}
