import Foundation
struct FavoriteParksModel: Codable, Identifiable {
    var id: String
    var favoriteParks: [String]
    init(id: String = "", favoriteParks: [String] = []) {
        self.id = id
        self.favoriteParks = favoriteParks
    }
    var parks: [String] {
        get { favoriteParks }
        set { favoriteParks = newValue }
    }
}
