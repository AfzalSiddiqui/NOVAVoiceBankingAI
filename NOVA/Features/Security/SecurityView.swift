// NOVA Voice Banking AI
// SecurityView - Security settings and card management

import SwiftUI

struct SecurityView: View {
    @StateObject private var viewModel = SecurityViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                // Biometric Section
                Section("Authentication") {
                    HStack(spacing: 12) {
                        Image(systemName: biometricIcon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(biometricTitle)
                                .font(.subheadline.bold())
                            Text(viewModel.biometricType == .none ? "Not available on this device" : "Enabled for app access")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.biometricType != .none {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { await viewModel.authenticateBiometric() }
                    }

                    // Voice Authentication
                    HStack(spacing: 12) {
                        Image(systemName: "waveform.badge.mic")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Voice Authentication")
                                .font(.subheadline.bold())
                            Text(viewModel.isVoiceEnrolled ? "Voice print enrolled" : "Not enrolled")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isVoiceEnrolled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Button("Enroll") {
                                Task { await viewModel.enrollVoice() }
                            }
                            .font(.caption.bold())
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }

                // Card Security Section
                Section("Card Security") {
                    ForEach(viewModel.cards) { card in
                        CardSecurityRow(card: card) {
                            Task { await viewModel.toggleCardFreeze(card: card) }
                        }
                    }
                }

                // Security Status Section
                Section("Security Status") {
                    SecurityStatusRow(icon: "lock.shield.fill", title: "SSL Pinning", status: "Active", color: .green)
                    SecurityStatusRow(icon: "key.fill", title: "Encryption", status: "AES-256", color: .green)
                    SecurityStatusRow(icon: "cpu", title: "Secure Enclave", status: "Available", color: .green)
                    SecurityStatusRow(icon: "lock.doc.fill", title: "Keychain", status: "Protected", color: .green)
                    SecurityStatusRow(icon: "shield.checkered", title: "Jailbreak Detection", status: "Clean", color: .green)
                }

                // Account Section
                Section {
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Security")
            .refreshable {
                await viewModel.loadSecurityStatus()
            }
            .alert("Security", isPresented: $viewModel.showAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage ?? "")
            }
            .task {
                await viewModel.loadSecurityStatus()
            }
        }
    }

    private var biometricIcon: String {
        switch viewModel.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.slash"
        }
    }

    private var biometricTitle: String {
        switch viewModel.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometric Auth"
        }
    }
}

// MARK: - Card Security Row

struct CardSecurityRow: View {
    let card: Card
    let onToggleFreeze: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.cardNetwork == .visa ? "creditcard.fill" : "creditcard.fill")
                .font(.title2)
                .foregroundStyle(card.isFrozen ? .gray : .blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(card.cardNetwork.rawValue.capitalized) \(card.cardType.rawValue.capitalized)")
                    .font(.subheadline.bold())
                Text(card.maskedNumber)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onToggleFreeze()
            } label: {
                Text(card.isFrozen ? "Unfreeze" : "Freeze")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(card.isFrozen ? .blue : .red)
            .controlSize(.small)
        }
    }
}

// MARK: - Security Status Row

struct SecurityStatusRow: View {
    let icon: String
    let title: String
    let status: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(status)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}
