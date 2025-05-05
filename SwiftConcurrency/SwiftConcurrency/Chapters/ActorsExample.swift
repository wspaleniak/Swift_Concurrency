//
//  ActorsExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 12/02/2025.
//



// MARK: - NOTES

// MARK: 9 - How to use Actors and non-isolated in Swift
///
/// - problem jaki rozwiązuje `Actor` to `data race` czyli pole danego typu może być jednocześnie aktualizowane przez kilka wątków
/// - aby móc sobie zweryfikować czy bezpieczeństwo wątków jest zachowane możemy sobie włączyć `Edit Scheme... > Run > Diagnostics > Thread Sanitizer`
/// - dzięki temu możemy sprawdzić czy występuje jakieś `data race` podczas działania aplikacji
///
/// - aby zabezpieczyć klasę przed `data race` możemy zainicjalizować swój własny wątek `let lock = DispatchQueue(label:)`
/// - a następnie wszystkie działania któremu mogą powodować problem umieścić na tym wątku czyli `lock.async {...}`
/// - dzięki temu tylko jeden wątek będzie miał dostęp do pól klasy a nie kilka
/// - wszystko powyższe dzieje się automatycznie podczas użycia `Actor` ponieważ każdy dostęp czy to do zmiennej czy do metody musi zostać poprzedzony słowem `await`
/// - dzięki temu wątki czekają na siebie podczas dostępu do obiektu i nie występuje `data race`
///
/// - może się zdarzyć że wewnątrz obiektu `Actor` będzie zmienna lub metoda do której dostęp nie jest niebezpieczny i wiemy że nie spowoduje `data race`
/// - w takim przypadku możemy użyć przed jej definicją słowa `nonisolated`
/// - dzięki temu nie będziemy musieli odwoływać się do niej w środowisku asynchronicznym `Task` i poprzedzać dostęp do niej słowem `await`
/// - WAŻNE: wewnątrz metod oznaczonych jako `nonisolated` nie możemy wywoływać zwykłych metod zdefiniowanych w obiekcie `Actor`



// MARK: - CODE

import SwiftUI

/// ** LOCK **
final class ActorsExampleLockManager {
    
    // MARK: - Properties
    
    static let shared = ActorsExampleLockManager()
    
    private(set) var data: [String] = []
    
    private let lock = DispatchQueue(
        label: "pl.wspaleniak.SwiftConcurrency.ActorsExample"
    )
    
    // MARK: - Init
    
    private init() { }
    
    // MARK: - Methods
    
    func getRandomData(completion: @escaping (String?) -> Void) {
        lock.async { [weak self] in
            print("Thread: \(Thread.current)")
            self?.data.append(UUID().uuidString)
            completion(self?.data.randomElement())
        }
    }
}



/// ** ACTOR **
actor ActorsExampleActorManager {
    
    // MARK: - Properties
    
    static let shared = ActorsExampleActorManager()
    
    var data: [String] = []
    
    nonisolated let number: Int = 99
    
    // MARK: - Init
    
    private init() { }
    
    // MARK: - Methods
    
    func getRandomData() -> String? {
        print("Thread: \(Thread.current)")
        data.append(UUID().uuidString)
        return data.randomElement()
    }
    
    nonisolated func getSavedData() -> String {
        return "NEW DATA"
    }
}



struct ActorsExample: View {
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            ActorsExampleHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            ActorsExampleBrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
        }
    }
}



struct ActorsExampleHomeView: View {
    
    // MARK: - Properties
    
    @State
    private var text: String = ""
    
    @State
    private var newDataText: String = ""
    
    /// ** LOCK **
    // private let manager = ActorsExampleLockManager.shared
    
    /// ** ACTOR **
    private let manager = ActorsExampleActorManager.shared
    
    private let timer = Timer.publish(
        every: 0.1,
        on: .main,
        in: .common
    ).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text(text)
                .font(.headline)
            Text(newDataText)
                .font(.largeTitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.5))
        .onReceive(timer) { _ in
            /// ** LOCK **
            // DispatchQueue.global(qos: .background).async {
            //     manager.getRandomData { data in
            //         guard let data else {
            //             return
            //         }
            //         DispatchQueue.main.async {
            //             text = data
            //         }
            //     }
            // }
            
            /// ** ACTOR **
            Task {
                guard let data = await manager.getRandomData() else {
                    return
                }
                await MainActor.run {
                    text = data
                }
            }
        }
        
        /// ** ACTOR - ISOLATED ACCESS **
        // .onAppear {
        //     Task {
        //         let newData = await manager.getSavedData()
        //         let newNumber = await manager.number
        //         await MainActor.run {
        //             newDataText = "\(newData) \(newNumber)"
        //         }
        //     }
        // }
        
        /// ** ACTOR - NONISOLATED ACCESS **
        .onAppear {
            let newData = manager.getSavedData()
            let newNumber = manager.number
            newDataText = "\(newData) \(newNumber)"
        }
    }
}



struct ActorsExampleBrowseView: View {
    
    // MARK: - Properties
    
    @State
    private var text: String = ""
    
    /// ** LOCK **
    // private let manager = ActorsExampleLockManager.shared
    
    /// ** ACTOR **
    private let manager = ActorsExampleActorManager.shared
    
    private let timer = Timer.publish(
        every: 0.01,
        on: .main,
        in: .common
    ).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text(text)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.brown.opacity(0.5))
        .onReceive(timer) { _ in
            /// ** LOCK **
            // DispatchQueue.global(qos: .default).async {
            //     manager.getRandomData { data in
            //         guard let data else {
            //             return
            //         }
            //         DispatchQueue.main.async {
            //             text = data
            //         }
            //     }
            // }
            
            /// ** ACTOR **
            Task {
                guard let data = await manager.getRandomData() else {
                    return
                }
                await MainActor.run {
                    text = data
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ActorsExample()
}
