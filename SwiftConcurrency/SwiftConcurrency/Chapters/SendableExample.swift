//
//  SendableExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 13/02/2025.
//



// MARK: - NOTES

// MARK: 11 - What is the Sendable protocol in Swift?
///
/// - `Sendable` jest protokołem który deklaruje czy obiekt jest bezpieczny do wysłania w asynchronicznym środowisku
/// - przydatne gdy chcemy przekazywać obiekty typu `Class` do obiektów typu `Actor` np. jako argument metody
/// - może być sytuacja że jakiś obiekt wysyła dane typu `Class` do obiektu typu `Actor` - klasa nie jest bezpieczna w środowisku asynchronicznym więc żeby to było bezpieczne to klasa musi być zgodna z protkołem `Sendable`
/// - żeby klasa mogła być zgodna z protokołem `Sendable` musi być oznaczona jako `final`
/// - oraz nie może posiadać żadnych pól oznaczonych jako `var`ponieważ inne obiekty nie mogą mieć możliwości żeby ją modyfikować
/// - jeśli jednak zdarzy się tak że obiekt `Class` będzie miał pola oznaczone jako `var` ale mamy pewność że żaden inny obiekt nie modyfikuje tych wartości to możemy oznaczyć klasę jako `@unchecked Sendable` - wtedy dajemy znać kompilatorowi że taka klasa jest bezpieczna - ale nie jest to rekomendowane rozwiązanie - w takim przypadku warto zabezpieczyć klasę za pomocą `let lock = DispatchQueue(label:)` i ewentualne modyfikacje pól wykonywać na tym wątku
/// - obiekty przekazywane przez wartość czyli np. `Struct`, `Enum`, `String` etc. są automatycznie zgodne z protokołem `Sendable` dopóki wszystkie typy wewnąrz obiektu są również zgodne z protokołem `Sendable`
/// - dodawanie w kodzie zgodności z protokołem `Sendable` dla typów przekazywanych przez wartość dodaje lekką optymalizację w działaniu aplikacji



// MARK: - CODE

import SwiftUI

struct SendableExampleStructModel: Sendable {
    let name: String
}

final class SendableExampleClassModel: Sendable {
    let name: String
    init(name: String) { self.name = name }
}

final class SendableExampleUncheckedClassModel: @unchecked Sendable {
    private var name: String
    private let lock = DispatchQueue(label: "com.example.uncheckedClass")
    
    init(name: String) { self.name = name }
    
    func update(_ newName: String) {
        lock.async { [weak self] in
            self?.name = newName
        }
    }
}



actor SendableExampleManager {
    
    // MARK: - Methods
    
    func updateDatabase(_ data: SendableExampleStructModel) {
        //...
    }
    
    func updateDatabase(_ data: SendableExampleClassModel) {
        //...
    }
    
    func updateDatabase(_ data: SendableExampleUncheckedClassModel) {
        //...
    }
}



final class SendableExampleViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private let manager = SendableExampleManager()
    
    // MARK: - Methods
    
    func update() async {
        let structData = SendableExampleStructModel(name: "New data")
        await manager.updateDatabase(structData)
        
        let classData = SendableExampleClassModel(name: "New data")
        await manager.updateDatabase(classData)
        
        let uncheckedClassData = SendableExampleUncheckedClassModel(name: "New data")
        await manager.updateDatabase(uncheckedClassData)
        
    }
}



struct SendableExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = SendableExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Text("Hello, World!")
            .task {
                await viewModel.update()
            }
    }
}

// MARK: - Preview

#Preview {
    SendableExample()
}
