import AppKit

protocol TextCaptureProtocol {
    func getSelectedText() async -> String?
    func replaceSelectedText(with text: String, in sourceApp: NSRunningApplication?) async -> Bool
    func checkPermission() -> Bool
    func requestPermission()
}
