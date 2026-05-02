import Foundation
import Combine
import FirebaseFirestore
class NationalParksViewModel : ObservableObject {
    @Published var introPages : [IntroPage] = []
    @Published var nationalParks : [ParkModel] = []
    @Published var isLoading = false
    @Published var hasError = false
    @Published var parkError : ParkModelError?
    @Published var favoriteParks = FavoriteParksModel()
    private let database = Firestore.firestore()
    func loadIntroPages() {
        guard introPages.isEmpty else { return }
        let captions = ["Discover America’s wild places",
                           "Plan your perfect park day",
                           "Learn about park activities and details",
                           "Start exploring national parks today"]
        let randomImages = (1...15)
            .map { String($0) }
            .shuffled()
            .prefix(4)
        introPages = zip(randomImages, captions).map {
            IntroPage(imageName: $0, caption: $1)
        }
    }
    @MainActor
    func fetchAllNationalParks() async {
        guard nationalParks.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            nationalParks = try await fetchParks()
        } catch {
            handle(error)
        }
    }
    private func fetchParks() async throws -> [ParkModel] {
        let baseUrl = "https://developer.nps.gov/api/v1/parks"
        let apiKey = "u9Rv0tfEv6KmVibSZ8lycyDdFvSijHc8eJ3PuAUP"
        guard var components = URLComponents(string : baseUrl) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "limit", value: "500")
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ParkAPIResponse.self, from: data)
        return response.data.filter {
            $0.designation == "National Park" || $0.designation == "National Park & Preserve"
        }
    }
    @MainActor
    func loadFavoriteParks(for userID: String) async {
        do {
            let snapshot = try await database.collection("history").document(userID).getDocument()
            favoriteParks = (try? snapshot.data(as: FavoriteParksModel.self)) ?? FavoriteParksModel(id: userID, favoriteParks: [])
        } catch {
            handle(error)
        }
    }
    @MainActor
    func toggleFavoritePark(_ parkID: String, for userID: String) async {
        var ids = Set(favoriteParks.favoriteParks)
        if ids.contains(parkID) {
            ids.remove(parkID)
        } else {
            ids.insert(parkID)
        }
        let updatedFavorites = ids.sorted()
        let model = FavoriteParksModel(id: userID, favoriteParks: updatedFavorites)
        favoriteParks = model
        do {
            try database.collection("history").document(userID).setData(from: model)
        } catch {
            handle(error)
        }
    }
    @MainActor
    func clearFavoriteParks() {
        favoriteParks = FavoriteParksModel()
    }
    @MainActor
    private func handle(_ error: Error) {
        hasError = true
        parkError = .customError(error: error)
    }
    struct ParkAPIResponse : Codable {
        let data : [ParkModel]
    }
    enum ParkModelError : LocalizedError {
        case customError(error: Error)
        var errorDescription: String? {
            switch self {
            case .customError(error: let error):
                return error.localizedDescription
            }
        }
    }
    var parks: [ParkModel] {
        get { nationalParks }
        set { nationalParks = newValue }
    }
    var favParks: FavoriteParksModel {
        get { favoriteParks }
        set { favoriteParks = newValue }
    }
    var err: ParkModelError? {
        get { parkError }
        set { parkError = newValue }
    }
    @MainActor
    func fetchAllParks() async {
        await fetchAllNationalParks()
    }
    @MainActor
    func loadFavParks(for userID: String) async {
        await loadFavoriteParks(for: userID)
    }
    @MainActor
    func toggleFavPark(_ parkID: String, for userID: String) async {
        await toggleFavoritePark(parkID, for: userID)
    }
    @MainActor
    func clearFavParks() {
        clearFavoriteParks()
    }
}
