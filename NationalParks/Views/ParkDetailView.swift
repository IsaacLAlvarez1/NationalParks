import SwiftUI
import MapKit
struct ParkDetailView: View {
    var park: ParkModel
    var coord : CLLocationCoordinate2D? {
        if let latStr = park.latitude,
           let longStr = park.longitude,
           let lat = Double(latStr),
           let long = Double(longStr)
        {
            return CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        return nil
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(park.fullName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                Text(park.states)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                if let coord = coord {
                    Map {
                        Marker(park.fullName, coordinate: coord)
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("Open in Maps") {
                        openDirections(to: coord)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let description = park.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                }
                if let activities = park.activities, !activities.isEmpty {
                    Text("Things To Do")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(activities) { activity in
                                Text(activity.name)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                if let directionsInfo = park.directionsInfo, !directionsInfo.isEmpty {
                    Text("Directions")
                        .font(.headline)
                    Text(directionsInfo)
                        .font(.subheadline)
                }
                if let weatherInfo = park.weatherInfo, !weatherInfo.isEmpty {
                    Text("Weather")
                        .font(.headline)
                    Text(weatherInfo)
                        .font(.subheadline)
                }
                if let hours = park.operatingHours?.first, !hours.description.isEmpty {
                    Text("Operating Hours")
                        .font(.headline)
                    Text(hours.description)
                        .font(.subheadline)
                }
                if let fees = park.entranceFees, !fees.isEmpty {
                    Text("Entrance Fees")
                        .font(.headline)
                    ForEach(fees) { fee in
                        HStack {
                            Text(fee.title)
                                .font(.subheadline)
                            Spacer()
                            Text("$\(fee.cost)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Park Info")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func openDirections(to coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = park.fullName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
#Preview {
    ParkDetailView(park: ParkModel(
        id: "yose",
        fullName: "Yosemite National Park",
        states: "CA",
        designation: "National Park",
        images: [],
        description: "Yosemite is famous for its granite cliffs, waterfalls, and giant sequoia trees.",
        latitude: "37.8651",
        longitude: "-119.5383",
        activities: [
            Activity(id: "1", name: "Hiking"),
            Activity(id: "2", name: "Camping"),
            Activity(id: "3", name: "Rock Climbing")
        ],
        directionsInfo: "From CA-41 North, follow signs into the park.",
        weatherInfo: "Summer is warm and dry. Winters bring snow, especially at higher elevations.",
        operatingHours: [
            OperatingHour(description: "Open 24 hours a day, year-round.")
        ],
        entranceFees: [
            EntranceFee(cost: "35.00", title: "Private Vehicle"),
            EntranceFee(cost: "20.00", title: "Individual"),
            EntranceFee(cost: "30.00", title: "Motorcycle")
        ]
    ))
}
