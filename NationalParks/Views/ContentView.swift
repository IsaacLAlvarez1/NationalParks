import SwiftUI
import MapKit
import CoreLocation
import Combine
import FirebaseAuth
struct ContentView: View {
    private enum ScreenTab: String, CaseIterable, Identifiable {
        case nearby = "Nearby Parks"
        case favorites = "Favorite Parks"
        var id: String { rawValue }
    }
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var parksVM: NationalParksViewModel
    @StateObject private var locMgr = LocationManager()
    @State private var camPos: MapCameraPosition = .automatic
    @State private var tab: ScreenTab = .nearby
    private var nearby: [NearbyPark] {
        guard let userLoc = locMgr.location else { return [] }
        return parksVM.parks.compactMap { park in
            guard let coordinate = park.coordinate else { return nil }
            let parkLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let dist = userLoc.distance(from: parkLoc)
            return NearbyPark(park: park, distance: dist)
        }
        .sorted { $0.distance < $1.distance }
    }
    private var closeParks: [NearbyPark] {
        Array(nearby.prefix(25))
    }
    private var favIDs: Set<String> {
        Set(parksVM.favParks.parks)
    }
    private var favParks: [ParkModel] {
        parksVM.parks.filter { favIDs.contains($0.id) }
            .sorted { $0.fullName < $1.fullName }
    }
    private var locDenied: Bool {
        locMgr.authStatus == .denied || locMgr.authStatus == .restricted
    }
    private var isLoading: Bool {
        parksVM.isLoading && parksVM.parks.isEmpty
    }
    private var nearReady: Bool {
        locMgr.location != nil && !closeParks.isEmpty
    }
    private var nearHdr: String {
        if locDenied {
            return "Turn on location to find nearby parks."
        }
        if locMgr.errMsg != nil {
            return "Couldn't get your location yet."
        }
        if isLoading {
            return "Using your location to find nearby parks."
        }
        if locMgr.location == nil {
            return "Using your location to find nearby parks."
        }
        if let park = closeParks.first {
            return "\(park.park.fullName) is closest right now."
        }
        return "Using your location to find nearby parks."
    }
    private var nearMapMsg: String {
        if locDenied {
            return "Location is off. Turn it on in Settings."
        }
        if let err = locMgr.errMsg {
            return err
        }
        if locMgr.location == nil {
            return "Finding location..."
        }
        return "No nearby parks right now."
    }
    private var nearListMsg: String {
        if locDenied {
            return "Allow location to see nearby parks."
        }
        if let err = locMgr.errMsg {
            return err
        }
        if locMgr.location == nil {
            return "Need your location to sort by distance."
        }
        return "No nearby parks right now."
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    tabPicker
                    if tab == .nearby {
                        header
                        mapCard
                        nearbySection
                    } else {
                        favoritesSection
                    }
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("National Parks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authVM.signOut()
                    }
                }
            }
            .task {
                locMgr.requestLocationAccess()
                await parksVM.fetchAllParks()
                await syncFavs()
                updateCam()
            }
            .onChange(of: authVM.user?.uid) { _, userID in
                Task {
                    await syncFavs(for: userID)
                }
            }
            .onChange(of: locMgr.location) { _, _ in
                updateCam()
            }
            .onChange(of: parksVM.parks.count) { _, _ in
                updateCam()
            }
            .alert(isPresented: $parksVM.hasError, error: parksVM.err) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.08), Color.white, Color.green.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    private var tabPicker: some View {
        Picker("Parks View", selection: $tab) {
            ForEach(ScreenTab.allCases) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parks near you")
                .font(.largeTitle.bold())
            Text(nearHdr)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    private var mapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
            if isLoading {
                ProgressView("Loading parks")
            } else if nearReady {
                Map(position: $camPos) {
                    UserAnnotation()
                    ForEach(closeParks) { park in
                        Marker(park.park.fullName, coordinate: park.park.coordinate ?? .init())
                    }
                }
            } else {
                messageView(nearMapMsg)
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Closest parks")
                .font(.title2.bold())
            if isLoading {
                ProgressView("Loading nearby parks")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if nearReady {
                ForEach(closeParks) { park in
                    parkRow(for: park.park, subtitle: distanceText(for: park.distance))
                }
            } else {
                Text(nearListMsg)
                    .foregroundStyle(.secondary)
            }
        }
    }
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Favorite parks")
                .font(.title2.bold())
            if parksVM.isLoading && parksVM.parks.isEmpty {
                ProgressView("Loading parks")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if favParks.isEmpty {
                Text("Save parks from Nearby Parks to see them here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favParks) { park in
                    parkRow(for: park, subtitle: park.states)
                }
            }
        }
    }
    private func parkRow(for park: ParkModel, subtitle: String) -> some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ParkDetailView(park: park)) {
                HStack(spacing: 14) {
                    thumbnail(for: park)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(park.fullName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text(park.states)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            Button {
                toggleFavorite(for: park.id)
            } label: {
                Image(systemName: favIDs.contains(park.id) ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .buttonStyle(.plain)
    }
    @ViewBuilder
    private func thumbnail(for park: ParkModel) -> some View {
        if let imgURL = URL(string: park.images.first?.url ?? "") {
            AsyncImage(url: imgURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 84, height: 84)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                case .failure:
                    Color.gray.opacity(0.15)
                        .frame(width: 84, height: 84)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Color.gray.opacity(0.15)
                .frame(width: 84, height: 84)
                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    private func messageView(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
    }
    private func distanceText(for distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        return "\(Int(miles.rounded())) miles away"
    }
    private func toggleFavorite(for parkID: String) {
        guard let userID = authVM.user?.uid else {
            return
        }
        Task {
            await parksVM.toggleFavPark(parkID, for: userID)
        }
    }
    private func syncFavs(for userID: String? = nil) async {
        guard let userID = userID ?? authVM.user?.uid else {
            await MainActor.run {
                parksVM.clearFavParks()
            }
            return
        }

        await parksVM.loadFavParks(for: userID)
    }
    private func updateCam() {
        guard let userCoord = locMgr.location?.coordinate else { return }
        let parkCoords = closeParks.prefix(3).compactMap { $0.park.coordinate }
        let coords = [userCoord] + parkCoords
        guard let region = regionThatFits(coordinates: coords) else { return }
        camPos = .region(region)
    }
    private func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let firstCoord = coordinates.first else { return nil }
        var minLat = firstCoord.latitude
        var maxLat = firstCoord.latitude
        var minLong = firstCoord.longitude
        var maxLong = firstCoord.longitude
        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLong = min(minLong, coordinate.longitude)
            maxLong = max(maxLong, coordinate.longitude)
        }
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.35),
            longitudeDelta: max((maxLong - minLong) * 1.6, 0.35)
        )
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLong + maxLong) / 2
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
private struct NearbyPark: Identifiable {
    let park: ParkModel
    let distance: CLLocationDistance
    var id: String { park.id }
}
private final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authStatus: CLAuthorizationStatus
    @Published var errMsg: String?
    private let mgr = CLLocationManager()
    private var wantsLoc = false
    override init() {
        authStatus = .notDetermined
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    func requestLocationAccess() {
        wantsLoc = true
        handleAuthorizationStatus(authStatus)
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        handleAuthorizationStatus(authStatus)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        errMsg = nil
        manager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        errMsg = "Can't get your location right now."
        print("Location error: \(error.localizedDescription)")
    }
    private func startLocationUpdates() {
        mgr.startUpdatingLocation()
        mgr.requestLocation()
    }
    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            wantsLoc = false
            errMsg = nil
            startLocationUpdates()
        case .denied:
            wantsLoc = false
            errMsg = "Location denied. Turn it on in Settings."
        case .restricted:
            wantsLoc = false
            errMsg = "Location is restricted on this device."
        case .notDetermined:
            guard wantsLoc else { break }
            mgr.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
private extension ParkModel {
    var coordinate: CLLocationCoordinate2D? {
        guard
            let latitude,
            let longitude,
            let lat = Double(latitude),
            let long = Double(longitude)
        else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
}
#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(NationalParksViewModel())
}
