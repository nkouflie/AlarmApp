/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A list of intents the app uses to manage the alarm state.
*/

import AlarmKit
import AppIntents

enum AlarmIntentError: Error {
    case invalidAlarmID
}

struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        try AlarmManager.shared.pause(id: uuid)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        try AlarmManager.shared.countdown(id: uuid)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        try AlarmManager.shared.resume(id: uuid)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}

struct OpenAlarmAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            throw AlarmIntentError.invalidAlarmID
        }
        try AlarmManager.shared.stop(id: uuid)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Opens the Sample app")
    static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}
