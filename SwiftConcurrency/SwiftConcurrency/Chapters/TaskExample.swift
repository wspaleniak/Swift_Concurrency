//
//  TaskExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 08/02/2025.
//



// MARK: - NOTES

// MARK: 4 - How to use Task and .task in Swift
///
/// - jeśli mamy dwie metody oznaczone jako `async` i umieścimy je w jedym `Task {...}` to wykonają się jedna po drugiej
/// - natomiast jeśli każdą umieścimy w osobnym `Task {...}` to wykonają się jednocześnie
/// - `Task` może mieć priorytet: `low = 17`, `medium = 21`, `high = 25`, `background = 9`, `utility = 17`, `userInitiated = 25`
/// - w zależności od nadanego `priority` w `Task(priority:)` taski sa priorytetyzowane podczas ich wykonywania
/// - natomiast nie znaczy to że `Task` z większym priorytetem zakończy się szybciej - system sam to optymalizuje
/// - użycie `await Task.yield()` wewnątrz `Task {...}` pozwala na dobrowolne oddanie sterowania innym zadaniom w systemie współbieżności
/// - `await Task.yield()` nie usypia zadania ale pozwala na przełączanie kontekstu - może pomóc w poprawie wydajności aplikacji
/// - jeśli wewnątrz `Task(priority: .low) {...}` dodamy kolejny `Task {...}` ale już bez priorytetu to ten task odziedziczy priorytet po rodzicu czyli również będzie miał priorytet `.low`
/// - aby `Task` dziecko nie dziedziczyło priorytetu po `Task` rodzicu należy `Task` dziecko oznaczyć jako `Task.detached {...}`
/// - dodawanie tasków wewnątrz innych tasków nie jest rekomendowane i służy do tego `TaskGroup`
/// - `Task` nie kończy swojego działania po wyjściu z widoku na którym został zainicjalizowany dlatego trzeba zakończyć go ręcznie
/// - aby to zrobić należy przechować go w widoku czyli np. `@State private var imageTask: Task<Void, Never>? = nil`
/// - używamy `@State` tylko dlatego że jest to na widoku - w view modelu może być to zwykła zmienna bez `@State`
/// - nastepnie w `.onAppear {...}` przypisujemy mu task czyli `imageTask = Task {...}`
/// - dzięki temu w `.onDisappear {...}` możemy wywołać na nim metodę `imageTask?.cancel()` oraz `imageTask = nil` aby zakończyć jego działanie
/// - zamiast używać `.onAppear {...}` i wewnątrz tworzyć `Task {...}` aby wywołać metodę oznaczoną jako `async` możemy użyć modyfikatora `.task {...}`
/// - dodatkową zaletą jest to że nie musimy ręcznie kończyć `Task` na wyjściu z widoku ponieważ kończy się on automatycznie gdy opuszczamy widok
/// - wyjątkiem może być `Task` który wewnątrz wykonuje skomplikowane długotrwałe operacje i nie zostanie przerwany np. długotrwała pętla `for-in` - w takim przypadku warto sprawdzać wewnątrz takiej pętli czy `Task` nie został już zakończony - sprawdzamy przy pomocy `try Task.checkCancellation()` - jeśli został zakończony to zostanie rzucony błąd i cały `Task` zakończy działanie



// MARK: - CODE

import SwiftUI

final class TaskExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    private(set) var image: UIImage? = nil
    
    @Published
    private(set) var nextImage: UIImage? = nil
    
    // MARK: - Methods
    
    func fetchImage() async {
        do {
            guard let url = URL(string: "https://picsum.photos/200") else {
                return
            }
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run { [weak self] in
                self?.image = UIImage(data: data)
                print("Image was dowloaded successfully")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchNextImage() async {
        do {
            guard let url = URL(string: "https://picsum.photos/200") else {
                return
            }
            try await Task.sleep(nanoseconds: 5_000_000_000)
            try Task.checkCancellation()
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run { [weak self] in
                self?.nextImage = UIImage(data: data)
                print("Next image was dowloaded successfully")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}



struct TaskExampleHome: View {
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            NavigationLink("NEW SCREEN >>") {
                TaskExample()
            }
        }
    }
}



struct TaskExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = TaskExampleViewModel()
    
    @State
    private var imageTask: Task<Void, Never>? = nil
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            imageView(viewModel.image)
            imageView(viewModel.nextImage)
        }
        .onAppear {
            /// ** POBIERANIE JEDNO PO DRUGIM **
            // Task {
            //     await viewModel.fetchImage()
            //     await viewModel.fetchNextImage()
            // }
            
            /// ** POBIERANIE JEDNOCZEŚNIE **
            // Task {
            //     await viewModel.fetchImage()
            // }
            // Task {
            //     await viewModel.fetchNextImage()
            // }
            
            /// ** PRIORYTETY **
            // Task(priority: .low) {
            //     print("LOW / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            // Task(priority: .medium) {
            //     print("MEDIUM / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            // Task(priority: .high) {
            //     await Task.yield()
            //     print("HIGH / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            // Task(priority: .background) {
            //     print("BACKGROUND / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            // Task(priority: .utility) {
            //     print("UTILITY / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            // Task(priority: .userInitiated) {
            //     print("USER INITIATED / thread: \(Thread()) / priority: \(Task.currentPriority.rawValue) ")
            // }
            
            /// ** DZIEDZICZENIE PRIORYTETÓW **
            // DZIECKO DZIEDZICZY PRIORYTET - ZALEŻNE OD RODZICA
            // Task(priority: .low) {
            //     Task { }
            // }
            // DZIECKO NIE DZIEDZICZY PRIORYTETU - NIEZALEŻNE OD RODZICA
            // Task(priority: .low) {
            //     Task.detached { }
            // }
            
            /// ** KOŃCZNIE DZIAŁANIA **
            // imageTask = Task {
            //     await viewModel.fetchImage()
            // }
        }
        /// ** KOŃCZNIE DZIAŁANIA **
        // .onDisappear {
        //     imageTask?.cancel()
        //     imageTask = nil
        // }
        .task {
            await viewModel.fetchImage()
            await viewModel.fetchNextImage()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func imageView(_ image: UIImage?) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
        } else {
            Circle()
                .frame(width: 200, height: 200)
                .overlay { ProgressView().tint(.white) }
        }
    }
}

// MARK: - Preview

#Preview {
    TaskExampleHome()
}
