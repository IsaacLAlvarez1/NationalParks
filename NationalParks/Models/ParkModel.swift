import Foundation
struct ParkModel : Codable, Identifiable {
    var id : String
    var fullName : String
    var states : String
    var designation : String
    var images : [ParkImageModel]
    var description: String?
    var latitude: String?
    var longitude: String?
    var activities : [Activity]?
    var directionsInfo: String?
    var weatherInfo : String?
    var operatingHours : [OperatingHour]?
    var entranceFees : [EntranceFee]?
}
struct Activity : Codable, Identifiable {
    var id : String
    var name : String
}
struct OperatingHour : Codable {
    var description : String
}
struct EntranceFee : Codable, Identifiable {
    var id : UUID { UUID() }
    var cost : String
    var title : String
}
struct ParkImageModel : Codable {
    var url : String
    var alt : String
    enum CodingKeys : String, CodingKey {
        case url
        case alt = "altText"
    }
}
