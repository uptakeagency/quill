import Foundation

protocol TextCaptureProtocol {
    func getSelectedText() async -> String?
    func replaceSelectedText(with text: String) async -> Bool
    func checkPermission() -> Bool
    func requestPermission()
}
