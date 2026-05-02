import SwiftUI
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var headerImageName = Self.randomHeaderImageName()
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.18), Color.white, Color.green.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerCard
                        formCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Account")
            .onAppear {
                headerImageName = Self.randomHeaderImageName()
            }
        }
    }
    private var headerCard: some View {
        ZStack(alignment: .bottomLeading) {
            Image(headerImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 8) {
                Text("National Parks")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Sign in to search parks and keep exploring.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Authentication Mode", selection: $authViewModel.authMode) {
                ForEach(AuthViewModel.AuthMode.allCases) { selectedMode in
                    Text(selectedMode.rawValue).tag(selectedMode)
                }
            }
            .pickerStyle(.segmented)
            VStack(spacing: 14) {
                TextField("Email", text: $authViewModel.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                SecureField("Password", text: $authViewModel.userPassword)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            Button(action: submit) {
                HStack {
                    Spacer()
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(actionTitle)
                            .font(.headline)
                    }
                    Spacer()
                }
                .frame(minHeight: 52)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.7 : 1)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
    private var actionTitle: String {
        authViewModel.authMode == .signIn ? "Log In" : "Create Account"
    }
    private func submit() {
        Task {
            await authViewModel.submit()
        }
    }
    private static func randomHeaderImageName() -> String {
        String(Int.random(in: 1...15))
    }
}
#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
