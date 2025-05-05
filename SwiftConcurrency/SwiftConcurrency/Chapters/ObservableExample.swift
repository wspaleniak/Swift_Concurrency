//
//  ObservableExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 17/02/2025.
//



// MARK: - NOTES

// MARK: 19 - How to use MainActor with Observable Macro in SwiftUI
///
/// - ONLY CODE



// MARK: - CODE

import SwiftUI

actor ObservableExampleManager {
    
    // MARK: - Methods
    
    func downloadData() -> String {
        return "NEW TITLE"
    }
}



@Observable @MainActor
final class ObservableExampleViewModel {
    
    // MARK: - Properties
    
    private(set) var title: String = ""
    
    @ObservationIgnored
    private let manager = ObservableExampleManager()
    
    // MARK: - Methods
    
    func fetchData() async {
        title = await manager.downloadData()
    }
}



struct ObservableExample: View {
    
    // MARK: - Properties
    
    @State
    private var viewModel = ObservableExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Text(viewModel.title)
            .task {
                await viewModel.fetchData()
            }
    }
}

// MARK: - Preview

#Preview {
    ObservableExample()
}
