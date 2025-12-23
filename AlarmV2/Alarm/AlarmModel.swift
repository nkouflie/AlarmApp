
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
        let attributes = AlarmAttributes(presentation: alarmPresentation(with: userInput),
                                         metadata: AlarmData(),
                                         tintColor: Color.accentColor)
        
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
            
            print("🔔 Scheduling alarm:")
            print("   Raw selected date: \(selectedDate)")
            print("   Current time: \(now)")
            print("   Timezone: \(calendar.timeZone.identifier)")
            
            // Get ALL components from selected date in LOCAL timezone
            // This interprets the date picker's time as local time, not UTC
            let selectedComponents = calendar.dateComponents(in: calendar.timeZone, from: selectedDate)
            
            print("   📅 Selected components: year=\(selectedComponents.year ?? -1), month=\(selectedComponents.month ?? -1), day=\(selectedComponents.day ?? -1), hour=\(selectedComponents.hour ?? -1), minute=\(selectedComponents.minute ?? -1)")
            
            // Create target date with today's date but selected time (seconds = 0)
            var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
            targetComponents.hour = selectedComponents.hour
            targetComponents.minute = selectedComponents.minute
            targetComponents.second = 0  // Always set seconds to 0 for precise minute-based alarms
            
            guard var targetDate = calendar.date(from: targetComponents) else {
                print("❌ Failed to create target date")
                return
            }
            
            print("   📍 Target components: year=\(targetComponents.year ?? -1), month=\(targetComponents.month ?? -1), day=\(targetComponents.day ?? -1), hour=\(targetComponents.hour ?? -1), minute=\(targetComponents.minute ?? -1)")
            print("   📍 Created target: \(targetDate)")
            
            // If the time has already passed today, schedule for tomorrow
            if targetDate <= now {
                targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
                print("   ⏭️ Time already passed, scheduling for tomorrow")
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
        
        let alertContent = AlarmPresentation.Alert(title: userInput.localizedLabel,
                                                   stopButton: .stopButton,
                                                   secondaryButton: secondaryButton,
                                                   secondaryButtonBehavior: secondaryButtonBehavior)
        
        // All alarms now use schedule-based configuration (fixed or relative)
        // Only provide alert presentation (no countdown/paused UI)
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
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }
    
    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }
    
    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }
    
    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }
    
    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
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
