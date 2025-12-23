
import AlarmKit
import SwiftUI
import AppIntents

@Observable class AlarmModel {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<AlarmData>
    typealias AlarmsMap = [UUID: (Alarm, LocalizedStringResource)]
    
    @MainActor var alarmsMap = AlarmsMap()
    @ObservationIgnored private var alarmManager: AlarmManager {
        AlarmManager.shared
    }
    
    @MainActor var hasAlarms: Bool {
        !alarmsMap.isEmpty
    }
    
    init() {
        Task {
            do {
                try await Task.sleep(for: .milliseconds(100))
                observeAlarms()
            } catch {
                print("Error in init: \(error)")
            }
        }
    }
    
    func fetchAlarms() {
        do {
            let remoteAlarms = try alarmManager.alarms
            updateAlarmState(with: remoteAlarms)
        } catch {
            print("Error fetching alarms: \(error)")
        }
    }
    
    func scheduleAlarm(with userInput: AlarmForm) {
        // Professional alarm presentation with optimal banner configuration
        let attributes = AlarmAttributes(
            presentation: alarmPresentation(with: userInput),
            metadata: AlarmData(),
            tintColor: .orange  // Warm, attention-getting but not aggressive
        )
        
        let id = UUID()
        
        // Create configuration based on whether schedule is enabled
        let alarmConfiguration: AlarmConfiguration
        if let schedule = userInput.schedule {
            // Schedule-based alarm
            alarmConfiguration = AlarmConfiguration(
                schedule: schedule,
                attributes: attributes,
                stopIntent: StopIntent(alarmID: id.uuidString),
                secondaryIntent: secondaryIntent(alarmID: id, userInput: userInput)
            )
        } else {
            // Fixed schedule alarm for precise timing
            let selectedDate = userInput.selectedDate
            let now = Date.now
            let calendar = Calendar.current
            
            // Extract time components from selected date (IGNORE seconds)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDate)
            
            // Create target date with today's date but selected time (seconds = 0)
            var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
            targetComponents.hour = timeComponents.hour
            targetComponents.minute = timeComponents.minute
            targetComponents.second = 0  // Always set seconds to 0 for precise minute-based alarms
            targetComponents.timeZone = calendar.timeZone  // Ensure we use local timezone
            
            guard var targetDate = calendar.date(from: targetComponents) else {
                return
            }
            
            // If the time has already passed today, schedule for tomorrow
            if targetDate <= now {
                targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            }
            
            print("   🎯 Final target date: \(targetDate)")
            print("   ⏱️ Will fire in: \(targetDate.timeIntervalSince(now)) seconds")
            
            // Use fixed date schedule
            let fixedSchedule = Alarm.Schedule.fixed(targetDate)
            
            alarmConfiguration = AlarmConfiguration(
                schedule: fixedSchedule,
                attributes: attributes,
                stopIntent: StopIntent(alarmID: id.uuidString),
                secondaryIntent: secondaryIntent(alarmID: id, userInput: userInput)
            )
        }
        
        scheduleAlarm(id: id, label: userInput.localizedLabel, alarmConfiguration: alarmConfiguration)
    }
    
    func scheduleAlarm(id: UUID, label: LocalizedStringResource, alarmConfiguration: AlarmConfiguration) {
        Task {
            do {
                guard await requestAuthorization() else {
                    print("Not authorized to schedule alarms.")
                    return
                }
                let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
                await MainActor.run {
                    alarmsMap[id] = (alarm, label)
                }
            } catch {
                print("Error encountered when scheduling alarm: \(error)")
            }
        }
    }
    
    func unscheduleAlarm(with alarmID: UUID) {
        try? alarmManager.cancel(id: alarmID)
        Task { @MainActor in
            alarmsMap[alarmID] = nil
        }
    }
    
