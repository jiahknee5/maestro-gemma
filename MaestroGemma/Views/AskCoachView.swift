import SwiftUI

struct AskCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var answer = ""
    @State private var isLoading = false
    @State private var answerSource: RoutingTarget = .onDevice

    private let suggestions = [
        "Why does my bow sound scratchy?",
        "How do I stop my shoulder from going up?",
        "How do I play more in tune?",
        "How do I make my bow go straighter?"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Suggested questions
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Suggested questions")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: { question = suggestion }) {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .accessibilityLabel(suggestion)
                        }
                    }

                    // Text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or ask your own question")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Ask anything about violin technique...", text: $question, axis: .vertical)
                            .lineLimit(3)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityLabel("Question input field")
                    }

                    // Answer
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Maestro is thinking...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if !answer.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill.checkmark")
                                    .foregroundColor(.blue)
                                Text(answerSource == .localServer ? "Maestro (Studio)" : "Maestro (on-device)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(answer)
                                .font(.body)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Coach answer: \(answer)")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ask Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityLabel("Close Ask Coach")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ask") { askQuestion() }
                        .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        .accessibilityLabel("Submit question to coach")
                }
            }
        }
    }

    private func askQuestion() {
        let trimmed = question.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        answer = ""

        Task {
            let (response, source) = await GemmaCoach.shared.analyze(requestType: .askCoach, prompt: trimmed)
            await MainActor.run {
                answer = response
                answerSource = source
                isLoading = false
            }
        }
    }
}
