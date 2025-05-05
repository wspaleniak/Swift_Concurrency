//
//  GlobalActorsExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 13/02/2025.
//



// MARK: - NOTES

// MARK: 10 - How to use Global Actors in Swift (@globalActor)
///
/// ** GLOBAL ACTOR **
/// - aby stworzyć `GlobalActor` tworzymy `final class` lub `Sruct` oznaczone jako `@globalActor`
/// - stworzenie takiej klasy lub struktury wymaga umieszczenia w niej statycznej zmiennej z obiektem typu `Actor`
/// - w naszym przykładzie mamy obiekt typu `Actor` który jest managerem i nazywa się `GlobalActorsExampleManager`
/// - w naszym przykładzie `GlobalActor` nazywa się `MyGlobalActor` - izoluje on zmienne, metody i obiekty nie będące w zasięgu aktora `GlobalActorsExampleManager` do tego właśnie aktora - są wtedy wywoływane na tym samym wątku
/// - czyli metoda oznaczona za pomocą `@MyGlobalActor` wywoływana jest zawsze w asynchronicznym środowisku czyli poprzedzona słowem `await` - nawet jeśli nie jest oznaczona slowem `async` - działa to tak dlatego że taka metoda jest izolowana do wybranego aktora - w tym przypadku do `GlobalActorsExampleManager`
/// - nie jest to często używane rozwiązanie ale można skorzystać okazjonalnie
/// - WAŻNE: gdy chcemy używać stworzonego `MyGlobalActor` to odwołujemy się do obiektu aktora np. `GlobalActorsExampleManager` poprzez instancję aktora globalnego czyli nie tworzymy instancji aktora w ten sposób `let manager = GlobalActorsExampleManager()` tylko tak `let manager = MyGlobalActor.shared`
/// - oczywiście możemy tworzyć instancje aktora w ten sposób `let manager = GlobalActorsExampleManager()` - ale wtedy nie będzimy korzystać z globalnego aktora
///
/// ** MAIN ACTOR **
/// - `MainActor` również jest globalnym aktorem
/// - jeżeli chemy mieć pewność że coś się wywoła na głównym wątku to oznaczamy to za pomocą `@MainActor`
/// - możemy oznaczać zmienne, metody i obiekty - np. oznaczenie całego obiektu `Class` lub `Struct` za pomocą `@MainActor` oznacza że wszystkie zmienne i wszystkie metody będą się wykonywać na głownym wątku
/// - wtedy też możemy niektóre metody oznaczyć jako `nonisolated` jeśli nie chcemy żeby były izolowane do globalnego aktora `@MainActor`



// MARK: - CODE

import SwiftUI

// @globalActor
// struct MyGlobalActor {
//     static let shared = GlobalActorsExampleManager()
// }

@globalActor
final class MyGlobalActor {
    static let shared = GlobalActorsExampleManager()
}



actor GlobalActorsExampleManager {
    
    // MARK: - Methods
    
    func downloadData() -> [String] {
        return ["One", "Two", "Three", "Four", "Five", "Six"]
    }
}



// @MyGlobalActor
@MainActor
final class GlobalActorsExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    // @MainActor @Published
    // @MyGlobalActor @Published
    @Published
    private(set) var data: [String] = []
    
    private let manager = MyGlobalActor.shared
    
    // MARK: - Methods
    
    // @MainActor
    @MyGlobalActor
    func fetchData() {
        Task {
            let data = await manager.downloadData()
            await MainActor.run { [weak self] in
                self?.data = data
            }
        }
    }
}



struct GlobalActorsExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = GlobalActorsExampleViewModel()
    
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
    GlobalActorsExample()
}