    private func alarmPresentation(with userInput: AlarmForm) -> AlarmPresentation {
        let secondaryButtonBehavior = userInput.secondaryButtonBehavior
        let secondaryButton: AlarmButton? = switch secondaryButtonBehavior {
            case .countdown: .repeatButton
            case .custom: .openAppButton
            default: nil
        }
        
        // Professional banner content optimized for system Live Activity presentation
        // Title, buttons, and icons are carefully chosen for clarity and polish
        let alertContent = AlarmPresentation.Alert(
            title: userInput.localizedLabel,      // Clean alarm name
            stopButton: .stopButton,              // Primary dismiss action
            secondaryButton: secondaryButton,     // Optional secondary action (Snooze/Open)
            secondaryButtonBehavior: secondaryButtonBehavior
        )
        
        // System will display this in:
        // - Dynamic Island (iPhone 14 Pro+)
        // - Lock Screen banner
        // - Top notification banner
        return AlarmPresentation(alert: alertContent)
    }
    
    private func secondaryIntent(alarmID: UUID, userInput: AlarmForm) -> (any LiveActivityIntent)? {
        guard let behavior = userInput.secondaryButtonBehavior else { return nil }
        
        switch behavior {
        case .countdown:
            return RepeatIntent(alarmID: alarmID.uuidString)
        case .custom:
            return OpenAlarmAppIntent(alarmID: alarmID.uuidString)
        @unknown default:
            return nil
        }
    }
    
    private func observeAlarms() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                updateAlarmState(with: incomingAlarms)
            }
        }
    }
    
    private func updateAlarmState(with remoteAlarms: [Alarm]) {
        Task { @MainActor in
            
            // Update existing alarm states.
            remoteAlarms.forEach { updated in
                alarmsMap[updated.id, default: (updated, "Alarm (Old Session)")].0 = updated
            }
            
            let knownAlarmIDs = Set(alarmsMap.keys)
            let incomingAlarmIDs = Set(remoteAlarms.map(\.id))
            
            // Clean-up removed alarms.
            let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
            removedAlarmIDs.forEach {
                alarmsMap[$0] = nil
            }
        }
    }
    
    private func requestAuthorization() async -> Bool {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                return state == .authorized
            } catch {
                print("Error occurred while requesting authorization: \(error)")
                return false
            }
        case .denied: return false
        case .authorized: return true
        @unknown default: return false
        }
    }
}

extension AlarmButton {
    // MARK: - Professional Alarm Banner Button Configurations
    // These buttons appear in the system Live Activity banner when alarms alert
    // Icons and text are optimized for clarity, professionalism, and iOS consistency
    
    /// Secondary action - Opens the app when tapped
    static var openAppButton: Self {
        AlarmButton(
            text: "Open",
            textColor: .black,
            systemImageName: "app.badge"
        )
    }
    
    /// Countdown control - Pauses active timer
    static var pauseButton: Self {
        AlarmButton(
            text: "Pause",
            textColor: .black,
            systemImageName: "pause.fill"
        )
    }
    
    /// Countdown control - Resumes paused timer
    static var resumeButton: Self {
        AlarmButton(
            text: "Resume",
            textColor: .black,
            systemImageName: "play.fill"
        )
    }
    
    /// Secondary action - Snoozes alarm for later
    static var repeatButton: Self {
        AlarmButton(
            text: "Snooze",
            textColor: .black,
            systemImageName: "clock.badge"
        )
    }
    
    /// Primary action - Dismisses alarm immediately
    /// White text on orange tint creates strong visual priority
    static var stopButton: Self {
        AlarmButton(
            text: "OK",
            textColor: .white,
            systemImageName: "checkmark.circle.fill"
        )
    }
}

extension Alarm {
    var alertingTime: Date? {
        guard let schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
        }
    }
}

extension Alarm.Schedule {
    static var twoMinsFromNow: Self {
        let twoMinsFromNow = Date.now.addingTimeInterval(2 * 60)
        let time = Alarm.Schedule.Relative.Time(hour: Calendar.current.component(.hour, from: twoMinsFromNow),
                                                minute: Calendar.current.component(.minute, from: twoMinsFromNow))
        return .relative(.init(time: time))
    }
}

extension TimeInterval {
    func customFormatted() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? self.formatted()
    }
}

extension Locale {
    var orderedWeekdays: [Locale.Weekday] {
        let days: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        if let firstDayIdx = days.firstIndex(of: firstDayOfWeek), firstDayIdx != 0 {
            return Array(days[firstDayIdx...] + days[0..<firstDayIdx])
        }
        return days
    }
}
