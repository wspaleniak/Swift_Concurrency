//
//  ContinuationsExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 09/02/2025.
//



// MARK: - NOTES

// MARK: 7 - How to use Continuations in Swift (withCheckedThrowingContinuation)
///
/// - służy do przekształcenia kodu który nie jest kompatybilny z `async await` w kod który kompatybilny jest
/// - niektóre frameworki lub metody w użyte w kodzie nie są dostosowane do używania `async await` i w ten sposób możemy je zmodyfikować
/// - do wyboru jest kilka opcji:
/// - `withUnsafeContinuation { continuation in }`
/// - `withCheckedContinuation { continuation in }`
/// - `withUnsafeThrowingContinuation { continuation in }`
/// - `withCheckedThrowingContinuation { continuation in }`
/// - używamy zazwyczaj opcji oznaczonych jako `checked` - używając `unsafe` mówisz kompilatorowi że sprawdziłeś kod samemu czy nie ma błędów - może to być dobre dla optymalizacji ale rzadziej się tego używa
/// - wewnątrz metody np. `withCheckedThrowingContinuation { continuation in ... }` wywołujemy metodę z `escaping closure`
/// - a nastepnie używamy metody `continuation.resume(...)` aby zwrócić asynchronicznie wartość odebraną z metody z `escaping closure`
/// - mamy kilka metod do wyboru:
/// - `continuation.resume(with:)` - jeśli domknięcie zwraca jako argument typ `Result<Type, Error>`
/// - `continuation.resume(returning:)` - jeśli domknięcie zwraca konkretny typ
/// - `continuation.resume(throwing:)` - jeśli domknięcie zwraca error
/// -
/// - WAŻNE:
/// - nie może być sytuacji że `continuation.resume(...)` wywoła się więcej niż raz lub nie wywoła się wcale bo wtedy appka może mieć crash
/// - każdy przypadek z domknięcia musi być obsłużony i wysłany jako wartość zwrotna
/// - dlatego najbezpieczniej i najprzyjemniej używać domknięcia zwracającego typ `Result<Type, Error>`



// MARK: - CODE

import SwiftUI

final class ContinuationsExampleManager {
    
    // MARK: - Methods
    
    /// ** ASYNC AWAIT **
    func downloadImageWithAsyncAwait() async throws -> Data {
        guard let url = URL(string: "https://picsum.photos/300") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    /// ** CONTINUATION **
    func downloadImageWithContinuation() async throws -> Data {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.downloadImageWithEscapingClosure { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// ** ESCAPING CLOSURE **
    private func downloadImageWithEscapingClosure(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "https://picsum.photos/300") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
            }
            guard let data else {
                completion(.failure(URLError(.dataNotAllowed)))
                return
            }
            completion(.success(data))
        }.resume()
    }
}



final class ContinuationsExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var image: UIImage? = nil
    
    private let manager = ContinuationsExampleManager()
    
    // MARK: - Methods
    
    func fetchImage() async {
        do {
            /// ** ASYNC AWAIT **
            // let data = try await manager.downloadImageWithAsyncAwait()
            
            /// ** CONTINUATION **
            let data = try await manager.downloadImageWithContinuation()
            
            let image = UIImage(data: data)
            await MainActor.run { [weak self] in
                self?.image = image
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}



struct ContinuationsExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = ContinuationsExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
        }
        .task {
            await viewModel.fetchImage()
        }
    }
}

// MARK: - Preview

#Preview {
    ContinuationsExample()
}
