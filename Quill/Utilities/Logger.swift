import os.log

enum Log {
    private static let subsystem = "com.c3nx.quill"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let accessibility = Logger(subsystem: subsystem, category: "accessibility")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
}
