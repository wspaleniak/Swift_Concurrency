//
//  DownloadImagesExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 07/02/2025.
//



// MARK: - NOTES

// MARK: 2 - Download images with Async/Await, @escaping, and Combine
///
/// - ONLY CODE



// MARK: - CODE

import Combine
import SwiftUI

final class DownloadImagesExampleManager {
    
    // MARK: - Properties
    
    private let url = URL(string: "https://picsum.photos/200")
    
    // MARK: - Methods
    
    // ESCAPING CLOSURE
    func downloadWithEscapingClosure(completion: @escaping (Result<UIImage?, Error>) -> Void) {
        guard let url else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            let image = self?.handleResponse(
                data: data,
                response: response
            )
            completion(.success(image))
        }.resume()
    }
    
    // COMBINE
    func downloadWithCombine() -> AnyPublisher<UIImage?, Error>? {
        guard let url else { return nil }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    // ASYNC AWAIT
    func downloadWithAsyncAwait() async throws -> UIImage? {
        guard let url else { return nil }
        let (data, response) = try await URLSession.shared.data(from: url)
        return handleResponse(data: data, response: response)
    }
    
    private func handleResponse(
        data: Data?,
        response: URLResponse?
    ) -> UIImage? {
        guard let data,
              let image = UIImage(data: data),
              let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode)
        else { return nil }
        return image
    }
}



final class DownloadImagesExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var image: UIImage? = nil
    
    private let manager = DownloadImagesExampleManager()
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Methods
    
    // ESCAPING CLOSURE && COMBINE
    func fetchImage() {
        // manager.downloadWithEscapingClosure { [weak self] result in
        //     switch result {
        //     case .success(let image):
        //         DispatchQueue.main.async {
        //             self?.image = image
        //         }
        //     case .failure(let error):
        //         print(error.localizedDescription)
        //     }
        // }
        
        // manager.downloadWithCombine()?
        //     .receive(on: DispatchQueue.main)
        //     .sink { result in
        //         switch result {
        //         case .finished:
        //             break
        //         case .failure(let error):
        //             print(error.localizedDescription)
        //         }
        //     } receiveValue: { [weak self] image in
        //         self?.image = image
        //     }
        //     .store(in: &cancellables)
    }
    
    // ASYNC AWAIT
    @MainActor
    func fetchImage() async {
        do {
            image = try await manager.downloadWithAsyncAwait()
        } catch {
            print(error.localizedDescription)
        }
    }
}



struct DownloadImagesExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = DownloadImagesExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: 300, height: 300)
                    .overlay { ProgressView().tint(.white) }
            }
        }
        // ESCAPING CLOSURE && COMBINE
        .onAppear {
            viewModel.fetchImage()
        }
        // ASYNC AWAIT
        .task {
            await viewModel.fetchImage()
        }
    }
}

// MARK: - Preview

#Preview {
    DownloadImagesExample()
}
