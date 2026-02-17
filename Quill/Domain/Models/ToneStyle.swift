import Foundation

enum ToneStyle: String, CaseIterable, Identifiable {
    case formal
    case casual
    case professional
    case friendly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .formal: "Formal"
        case .casual: "Casual"
        case .professional: "Professional"
        case .friendly: "Friendly"
        }
    }

    var icon: String {
        switch self {
        case .formal: "building.columns"
        case .casual: "face.smiling"
        case .professional: "briefcase"
        case .friendly: "hand.wave"
        }
    }
}
