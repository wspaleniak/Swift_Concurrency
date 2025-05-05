//
//  AsyncAwaitKeywordsExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 07/02/2025.
//



// MARK: - NOTES

// MARK: 3 - How to use async / await keywords in Swift
///
/// - akcje wywoływane w kodzie oznaczonym `async` są z automatu wykonywane na wątku `background`
/// - jeśli przypisujemy nową wartość do zmiennej wewnątrz metody `async` to mamy dwie opcje
/// - albo umieścić przypisanie nowej wartości wewnątrz `await MainActor.run {...}`
/// - albo oznaczyć całą metodę jako `@MainActor`
/// - trzeba uważać ponieważ oznaczenie pierwszego przypisania wartości za pomocą `await MainActor.run {...}` następnie wywołanie innej metody oznaczoenj jako `async` np. `Task.sleep(...)` która wykonuje się w tle i nastepnie przypisanie kolejnej wartości bez żadnego oznaczenia że ma być to wykonywane na głównym wątku skutkuje tym że wykona się to na wątku `background` - bezpieczniejsze jest użycie `@MainActor` na całej metodzie



// MARK: - CODE

import SwiftUI

final class AsyncAwaitKeywordsExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var data: [String] = []
    
    // MARK: - Methods
    
    func addTitleOne() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.data.append("One / \(Thread.current)")
        }
    }
    
    func addTitleTwoThree() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            let title = "Two / \(Thread.current)"
            DispatchQueue.main.async {
                self?.data.append(title)
                
                let nextTitle = "Three / \(Thread.current)"
                self?.data.append(nextTitle)
            }
        }
    }
    
    @MainActor
    func addFruits() async {
        let fruitOne = "Apple / \(Thread())"
        data.append(fruitOne)
        
        try? await Task.sleep(for: .seconds(2))
        
        let fruitTwo = "Orange / \(Thread())"
        data.append(fruitTwo)
    }
}



struct AsyncAwaitKeywordsExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = AsyncAwaitKeywordsExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(viewModel.data, id: \.self) {
                Text($0)
            }
        }
        .onAppear {
            // viewModel.addTitleOne()
            // viewModel.addTitleTwoThree()
            
            // Task {
            //     await viewModel.addFruits()
            // }
        }
        .task {
            await viewModel.addFruits()
        }
    }
}

// MARK: - Preview

#Preview {
    AsyncAwaitKeywordsExample()
}
