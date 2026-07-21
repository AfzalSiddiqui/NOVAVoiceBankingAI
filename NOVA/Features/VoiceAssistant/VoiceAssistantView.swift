// NOVA Voice Banking AI
// VoiceAssistantView - AI voice banking assistant interface

import SwiftUI

struct VoiceAssistantView: View {
    @StateObject private var viewModel = VoiceAssistantViewModel()
    @State private var textInput = ""
    @State private var showTextField = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Conversation History
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.conversationHistory.isEmpty {
                                welcomeMessage
                            }

                            ForEach(viewModel.conversationHistory) { message in
                                MessageBubble(message: message) { suggestion in
                                    Task {
                                        await viewModel.sendTextCommand(suggestion)
                                    }
                                }
                                .id(message.id)
                            }

                            // Live transcription
                            if !viewModel.transcribedText.isEmpty && viewModel.state == .listening {
                                HStack {
                                    Text(viewModel.transcribedText)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .padding()
                                        .background(Color.blue.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.conversationHistory.count) {
                        if let last = viewModel.conversationHistory.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Bottom Controls
                VStack(spacing: 12) {
                    // Waveform visualization
                    if viewModel.state == .listening {
                        WaveformView(samples: viewModel.waveformSamples)
                            .frame(height: 40)
                            .padding(.horizontal)
                    }

                    // Status indicator
                    statusIndicator

                    // Input area
                    HStack(spacing: 16) {
                        if showTextField {
                            TextField("Type a command...", text: $textInput)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    Task {
                                        await viewModel.sendTextCommand(textInput)
                                        textInput = ""
                                    }
                                }

                            Button {
                                Task {
                                    await viewModel.sendTextCommand(textInput)
                                    textInput = ""
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                            .disabled(textInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        // Microphone button
                        Button {
                            handleMicrophoneTap()
                        } label: {
                            microphoneButton
                        }

                        // Keyboard toggle
                        Button {
                            showTextField.toggle()
                        } label: {
                            Image(systemName: showTextField ? "mic.fill" : "keyboard")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .navigationTitle("NOVA Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.conversationHistory.isEmpty {
                        Button("Clear") {
                            viewModel.clearHistory()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Hi, I'm NOVA")
                .font(.title2.bold())

            Text("Your AI banking assistant. Tap the microphone and ask me anything about your accounts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                suggestionChip("Show my account balance")
                suggestionChip("Transfer 500 AED to Ahmed")
                suggestionChip("How much did I spend on food?")
                suggestionChip("Block my card")
            }
            .padding(.top, 8)
        }
        .padding(32)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            Task { await viewModel.sendTextCommand(text) }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text(text)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
        }
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Text("Tap the microphone to start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .listening:
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Listening...")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
            case .processing:
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .responding:
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                    Text("Speaking...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            case .error(let msg):
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Microphone Button

    private var microphoneButton: some View {
        ZStack {
            Circle()
                .fill(viewModel.state == .listening ? Color.red : Color.blue)
                .frame(width: 56, height: 56)
                .shadow(color: (viewModel.state == .listening ? Color.red : Color.blue).opacity(0.3), radius: 8)

            Image(systemName: viewModel.state == .listening ? "stop.fill" : "mic.fill")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .scaleEffect(viewModel.state == .listening ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
    }

    private func handleMicrophoneTap() {
        switch viewModel.state {
        case .listening:
            viewModel.stopListening()
        case .responding:
            viewModel.stopSpeaking()
        case .idle, .error:
            Task { await viewModel.startListening() }
        default:
            break
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage
    let onSuggestionTap: (String) -> Void

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.role == .user { Spacer() }

                VStack(alignment: .leading, spacing: 8) {
                    Text(message.text)
                        .font(.body)

                    if let intent = message.intent {
                        HStack(spacing: 4) {
                            Image(systemName: intent.icon)
                                .font(.caption2)
                            Text(intent.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(message.role == .user ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if message.role == .assistant { Spacer() }
            }

            // Suggestion chips
            if !message.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(message.suggestions, id: \.self) { suggestion in
                            Button {
                                onSuggestionTap(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let samples: [Float]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3, height: max(2, CGFloat(sample) * 40))
            }
        }
        .animation(.easeOut(duration: 0.1), value: samples)
    }
}
