//
//  PhotosPickerExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 30/03/2025.
//



// MARK: - NOTES

// MARK: 17 - How to use PhotosPicker in SwiftUI & PhotosUI
///
/// - aby używać obiektu `PhotosPicker` musimy zaimportować bibliotekę `PhotosUI`
/// - podczas tworzenia obiektu przekazujemy mu zmienną typu `Binding<PhotosPickerItem?>` dla pojedynczego zaznaczenia
/// - lub `Binding<[PhotosPickerItem]>` dla wielokrotnego zaznaczenia
/// - aby przechwytywać wybierane przez użytkownika multimedia wystarczy nasłuchiwać na zmiany przekazanej powyżej zmiennej
/// - zmienna przychodzi jako typ `PhotosPickerItem` i musimy ją rozpakować do typu `Data`
/// - robimy to za pomocą metody `try await loadTransferable(type: Data.self)` wywoływanej na obiekcie typu `PhotosPickerItem`



// MARK: - CODE

import PhotosUI
import SwiftUI

@MainActor
final class PhotosPickerExampleViewModel: ObservableObject {
    
    // MARK: - Properties for single selection
    
    @Published
    private(set) var selectedImage: UIImage?
    
    @Published
    var photosPickerItem: PhotosPickerItem? = nil {
        didSet { setImage(photosPickerItem) }
    }
    
    // MARK: - Properties for multiple selection
    
    @Published
    private(set) var selectedImages: [UIImage] = []
    
    @Published
    var photosPickerItems: [PhotosPickerItem] = [] {
        didSet { setImages(photosPickerItems) }
    }
    
    // MARK: - Methods for single selection
    
    private func setImage(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }
        Task { [weak self] in
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "load transferable error", code: 99)
                }
                self?.selectedImage = UIImage(data: data)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Methods for multiple selection
    
    private func setImages(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else {
            return
        }
        Task { [weak self] in
            var images: [UIImage] = []
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else { continue }
                images.append(image)
            }
            self?.selectedImages = images
        }
    }
}



struct PhotosPickerExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = PhotosPickerExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            
            // MARK: UI for single selection
            
            PhotosPicker(
                selection: $viewModel.photosPickerItem,
                matching: .images,
                label: { Text("Select a photo") }
            )
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 250, height: 250)
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // MARK: UI for multiple selection
            
            PhotosPicker(
                selection: $viewModel.photosPickerItems,
                matching: .images,
                label: { Text("Select photos") }
            )
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(viewModel.selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhotosPickerExample()
}
