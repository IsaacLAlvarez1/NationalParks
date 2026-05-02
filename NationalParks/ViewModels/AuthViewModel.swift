import Foundation
import Combine
import FirebaseAuth
@MainActor
class AuthViewModel: ObservableObject {
    enum AuthMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        var id: Self { self }
    }
    @Published var currentUser: User?
    @Published var errorMessage = ""
    @Published var emailAddress = ""
    @Published var userPassword = ""
    @Published var authMode: AuthMode = .signIn
    @Published var isLoading = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    init() {
        currentUser = Auth.auth().currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }
    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }
    func submit() async {
        errorMessage = ""
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = userPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Enter both an email and password."
            return
        }
        isLoading = true
        defer { isLoading = false }
        switch authMode {
        case .signIn:
            await signIn(email: trimmedEmail, password: trimmedPassword)
        case .signUp:
            await signUp(email: trimmedEmail, password: trimmedPassword)
        }
        if currentUser != nil {
            emailAddress = ""
            userPassword = ""
        }
    }
    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
        } catch {
            errorMessage = userFacingMessage(for: error, mode: .signIn)
        }
    }
    func signUp(email: String, password: String) async {
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = result.user
        } catch {
            errorMessage = userFacingMessage(for: error, mode: .signUp)
        }
    }
    func signOut() {
        errorMessage = ""
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = "Couldn't sign out right now."
        }
    }
    private func userFacingMessage(for error: Error, mode: AuthMode) -> String {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return mode == .signIn ? "Couldn't sign in. Try again." : "Couldn't create your account. Try again."
        }
        switch errorCode {
        case .invalidEmail:
            return "Enter a valid email address."
        case .wrongPassword, .invalidCredential, .userNotFound:
            return "Email or password is incorrect."
        case .emailAlreadyInUse:
            return "That email is already in use."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .networkError:
            return "Check your internet connection and try again."
        default:
            return mode == .signIn ? "Couldn't sign in. Try again." : "Couldn't create your account. Try again."
        }
    }
    var user: User? {
        get { currentUser }
        set { currentUser = newValue }
    }
}
