//
//  SearchableExample.swift
//  SwiftConcurrency
//
//  Created by Wojciech Spaleniak on 29/03/2025.
//



// MARK: - NOTES

// MARK: 16 - How to use Searchable, Search Suggestions, Search Scopes in SwiftUI
///
/// ** SEARCHABLE **
/// - modyfikator `.searchable(...)` dodaje nam do widoku gotowy pasek wyszukiwania
/// - jedyne co musimy dostarczyć to zmienna `Binding<String>` która przechowuje tekst wpisany w pasek wyszukiwania
/// - oraz logikę filtrowania danych spośród których można wyszukiwać
/// - jedynym minusem tego rozwiązania jest to że wygląd paska wyszukiwania jest mało modyfikowalny
///
/// ** SEARCH SCOPES **
/// - modyfikator `.searchScopes(...)` pozwala dodać dodatkowe filtrowanie za pomocą paska wyboru który pojawia się pod paskiem wyszukiwania
/// - musimy dostarczyć zmienną `Binding<...>` przechowującą aktualnie wybraną opcję
///
/// ** SEARCH SUGGESTIONS **
/// - modyfikator `.searchSuggestions` pozwala dodać listę sugerowanych elementów po kliknięciu w pasek wyszukiwania
/// - dodanie do pojedynczej sugestii modyfikatora `.searchCompletion` pozwala po kliknięciu w sugestię wprowadzić jej całą nazwę do paska wyszukiwania



// MARK: - CODE

import Combine
import SwiftUI

struct SearchableExampleDataModel: Identifiable, Hashable {
    let id: String
    let title: String
    let cuisine: CuisineOption
}

enum CuisineOption: String, Hashable {
    case american
    case italian
    case japanese
}



final class SearchableExampleDataManager: Sendable {
    
    // MARK: - Methods
    
    func fetchData() async throws -> [SearchableExampleDataModel] {
        [
            .init(id: "1", title: "American Burger", cuisine: .american),
            .init(id: "2", title: "Pasta Palace", cuisine: .italian),
            .init(id: "3", title: "Sushi Heaven", cuisine: .japanese),
            .init(id: "4", title: "Local market", cuisine: .american)
        ]
    }
}



@MainActor
final class SearchableExampleViewModel: ObservableObject {
    
    // MARK: - Enums
    
    enum SearchScopeOption: Hashable {
        case all
        case cuisine(CuisineOption)
        
        var title: String {
            switch self {
            case .all: "All"
            case let .cuisine(option): option.rawValue.capitalized
            }
        }
    }
    
    // MARK: - Properties
    
    @Published
    var searchScope: SearchScopeOption = .all
    
    @Published
    private(set) var allSearchScopes: [SearchScopeOption] = []
    
    @Published
    var searchText: String = ""
    
    @Published
    private(set) var filteredData: [SearchableExampleDataModel] = []
    
    private var data: [SearchableExampleDataModel] = []
    
    private var searchTextCancellable: AnyCancellable?
    
    private let manager = SearchableExampleDataManager()
    
    // MARK: - Init
    
    init() {
        addSearchTextObservation()
    }
    
    // MARK: - Methods
    
    func getData() async {
        do {
            data = try await manager.fetchData()
            filteredData = data
            
            let allCuisines = Set(data.map(\.cuisine))
            allSearchScopes = [.all] + Array(allCuisines).map(SearchScopeOption.cuisine)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getSearchSuggestions() -> [String] {
        guard searchText.count >= 2 else {
            return []
        }
        let search = searchText.lowercased()
        var suggestions: [String] = []
        if search.contains("bu") {
            suggestions.append("Burger")
        }
        if search.contains("pa") {
            suggestions.append("Pasta")
        }
        if search.contains("su") {
            suggestions.append("Sushi")
        }
        suggestions.append(CuisineOption.american.rawValue.capitalized)
        suggestions.append(CuisineOption.italian.rawValue.capitalized)
        suggestions.append(CuisineOption.japanese.rawValue.capitalized)
        return suggestions
    }
    
    func getRestaurantsSuggestions() -> [SearchableExampleDataModel] {
        guard searchText.count >= 2 else {
            return []
        }
        let search = searchText.lowercased()
        var suggestions: [SearchableExampleDataModel] = []
        if search.contains("ame") {
            suggestions.append(contentsOf: data.filter { $0.cuisine == .american })
        }
        if search.contains("ita") {
            suggestions.append(contentsOf: data.filter { $0.cuisine == .italian })
        }
        if search.contains("jap") {
            suggestions.append(contentsOf: data.filter { $0.cuisine == .japanese })
        }
        return suggestions
    }
    
    private func addSearchTextObservation() {
        searchTextCancellable = $searchText
            .combineLatest($searchScope)
            .debounce(for: .seconds(0.6), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText, currentSearchScope in
                guard let self else {
                    return
                }
                guard !searchText.isEmpty else {
                    filteredData = data
                    searchScope = .all
                    return
                }
                // Filter by search scope
                let filteredDataByScope = switch currentSearchScope {
                case .all: data
                case let .cuisine(option): data.filter { $0.cuisine == option }
                }
                // Filter by search text
                let search = searchText.lowercased()
                filteredData = filteredDataByScope.filter {
                    $0.title.lowercased().contains(search) ||
                    $0.cuisine.rawValue.lowercased().contains(search)
                }
            }
    }
}



struct SearchableExample: View {
    
    // MARK: - Properties
    
    @StateObject
    private var viewModel = SearchableExampleViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(viewModel.filteredData) { model in
                        NavigationLink(value: model) {
                            row(model)
                        }
                    }
                }
            }
            .navigationTitle("Restaurants")
            .task { await viewModel.getData() }
            .searchable(
                text: $viewModel.searchText,
                placement: .automatic,
                prompt: Text("Search restaurants...")
            )
            .searchScopes($viewModel.searchScope) {
                ForEach(viewModel.allSearchScopes, id: \.self) { scope in
                    Text(scope.title)
                        .tag(scope)
                }
            }
            .searchSuggestions {
                ForEach(viewModel.getSearchSuggestions(), id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
                ForEach(viewModel.getRestaurantsSuggestions(), id: \.self) { suggestion in
                    NavigationLink(value: suggestion) {
                        Text(suggestion.title.capitalized)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationDestination(for: SearchableExampleDataModel.self) { model in
                Text(model.title.uppercased())
            }
        }
    }
    
    // MARK: - Subviews
    
    func row(_ model: SearchableExampleDataModel) -> some View {
        VStack(alignment: .leading) {
            Text(model.title)
                .font(.headline)
            Text(model.cuisine.rawValue.capitalized)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .tint(.primary)
        .background(.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    SearchableExample()
}
