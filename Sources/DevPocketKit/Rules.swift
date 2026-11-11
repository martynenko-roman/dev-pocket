import Foundation

public enum AwakeDuration: String, CaseIterable, Sendable, Identifiable {
    case minutes15, hour1, hours2, indefinitely
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .minutes15: "15 minutes"
        case .hour1: "1 hour"
        case .hours2: "2 hours"
        case .indefinitely: "Until turned off"
        }
    }
    public var seconds: TimeInterval? {
        switch self {
        case .minutes15: 900
        case .hour1: 3600
        case .hours2: 7200
        case .indefinitely: nil
        }
    }
}

public enum Rules {
    public static func clock(_ interval: TimeInterval) -> String {
        guard interval.isFinite else { return "0:00" }
        let total = Int(min(max(interval.rounded(.up), 0), Double(Int32.max)))
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    public static func preferenceBool(_ value: Any?, fallback: Bool) -> Bool {
        switch value {
        case let number as NSNumber: number.boolValue
        case let text as String: ["1", "yes", "true"].contains(text.lowercased())
        default: fallback
        }
    }

    public static func shouldReverseScroll(phase: Int64, momentum: Int64, continuous: Int64) -> Bool {
        phase == 0 && momentum == 0 && continuous == 0
    }
}
