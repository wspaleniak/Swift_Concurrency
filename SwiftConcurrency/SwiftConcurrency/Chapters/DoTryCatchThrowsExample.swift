//
//  DoTryCatchThrowsExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 30/06/2024.
//



// MARK: - NOTES

// MARK: 1 - How to use Do, Try, Catch and Throws in Swift
///
/// - ONLY CODE



// MARK: - CODE

import SwiftUI

final class DoTryCatchThrowsExampleManager {
    
    // MARK: - Properties
    
    private var isActive: Bool = false
    
    // MARK: - Methods
    
    func downloadTitle() throws -> String {
        if isActive {
            return "NEW TEXT"
        } else {
            throw URLError(.unknown)
        }
    }
}



final class DoTryCatchThrowsExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var title: String = "Default text"
    
    private let manager = DoTryCatchThrowsExampleManager()
    
    // MARK: - Init
    
    // MARK: - Methods
    
    func fetchTitle() {
        // DO-CATCH && TRY
        do {
            title = try manager.downloadTitle()
        } catch {
            title = error.localizedDescription
        }
        // TRY?
        if let newTitle = try? manager.downloadTitle() {
            title = newTitle
        }
    }
}



struct DoTryCatchThrowsExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = DoTryCatchThrowsExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Text(viewModel.title)
            .padding()
            .frame(width: 300, height: 300)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .background(.indigo)
            .onTapGesture {
                viewModel.fetchTitle()
            }
    }
}

// MARK: - Preview

#Preview {
    DoTryCatchThrowsExample()
}
