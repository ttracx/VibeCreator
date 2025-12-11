// LoginView.swift
// VibeCreator - Authentication views

import SwiftUI
import VibeCreatorKit

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geometry.size.height * 0.1)

                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.accent)

                        Text("VibeCreator")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Social Media Management")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 40)

                    // Login/Register Form
                    VStack(spacing: 20) {
                        if viewModel.isRegistering {
                            TextField("Name", text: $viewModel.name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                #if os(iOS)
                                .autocapitalization(.words)
                                #endif
                        }

                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            #endif

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(viewModel.isRegistering ? .newPassword : .password)

                        if viewModel.isRegistering {
                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: viewModel.submit) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                                Text(viewModel.isRegistering ? "Create Account" : "Sign In")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading || !viewModel.isValid)

                        Button(action: { withAnimation { viewModel.toggleMode() } }) {
                            Text(viewModel.isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.accent)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 400)

                    Spacer(minLength: geometry.size.height * 0.1)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Login View Model

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var isRegistering = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isValid: Bool {
        if isRegistering {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
        }
        return !email.isEmpty && !password.isEmpty
    }

    func toggleMode() {
        isRegistering.toggle()
        errorMessage = nil
    }

    func submit() {
        Task {
            await isRegistering ? register() : login()
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            AuthManager.shared.saveAuthResponse(response)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }

    private func register() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.register(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: confirmPassword
            )
            AuthManager.shared.saveAuthResponse(response)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
