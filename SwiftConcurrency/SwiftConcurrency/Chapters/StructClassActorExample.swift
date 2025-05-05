//
//  StructClassActorExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 10/02/2025.
//



// MARK: - NOTES

// MARK: 8 - Swift: Struct vs Class vs Actor, Value vs Reference Types, Stack vs Heap
///
/// ** STRUCT **
/// - ma defaultową metodę `init()` z której można skorzystać i nie trzeba jej definiować
/// - pola obiektu utworzonego przy pomocy `Struct` możemy modyfikować tylko jeśli dane pole oraz cały obiekt oznaczone są jako `var`
/// - tak naprawdę nie modyfikujemy pola w tym obiekcie tylko zwracamy całkiem nowy obiekt z innymi wartościami
/// - działa to tak dlatego że `Struct`jest typem przekazującym wartość a nie referencję
/// - jeśli zrobimy coś takiego jak w przykładzie `var structB = structA` to obiektowi `structB` nie przekażemy referencji do obiektu `structA` tylko przekażemy mu aktualną wartość obiektu `structA`
/// - `Struct` jest `immutable` w momencie gdy wszystkie pola ma oznaczone jako `let` - wtedy nie możemy modyfikować pól - możemy tylko podmienić obiekt na nowy
/// - gdy chcemy wewnątrz `Struct` w metodzie modyfikować pola struktury oznaczone jako `var` to taka metoda musi być oznaczona jako `mutating` - tak naprawdę ta metoda nie będzie aktualizować pól aktualnego obiektu ale stworzy całkiem nowy obiekt ze zmodyfikowanymi polami
/// - słowo `mutating` jest dostępne tylko dla typów przekazywanych przez wartość - oznacza to że bierze wartości aktualnego obiektu podmienia je i zwraca całkiem nowy obiekt
///
/// ** CLASS **
/// - metoda `init()` musi być jawnie zdefiniowana - nie tak jak w strukturze
/// - aby zmienna klasy mogła być modyfikowana to musi być oznaczona jako `var` - ale sam obiekt klasy może być stałą oznaczoną jako `let`
/// - modyfikując pole obiektu który jest klasą rzeczywiście modyfikujemy jego pole - po modyfikacji jest to cały czas ten sam obiekt - dlatego obiekt może być oznaczony jako `let`
/// - działa to tak dlatego że przypisując zmiennej `let classB = classA` tak naprawdę nie przekazujemy jej wartości tak jak w `Struct` - tylko referencję do tego konkretnego obiektu w pamięci - w takim przypadku obie te zmienne są tak naprawdę jednym i tym samym obiektem
///
/// ** STRUCT vs CLASS **
/// - przewaga struktury nad klasą jest taka że przekazywanie przez WARTOŚĆ jest dużo szybsze niż przekazywanie przez REFERENCJĘ
/// - działa to szybciej ponieważ obiekty nie muszą być ze sobą synchronizowane
/// - to nie znaczy jednak że używanie `Struct` jest zawsze lepsze od używania `Class`
/// - modyfikując pole w `Struct` podmieniamy tak naprawdę cały obiekt
/// - modyfikując pole w `Class` podmieniamy wartość tylko dla tego pola
/// - obiekty typu `Struct` są blokami danych które przechowywane są w `Stack` - nie potrzebują referencji ponieważ przekazywane są przez wartość
/// - obiekty typu `Class` są blokami danych które przechowywane są w `Heap`- do każdego takiego obiektu trzymana jest referencja która odnosi się do ich miejsca w pamięci
/// - używanie `Struct` jest preferowane przez Apple ponieważ kopiowanie wartości jest bezpieczniejsze niż posiadanie wielu referencji do tego samego obiektu tak jak w `Class`
/// - używanie `Struct` zapobiega również wyciekom pamięci oraz tzw. `multiple threads racing` gdzie wartość zmiennej może być modyfikowana z różnych wątków
/// - wszystkie wątki mają tylko jeden `Heap` gdzie trzymane są obiekty przekazywane przez referencję
/// - natomiast każdy wątek ma swój oddzielny `Stack` gdzie trzymane są obiekty przekazywane przez wartość
/// - jest tak dlatego że `Stack` jest zsynchronizowany tylko ze swoim wątkiem - natomiast `Heap` musi mieć synchronizację ze wszystkimi wątkami
/// - `ARC - Automatic Reference Counting` jest używany tylko dla `Class` i pozwala zwolnić pamięć w `Heap` jeśli żadna referencja do danej instancji nie jest już potrzebna
/// - `weak` używamy tylko i wyłącznie w odniesieniu do obiektów typu `Class` - jeśli np. w closure nie dodamy `[weak self]` a używamy odniesienia do `self` wewnątrz domknięcia to mówimy kompilatorowi że ta klasa jest nam potrzebna - wtedy `ARC` będzie trzymać referencję do niej w pamięci zamiast zwolnić gdy nastąpi `deinit` - dodając `[weak self]` mówimy kompilatorowi że nie ma dla nas znaczenia czy ta klasa istnieje czy nie - jeśli będzie to wykonaj blok kodu a jeśli nie będzie to nie wykonuj - ale nie musisz trzymać referencji do obiektu specjalnie dla tego bloku kodu
///
/// ** CLASS vs ACTOR
/// - `Actor` jest właściwie tym co `Class` ale jest bezpieczny w kontekście wielowątkowości
/// - w przypadku `Class` gdy dwa różne wątki chcą zmienić wybrany obiekt to po prostu to robią
/// - w przypadku `Actor` gdy dwa różne wątki chcą zmienić wybrany obiekt to drugi w kolejności wątek poczeka aż ten pierwszy skończy swoje działanie
/// - dostęp do obiektu `Actor` jest asynchroniczny - czyli odwołanie się do jego pól i metod musi być poprzedzone słowem `await` czyli musi się znajdować w metodzie oznaczonej jako `async` lub wewnątrz `Task`
/// - nie ma możliwości zmiany pól obiektu `Actor` z zewnątrz - możemy to zrobić tylko poprzez wewnętrzną metodę
/// - `Actor` również jest przechowywany w `Heap` i tak jak `Class` jest przekazywany przez referencję
///
/// ** KIEDY UŻYWAĆ KTÓREGO **
/// STRUCT:
/// - modele danych
/// - widoki w SwiftUI
/// CLASS:
/// - view modele
/// ACTOR:
/// - service / manager
/// - obiekty typu singleton do których odwołanie jest w wielu miejscach w kodzie
/// - gdy wiele obiektów może zmieniać stan pól w obiekcie z różnych wątków



