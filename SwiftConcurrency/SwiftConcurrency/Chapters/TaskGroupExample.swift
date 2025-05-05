//
//  TaskGroupExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 08/02/2025.
//



// MARK: - NOTES

// MARK: 6 - How to use TaskGroup to perform concurrent Tasks in Swift
///
/// - `TaskGroup` jest przydatne wtedy gdy mamy do wykonania bardzo dużo zadań w tym samym czasie ponieważ `async let` nie jest skalowalne
/// - w przeciwieństwie do `async let` to `TaskGroup` może zwrócić jeden określony typ
/// - mega przydatne gdy np. mamy do pobrania 50 zdjęć za pomocą jednej metody - przy użyciu `async let` byłoby to 50 linijek
/// - aby utworzyć `TaskGroup` używamy metody `withTaskGroup(of:) { group in }` jeśli wywoływane wewnątrz metody nie rzucają błędu
/// - lub metody `withThrowingTaskGroup(of:) { group in }` jeśli wywoływane wewnątrz metody mogą rzucić błąd
/// - aby dodać nowy metody do wykonywania do `TaskGroup` używamy `group.addTask {...}`
/// - gdy metoda dodana w powyższy sposób może rzucić błąd warto oznaczyć ją za pomocą `try?` żeby jeden błąd przypadkiem nie zakończył wykonywania się wszystkich zadań w `TaskGroup` - w najgorszym przypadku dostaniemy wartości `nil` których nie użyjemy zamiast zakończyć wykonywania zadań przez błąd
/// - rezulat wykonywanych działań przechwytujemy za pomocą `for await in` lub `for try await in` w zależności czy mamy metody rzucające błąd czy nie
/// - np. `for try await image in group {...}`
/// - jeśli rezultat wykonywanych działań przypisujemy do tablicy to aby poprawić optymalizację możemy przypisać tablicy ile będzie miała minimalnie elementów
/// - do tego celu używamy `array.reserveCapacity()` i podajemy wartość typu `Int` jako argument



// MARK: - CODE

import SwiftUI

final class TaskGroupExampleManager {
    
    // MARK: - Methods
    
    /// ** ASYNC LET ** WITH THROWS
    func downloadImagesWithAsyncLet() async throws -> [UIImage] {
        async let image1 = downloadImage(with: "https://picsum.photos/200")
        async let image2 = downloadImage(with: "https://picsum.photos/200")
        async let image3 = downloadImage(with: "https://picsum.photos/200")
        async let image4 = downloadImage(with: "https://picsum.photos/200")
        return try await [image1, image2, image3, image4]
    }
    
    /// ** TASK GROUP ** WITH THROWS
    func downloadImagesWithTaskGroup() async throws -> [UIImage] {
        let urls: [String] = [
            "https://picsum.photos/200",
            "https://picsum.photos/200",
            "https://picsum.photos/200",
            "https://picsum.photos/200",
            "https://picsum.photos/200",
            "https://picsum.photos/200"
        ]
        return try await withThrowingTaskGroup(of: UIImage?.self) { [weak self] group in
            var images: [UIImage] = []
            images.reserveCapacity(urls.count)
            for url in urls {
                group.addTask {
                    try? await self?.downloadImage(with: url)
                }
            }
            for try await image in group {
                if let image {
                    images.append(image)
                }
            }
            return images
        }
    }
    
    /// ** TASK GROUP ** WITHOUT THROWS
    func downloadtitlesWithTaskGroup() async -> [String] {
        let strings: [String] = ["Apple", "Orange", "Cherry", "Watermelon"]
        return await withTaskGroup(of: String?.self) { [weak self] group in
            var titles: [String] = []
            titles.reserveCapacity(strings.count)
            for string in strings {
                group.addTask {
                    await self?.downloadTitle(with: string)
                }
            }
            for await title in group {
                if let title {
                    titles.append(title)
                }
            }
            return titles
        }
    }
    
    private func downloadImage(with urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeRawData)
        }
        return image
    }
    
    private func downloadTitle(with title: String) async -> String {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return title
    }
}



final class TaskGroupExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var images: [UIImage] = []
    
    @Published
    private(set) var titles: [String] = []
    
    private let manager = TaskGroupExampleManager()
    
    // MARK: - Methods
    
    func fetchImages() async {
        do {
            /// ** ASYNC LET **
            // let newImages = try await manager.downloadImagesWithAsyncLet()
            
            /// ** TASK GROUP **
            let newImages = try await manager.downloadImagesWithTaskGroup()
            await MainActor.run { [weak self] in
                self?.images.append(contentsOf: newImages)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchTitles() async {
        /// ** TASK GROUP **
        let newTitles = await manager.downloadtitlesWithTaskGroup()
        await MainActor.run { [weak self] in
            self?.titles = newTitles
        }
    }
}



struct TaskGroupExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = TaskGroupExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .frame(height: 150)
                    }
                }
                .padding()
                
                VStack {
                    ForEach(viewModel.titles, id: \.self) { title in
                        Text(title)
                    }
                }
            }
            .navigationTitle("Task Group")
            .task {
                await viewModel.fetchImages()
                await viewModel.fetchTitles()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TaskGroupExample()
}
