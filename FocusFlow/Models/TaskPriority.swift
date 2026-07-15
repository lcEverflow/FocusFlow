import SwiftUI

enum TaskPriority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case high = 0
    case medium = 1
    case low = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .high: "高"
        case .medium: "中"
        case .low: "低"
        }
    }

    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .low: .green
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}