// MARK: - CODE

import SwiftUI

struct StructClassActorExample: View {
    
    // MARK: - Body
    
    var body: some View {
        Text("Hello, World!")
            .onAppear { runTest() }
    }
    
    // MARK: - Methods
    
    private func runTest() {
        print("START TESTS:")
        print("- - - - - - -")
        
        structTest1()
        classTest1()
        actorTest1()
        
        structTest2()
        classTest2()
    }
}

// MARK: - Preview

#Preview {
    StructClassActorExample()
}



// MARK: - STRUCT

struct MyStruct {
    var title: String
}

struct YourStruct {
    let title: String
    
    func updateTitle(_ newTitle: String) -> Self {
        YourStruct(title: newTitle)
    }
}

struct MutatingStruct {
    private(set) var title: String
    
    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
    }
}

extension StructClassActorExample {
    
    private func structTest1() {
        print("* STRUCT TEST 1 *")
        
        let structA = MyStruct(title: "Starting title")
        print("StructA: ", structA.title)
        
        var structB = structA
        print("StructB: ", structB.title)
        
        structB.title = "Second title"
        print("StructB title changed")
        
        print("StructA: ", structA.title)
        print("StructB: ", structB.title)
        
        print("- - - - - - -")
    }
    
    private func structTest2() {
        print("* STRUCT TEST 2 *")
        
        var structA = MyStruct(title: "Starting title")
        print("StructA: ", structA.title)
        structA.title = "New title"
        print("StructA: ", structA.title)
        
        var structB = YourStruct(title: "Starting title")
        print("StructB: ", structB.title)
        structB = YourStruct(title: "New title")
        print("StructB: ", structB.title)
        
        var structC = YourStruct(title: "Starting title")
        print("StructC: ", structC.title)
        structC = structC.updateTitle("New title")
        print("StructC: ", structC.title)
        
        var structD = MutatingStruct(title: "Starting title")
        print("StructD: ", structD.title)
        structD.updateTitle("New title")
        print("StructD: ", structD.title)
        
        print("- - - - - - -")
    }
}



// MARK: - CLASS

class MyClass {
    var title: String
    
    init(title: String) {
        self.title = title
    }
}

class YourClass {
    private(set) var title: String
    
    init(title: String) {
        self.title = title
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
    }
}

extension StructClassActorExample {
    
    private func classTest1() {
        print("* CLASS TEST 1 *")
        
        let classA = MyClass(title: "Starting title")
        print("ClassA: ", classA.title)
        
        let classB = classA
        print("ClassB: ", classB.title)
        
        classB.title = "Second title"
        print("ClassB title changed")
        
        print("ClassA: ", classA.title)
        print("ClassB: ", classB.title)
        
        print("- - - - - - -")
    }
    
    private func classTest2() {
        print("* CLASS TEST 2 *")
        
        let classA = MyClass(title: "Starting title")
        print("ClassA: ", classA.title)
        classA.title = "New title"
        print("ClassA: ", classA.title)
        
        let classB = YourClass(title: "Starting title")
        print("ClassB: ", classB.title)
        classB.updateTitle("New title")
        print("ClassB: ", classB.title)
        
        print("- - - - - - -")
    }
}



// MARK: - ACTOR

actor MyActor {
    var title: String
    
    init(title: String) {
        self.title = title
    }
    
    func updateTitle(_ newTitle: String) {
        title = newTitle
    }
}

extension StructClassActorExample {
    
    func actorTest1() {
        Task {
            print("* ACTOR TEST 1 *")
            
            let actorA = MyActor(title: "Starting title")
            await print("ActorA: ", actorA.title)
            
            let actorB = actorA
            await print("ActorB: ", actorB.title)
            
            await actorB.updateTitle("Second title")
            print("ActorB title changed")
            
            await print("ActorA: ", actorA.title)
            await print("ActorB: ", actorB.title)
            
            print("- - - - - - -")
        }
    }
}
