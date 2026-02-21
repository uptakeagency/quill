import Foundation

/// AI service that uses the locally installed `claude` CLI instead of the API directly.
/// No API key needed - uses the existing Claude Code authentication.
final class ClaudeCLIService: AIServiceProtocol {
    private let claudePath: String

    init(claudePath: String = ClaudeCLIService.defaultPath) {
        self.claudePath = claudePath
    }

    private static let defaultPath: String = {
        let home = NSHomeDirectory()
        let candidates = [
            "\(home)/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude"
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? "\(home)/.local/bin/claude"
    }()

    func analyze(text: String, mode: AnalysisMode, tone: ToneStyle?, sentenceContext: String? = nil, nativeLanguage: String? = nil, targetLanguage: String? = nil, explanationLevel: ExplanationLevel? = nil) async throws -> AnalysisResult {
        let systemPrompt = ClaudePrompts.systemPrompt(for: mode, explanationLevel: explanationLevel)
        let userPrompt = ClaudePrompts.userPrompt(for: mode, text: text, tone: tone, sentenceContext: sentenceContext, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)
        let fullPrompt = "\(systemPrompt)\n\n\(userPrompt)"

        Log.ai.info("Sending \(mode.rawValue) request via claude CLI")

        let output = try await runClaude(prompt: fullPrompt, model: modelForMode(mode))
        return ClaudeResponseParser.parse(response: output, mode: mode, originalText: text)
    }

    // MARK: - Private

    private func runClaude(prompt: String, model: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = [
            "-p",
            "--output-format", "json",
            "--model", model,
            prompt
        ]

        // Clean environment to avoid nesting issues
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "CLAUDECODE")
        env.removeValue(forKey: "CLAUDE_CODE_ENTRYPOINT")
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: "/tmp")

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                let data = stdout.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown CLI error"
                    continuation.resume(throwing: QuillError.networkError("claude CLI: \(errorMsg)"))
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let result = json["result"] as? String else {
                    // Fallback: treat entire output as text
                    let raw = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: raw)
                    return
                }

                continuation.resume(returning: result)
            }
        }
    }

    private func modelForMode(_ mode: AnalysisMode) -> String {
        mode.usesHaiku ? "claude-haiku-4-5-20251001" : "claude-sonnet-4-5-20250929"
    }
}
