import Foundation

protocol AIServiceProtocol {
    func analyze(text: String, mode: AnalysisMode, tone: ToneStyle?, sentenceContext: String?, nativeLanguage: String?, targetLanguage: String?) async throws -> AnalysisResult
}
