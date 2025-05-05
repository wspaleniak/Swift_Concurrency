//
//  RefreshableExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 15/02/2025.
//



// MARK: - NOTES

// MARK: 15 - How to use Refreshable modifier in SwiftUI
///
/// - ONLY CODE



// MARK: - CODE

import SwiftUI

final class RefreshableExampleManager {
    
    // MARK: - Methods
    
    func downloadData() async throws -> [String] {
        try await Task.sleep(for: .seconds(2))
        return ["Apple", "Orange", "Banana", "Cherry", "Watermelon"].shuffled()
    }
}



@MainActor
final class RefreshableExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var fruits: [String] = []
    
    private let manager = RefreshableExampleManager()
    
    // MARK: - Methods
    
    func updateData() async {
        do {
            fruits = try await manager.downloadData()
        } catch {
            print(error.localizedDescription)
        }
    }
}



struct RefreshableExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = RefreshableExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.fruits, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .refreshable {
            /// Jeśli tu wywołamy metodę która nie jest `async` to spinner nie będzie się kręcił tak długo jak trwa wywołanie metody tylko od razu przestanie
            /// Natomiast jeśli wywołana tu metoda będzie `async` to spinner będzie się kręcił tak długo jak będzie trwało wykonywanie metody
            await viewModel.updateData()
        }
        .task {
            await viewModel.updateData()
        }
    }
}

// MARK: - Preview

#Preview {
    RefreshableExample()
}
