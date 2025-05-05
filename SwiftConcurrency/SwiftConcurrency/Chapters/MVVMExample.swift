//
//  MVVMExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 15/02/2025.
//



// MARK: - NOTES

// MARK: 14 - How to use MVVM with Async Await
///
/// - ONLY CODE



// MARK: - CODE

import SwiftUI

actor MVVMExampleActorManager {
    
    // MARK: - Methods
    
    func downloadData() async throws -> String {
        return "ACTOR - NEW DATA"
    }
}



final class MVVMExampleClassManager {
    
    // MARK: - Methods
    
    func downloadData() async throws -> String {
        return "CLASS - NEW DATA"
    }
}



// @MainActor
final class MVVMExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @MainActor @Published
    private(set) var title: String = "Default title"
    
    private let actorManager = MVVMExampleActorManager()
    
    private let classManager = MVVMExampleClassManager()
    
    private var tasks: [Task<Void, Never>] = []
    
    // MARK: - Methods
    
    // @MainActor
    func buttonTapped() {
        let task = Task { @MainActor in
            do {
                let newTitle = try await actorManager.downloadData()
                title = newTitle
                // await MainActor.run {
                //     title = newTitle
                // }
            } catch {
                print(error.localizedDescription)
            }
        }
        tasks.append(task)
    }
    
    func cancelTasks() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}



struct MVVMExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = MVVMExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text(viewModel.title)
            Button("CLICK IT") {
                viewModel.buttonTapped()
            }
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
    }
}

// MARK: - Preview

#Preview {
    MVVMExample()
}
