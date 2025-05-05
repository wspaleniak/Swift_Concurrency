//
//  AsyncStreamExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 16/02/2025.
//



// MARK: - NOTES

// MARK: 18 - How to use AsyncStream in Swift
///
/// - `AsyncStream<Type>``AsyncThrowingStream<Type, Error>`  pozwala na publikowanie danych w środowisku asynchronicznym
/// - dane z `AsyncStream<Type>` nasłuchujemy za pomocą asynchronicznej pętli `for await in`
/// - dane z `AsyncThrowingStream<Type, Error>` nasłuchujemy za pomocą asynchronicznej pętli `for try await in`
/// - dzięki `AsyncStream` możemy przerobić metodę napisaną z użyciem `Closure` na asynchroniczny stream danych
/// - tworząc nowy obiekt `AsyncStream` dostajemy w domknięciu argument `continuation`
/// - aby publikować dane przechwycone z metody z `Closure` używamy `continuation.yield()`
/// - jeśli z `Closure` dostajemy typ `Result<Type, Error>` możemy użyć `continuation.yield(with:)`
/// - aby zakończyć asynchroniczny stream danych używamy `continuation.finish()`
/// - jeśli na zakończenie asynchronicznego streamu danych możemy rzucić błędem to używamy `continuation.finish(throwing:)`
/// - zakończenie `AsyncStream` lub samego `Task` w którym nasłuchujemy na nowe wartości z `AsyncStream` nie kończy tak naprawdę funkcji publikującej dane z `Closure` - trzeba tym zarządzać manualnie
///
/// - dla `AsyncStream` możemy używać takich samych metod jak w `Combine` np. `dropFirst()` lub `.debounce()`
/// - ale żeby ich używać to musimy zaimportować bibliotekę `import AsyncAlgorithms` którą dodajemy w `Package Dependencies`



// MARK: - CODE

import AsyncAlgorithms
import SwiftUI

final class AsyncStreamExampleManager {
    
    // MARK: - Methods
    
    /// ** COMPLETION WITHOUT ERROR **
    private func downloadData(
        newValue: @escaping (Int) -> Void,
        onFinish: @escaping () -> Void
    ) {
        let items: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                if item <= 5 {
                    newValue(item)
                } else {
                    onFinish()
                }
            }
        }
    }
    
    /// ** COMPLETION WITH ERROR **
    private func downloadDataWithError(
        newValue: @escaping (Int) -> Void,
        onFinish: @escaping ((any Error)?) -> Void
    ) {
        let items: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                if item == 6 {
                    onFinish(URLError(.unknown))
                } else if item <= 8 {
                    newValue(item)
                } else {
                    onFinish(nil)
                }
            }
        }
    }
    
    /// ** COMPLETION WITH RESULT **
    private func downloadDataWithResult(
        newValue: @escaping (Result<Int, Error>) -> Void,
        onFinish: @escaping () -> Void
    ) {
        let items: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                if item == 6 {
                    newValue(.failure(URLError(.unknown)))
                } else if item <= 8 {
                    newValue(.success(item))
                } else {
                    onFinish()
                }
            }
        }
    }
    
    /// ** ASYNC STREAM **
    func downloadData() -> AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            self?.downloadData { number in
                continuation.yield(number)
            } onFinish: {
                continuation.finish()
            }
        }
    }
    
    /// ** ASYNC THROWING STREAM - ERROR **
    func downloadDataWithError() -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { [weak self] continuation in
            self?.downloadDataWithError { item in
                continuation.yield(item)
            } onFinish: { error in
                continuation.finish(throwing: error)
            }
        }
    }
    
    /// ** ASYNC THROWING STREAM - RESULT **
    func downloadDataWithResult() -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { [weak self] continuation in
            self?.downloadDataWithResult { result in
                continuation.yield(with: result)
            } onFinish: {
                continuation.finish()
            }
        }
    }
}



@MainActor
final class AsyncStreamExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var currentNumber: Int = 0
    
    private let manager = AsyncStreamExampleManager()
    
    // MARK: - Methods
    
    func fetchData() {
        /// ** ASYNC STREAM **
        // Task {
        //     for await number in manager.downloadData() {
        //         currentNumber = number
        //     }
        // }
        
        /// ** ASYNC THROWING STREAM - ERROR **
        // Task {
        //     do {
        //         for try await number in manager.downloadDataWithError() {
        //             currentNumber = number
        //         }
        //     } catch {
        //         print(error.localizedDescription)
        //     }
        // }
        
        /// ** ASYNC THROWING STREAM - RESULT **
        Task {
            do {
                for try await number in manager.downloadDataWithResult() {
                    currentNumber = number
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}



struct AsyncStreamExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = AsyncStreamExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Text(viewModel.currentNumber.description)
            .onAppear {
                viewModel.fetchData()
            }
    }
}

// MARK: - Preview

#Preview {
    AsyncStreamExample()
}
