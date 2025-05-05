//
//  AsyncPublisherExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 14/02/2025.
//



// MARK: - NOTES

// MARK: 12 - How to use AsyncPublisher to convert @Published to Async / Await
///
/// - na początek tworzymy klasyczny publisher `@Published var data: String = ""` który wysyła swoje wartości do nasłuchujących obiektów
/// - klasycznie nasłuchiwaliśmy te wartości za pomocą `.sink` z biblioteki `Combine` odwołując się do `$data`
/// - aby nasłuchiwać na `AsyncPublisher` musimy odwołać się za pomocą `$data.values`
/// - a do nasłuchiwania wartości używamy asynchornicznej pętli `for await in` lub `for try await in`
/// - pętla ta musi być umieszczona `Task {...}`
/// - WAŻNE: używamy tylko jeden `Task {...}` dla jednego nasłuchiwania - jeśli umieścimy w jednym `Task` kilka pętli nasłuchujących na wartości to będzie wykonywać się tylko ta pierwsza - kolejne się nie wykonają



// MARK: - CODE

import SwiftUI

final class AsyncPublisherExampleManager {
    
    // MARK: - Properties
    
    @Published
    private(set) var data: [String] = []
    
    // MARK: - Methods
    
    func downloadData() async {
        data.append("Apple")
        try? await Task.sleep(for: .seconds(2))
        data.append("Orange")
        try? await Task.sleep(for: .seconds(2))
        data.append("Banana")
        try? await Task.sleep(for: .seconds(2))
        data.append("Cherry")
    }
}



final class AsyncPublisherExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @MainActor @Published
    private(set) var data: [String] = []
    
    private let manager = AsyncPublisherExampleManager()
    
    private var task: Task<Void, Error>?
    
    // MARK: - Init
    
    init() {
        let asyncPublisher = manager.$data.values
        task = Task { [weak self] in
            for await newData in asyncPublisher {
                guard let self else {
                    return
                }
                try Task.checkCancellation()
                await MainActor.run {
                    self.data = newData
                }
            }
        }
    }
    
    deinit {
        task?.cancel()
        task = nil
    }
    
    // MARK: - Methods
    
    func fetchData() async {
        await manager.downloadData()
    }
}



struct AsyncPublisherExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = AsyncPublisherExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.data, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .task {
            await viewModel.fetchData()
        }
    }
}

// MARK: - Preview

#Preview {
    AsyncPublisherExample()
}
