import SwiftUI
import FirebaseCore
private enum FirebaseConfiguration {
    static func configure() {
        if FirebaseApp.app() == nil {
            guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let options = FirebaseOptions(contentsOfFile: filePath) else {
                fatalError("Missing Firebase configuration file: GoogleService-Info.plist")
            }
            FirebaseApp.configure(options: options)
        }
    }
}
@main
struct NationalParksApp: App {
    @StateObject private var parks: NationalParksViewModel
    @StateObject private var authViewModel: AuthViewModel
    @State private var hasSeenIntro = false
    init() {
        FirebaseConfiguration.configure()
        _parks = StateObject(wrappedValue: NationalParksViewModel())
        _authViewModel = StateObject(wrappedValue: AuthViewModel())
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenIntro {
                    if authViewModel.currentUser == nil {
                        AuthView()
                    } else {
                        ContentView()
                    }
                } else {
                    IntroView {
                        hasSeenIntro = true
                    }
                }
            }
            .environmentObject(parks)
            .environmentObject(authViewModel)
        }
    }
}
