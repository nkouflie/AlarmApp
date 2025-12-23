
import AlarmKit

struct AlarmForm {
    
    // Default alarm name is "Alarm" - user can edit immediately
    var label = "Alarm"
    
    var selectedDate = Date.now
    var selectedDays = Set<Locale.Weekday>()
    
    var selectedSecondaryButton: SecondaryButtonOption = .none
    
    var scheduleEnabled = false
    
    var isValidAlarm: Bool {
        !label.isEmpty
    }
    
    var localizedLabel: LocalizedStringResource {
        label.isEmpty ? LocalizedStringResource("Alarm") : LocalizedStringResource(stringLiteral: label)
    }
    
    func isSelected(day: Locale.Weekday) -> Bool {
        selectedDays.contains(day)
    }
    
    enum SecondaryButtonOption: String, CaseIterable {
        case none = "None"
        case countdown = "Countdown"
        case openApp = "Open App"
    }
    
    var schedule: Alarm.Schedule? {
        guard scheduleEnabled else { return nil }
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return nil }
        
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        return .relative(.init(
            time: time,
            repeats: selectedDays.isEmpty ? .never : .weekly(Array(selectedDays))
        ))
    }
    
    var secondaryButtonBehavior: AlarmPresentation.Alert.SecondaryButtonBehavior? {
        switch selectedSecondaryButton {
        case .none: nil
        case .countdown: .countdown
        case .openApp: .custom
        }
    }
    
}
