import SwiftAnthropic

/// Direct Claude API client — bypasses CLI for lower latency
final class ClaudeService: AIServiceProtocol {
    private let service: AnthropicService

    init(apiKey: String) {
        self.service = AnthropicServiceFactory.service(
            apiKey: apiKey,
            betaHeaders: nil
        )
    }

    func analyze(text: String, mode: AnalysisMode, tone: ToneStyle?, sentenceContext: String? = nil, nativeLanguage: String? = nil, targetLanguage: String? = nil) async throws -> AnalysisResult {
        let parameters = buildParameters(text: text, mode: mode, tone: tone, sentenceContext: sentenceContext, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)

        Log.ai.info("Sending \(mode.rawValue) request to Claude (\(mode.usesHaiku ? "Haiku" : "Sonnet"))")
        let response = try await service.createMessage(parameters)

        let responseText = response.content.compactMap { block -> String? in
            if case .text(let text, _) = block { return text }
            return nil
        }.joined()

        return ClaudeResponseParser.parse(response: responseText, mode: mode, originalText: text)
    }

    // MARK: - Private

    private func buildParameters(text: String, mode: AnalysisMode, tone: ToneStyle?, sentenceContext: String?, nativeLanguage: String?, targetLanguage: String?) -> MessageParameter {
        let systemPrompt = ClaudePrompts.systemPrompt(for: mode)
        let userPrompt = ClaudePrompts.userPrompt(for: mode, text: text, tone: tone, sentenceContext: sentenceContext, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)
        let message = MessageParameter.Message(role: .user, content: .text(userPrompt))
        let model: Model = mode.usesHaiku ? .claude35Haiku : .claude37Sonnet
        return MessageParameter(model: model, messages: [message], maxTokens: 2048, system: .text(systemPrompt))
    }
}
