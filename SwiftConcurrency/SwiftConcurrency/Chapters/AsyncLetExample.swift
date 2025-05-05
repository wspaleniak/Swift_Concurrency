//
//  AsyncLetExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 08/02/2025.
//



// MARK: - NOTES

// MARK: 5 - How to use Async Let to perform concurrent methods in Swift
///
/// - użycie `async let` pozwala na jednoczesne wywołanie wielu metod oznaczonych jako `async`
/// - dzięki temu wiele zadań może wykonywać się jednocześnie a wynik wszystkich otrzymujemy w tym samym czasie
/// - do zmiennej oznaczonej `async let` przypisujemy meodę oznaczoną jako `async` lub `async throws`
/// - wygląda to następująco `async let image = fetchImage()` - nie musimy używać ani `await` ani `try`
/// - używamy ich dopiero potem, podczas odwołania się do zmiennych
/// - wygląda to tak
/// - `async let image1 = fetchImage()`
/// - `async let image2 = fetchImage()`
/// - `let (i1, i2) = await (try image1, try image2)`
/// - powyższe możemy zapisać jeszcze prościej
/// - `let (i1, i2) = try await (image1, image2)`
/// - lub jeszcze prościej
/// - `let images = try await [image1, image2]`
/// - wszystkie zadania `async let` są umieszczone w jednym `Task {...}` więc anulowanie tego taska kończy wszystkie te zadania



// MARK: - CODE

import SwiftUI

struct AsyncLetExample: View {
    
    // MARK: - Properties
    
    @State
    private var images: [UIImage] = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .frame(height: 150)
                    }
                }
                .padding()
            }
            .navigationTitle("Async Let")
            .onAppear {
                /// ** POBIERANIE JEDNO PO DRUGIM - JEDEN TASK **
                // Task {
                //     let image1 = try await fetchImage()
                //     images.append(image1)
                //     let image2 = try await fetchImage()
                //     images.append(image2)
                //     let image3 = try await fetchImage()
                //     images.append(image3)
                //     let image4 = try await fetchImage()
                //     images.append(image4)
                // }
                
                /// ** POBIERANIE JEDNOCZEŚNIE - WIELE TASKÓW **
                // Task {
                //     let image = try await fetchImage()
                //     images.append(image)
                // }
                // Task {
                //     let image = try await fetchImage()
                //     images.append(image)
                // }
                // Task {
                //     let image = try await fetchImage()
                //     images.append(image)
                // }
                // Task {
                //     let image = try await fetchImage()
                //     images.append(image)
                // }
                
                /// ** POBIERANIE JEDNOCZEŚNIE - ASYNC LET **
                Task {
                    // ZWRACA IDENTYCZNE TYPY
                    async let image1 = fetchImage()
                    async let image2 = fetchImage()
                    async let image3 = fetchImage()
                    async let image4 = fetchImage()
                    // let (i1, i2, i3, i4) = await (try image1, try image2, try image3, try image4)
                    // let (i1, i2, i3, i4) = try await (image1, image2, image3, image4)
                    // let images = try await (image1, image2, image3, image4)
                    let images = try await [image1, image2, image3, image4]
                    self.images = images
                    
                    // ZWRACA RÓŻNE TYPY + JEDNA METODA NIE RZUCA BŁĘDEM
                    async let image = fetchImage()
                    async let title = fetchTitle()
                    let (newImage, newTitle) = await (try image, title)
                    self.images.append(newImage)
                    print("Title: \(newTitle)")
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func fetchImage() async throws -> UIImage {
        guard let url = URL(string: "https://picsum.photos/200") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeRawData)
        }
        return image
    }
    
    private func fetchTitle() async -> String {
        return "NEW TITLE"
    }
}

// MARK: - Preview

#Preview {
    AsyncLetExample()
}
