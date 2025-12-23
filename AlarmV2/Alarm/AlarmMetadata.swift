
import AlarmKit

struct AlarmData: AlarmMetadata {
    enum Method: String, Codable {
        case reminder
        case workout
        case medication
        case meeting
        case task
        
        var icon: String {
            switch self {
            case .reminder:
                return "bell.fill"
            case .workout:
                return "figure.run"
            case .medication:
                return "cross.case.fill"
            case .meeting:
                return "person.2.fill"
            case .task:
                return "checkmark.circle.fill"
            }
        }
    }
    
    var method: Method?
}
