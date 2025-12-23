
import SwiftUI
import AlarmKit

struct AlarmCell: View {
    var alarm: Alarm
    var label: LocalizedStringResource
    
    @Environment(AlarmModel.self) private var alarmModel
    @State private var isEnabled: Bool = true
    @State private var showEditSheet = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side: Time and label
            VStack(alignment: .leading, spacing: 6) {
                // Time display - most prominent element
                timeView
                
                // Label - secondary element
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                // Weekly schedule summary - only for repeating alarms
                if let scheduleSummary = weeklyScheduleSummary {
                    Text(scheduleSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Status indicator - subtle
                if alarm.state != .scheduled {
                    statusBadge
                }
            }
            
            Spacer(minLength: 12)
            
            // Right side: Edit button and state indicator
            HStack(spacing: 12) {
                // Edit button - subtle pencil icon
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit alarm")
                
                // State indicator
                stateIndicator
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .sheet(isPresented: $showEditSheet) {
            EditAlarmView(alarm: alarm, label: label)
        }
    }
    
    // MARK: - Time View
    
    /// Large, prominent time display using SF Rounded
    @ViewBuilder
    private var timeView: some View {
        if let alertingTime = alarm.alertingTime {
            // For scheduled alarms, show the time
            Text(alertingTime, style: .time)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .foregroundStyle(isAlarmActive ? .primary : .secondary)
                .monospacedDigit()
        } else if let countdown = alarm.countdownDuration?.preAlert {
            // For countdown alarms, show duration
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(countdown.customFormatted())
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .foregroundStyle(isAlarmActive ? .primary : .secondary)
                
                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            // Fallback
            Text("--:--")
                .font(.system(size: 52, weight: .light, design: .rounded))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }
    
    // MARK: - Status Badge
    
    /// Small badge showing alarm state (Running, Paused, Alerting)
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }
    
    // MARK: - State Indicator
    
    /// Right side visual indicator (could be toggle or just status)
    private var stateIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isAlarmActive: Bool {
        alarm.state == .countdown || alarm.state == .alerting
    }
    
    /// Returns a formatted summary of weekly schedule (e.g., "Mon, Wed, Fri" or "Weekdays")
    private var weeklyScheduleSummary: String? {
        guard let schedule = alarm.schedule else { return nil }
        
        // Only show summary for relative schedules with weekly repeats
        switch schedule {
        case .relative(let relative):
            switch relative.repeats {
            case .weekly(let weekdays):
                guard !weekdays.isEmpty else { return nil }
                return formatWeekdays(weekdays)
            case .never:
                return nil
            @unknown default:
                return nil
            }
        case .fixed:
            return nil
        @unknown default:
            return nil
        }
    }
    
    /// Formats an array of weekdays into a readable string
    /// Returns shorthand like "Weekdays", "Weekends", or "Mon, Tue, Wed"
    private func formatWeekdays(_ weekdays: [Locale.Weekday]) -> String {
        let sortedDays = weekdays.sorted { day1, day2 in
            let locale = Locale.autoupdatingCurrent
            let orderedWeekdays = locale.orderedWeekdays
            let index1 = orderedWeekdays.firstIndex(of: day1) ?? 0
            let index2 = orderedWeekdays.firstIndex(of: day2) ?? 0
            return index1 < index2
        }
        
        // Check for common patterns
        let weekdaySet = Set(weekdays)
        let allWeekdays: Set<Locale.Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let allWeekendDays: Set<Locale.Weekday> = [.saturday, .sunday]
        let allDays: Set<Locale.Weekday> = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        
        if weekdaySet == allDays {
            return "Every day"
        } else if weekdaySet == allWeekdays {
            return "Weekdays"
        } else if weekdaySet == allWeekendDays {
            return "Weekends"
        } else {
            // Format as "Mon, Tue, Wed"
            return sortedDays.map { weekdayAbbreviation($0) }.joined(separator: ", ")
        }
    }
    
    /// Returns 3-letter abbreviation for a weekday
    private func weekdayAbbreviation(_ weekday: Locale.Weekday) -> String {
        switch weekday {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    private var statusText: String {
        switch alarm.state {
        case .scheduled: return "Scheduled"
        case .countdown: return "Running"
        case .paused: return "Paused"
        case .alerting: return "Alerting"
        @unknown default: return "Unknown"
        }
    }
    
    private var statusIcon: String {
        switch alarm.state {
        case .scheduled: return "clock.fill"
        case .countdown: return "timer"
        case .paused: return "pause.circle.fill"
        case .alerting: return "bell.circle.fill"
        @unknown default: return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch alarm.state {
        case .scheduled: return .blue
        case .countdown: return .green
        case .paused: return .orange
        case .alerting: return .red
        @unknown default: return .gray
        }
    }
}
// MARK: - Preview

#Preview("Alarm Cell") {
    // Note: AlarmKit Alarm objects can only be created by AlarmManager
    // These previews require actual alarms to be scheduled
    // For now, showing the UI structure without live data
    
    List {
        // Placeholder view showing the expected layout
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("7:00")
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                
                Text("Wake Up")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            Spacer(minLength: 12)
            
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color(uiColor: .systemGroupedBackground))
}


// MARK: - Edit Alarm View
/// Wrapper view for editing existing alarms
/// Reuses AddAlarmView with pre-populated alarm data
struct EditAlarmView: View {
    let alarm: Alarm
    let label: LocalizedStringResource
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmModel.self) private var alarmModel
    
    @State private var userInput: AlarmForm
    @FocusState private var isNameFieldFocused: Bool  // Add focus state
    
    init(alarm: Alarm, label: LocalizedStringResource) {
        self.alarm = alarm
        self.label = label
        
        // Pre-populate form with existing alarm data
        var form = AlarmForm()
        
        // Set label
        form.label = String(localized: label)
        
        // Set time from alarm schedule
        if let schedule = alarm.schedule {
            switch schedule {
            case .fixed(let date):
                form.selectedDate = date
                form.scheduleEnabled = false
            case .relative(let relative):
                // Create a date from hour and minute
                var components = DateComponents()
                components.hour = relative.time.hour
                components.minute = relative.time.minute
                if let date = Calendar.current.date(from: components) {
                    form.selectedDate = date
                }
                
                // Set schedule enabled and days
                form.scheduleEnabled = true
                switch relative.repeats {
                case .weekly(let weekdays):
                    form.selectedDays = Set(weekdays)
                case .never:
                    form.scheduleEnabled = false
                @unknown default:
                    break
                }
            @unknown default:
                break
            }
        }
        
        _userInput = State(initialValue: form)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Time Picker Section
                    timePickerSection
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    
                    // MARK: - Configuration Sections
                    VStack(spacing: 16) {
                        nameSection
                        scheduleToggleSection
                        
                        if userInput.scheduleEnabled {
                            repeatSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Dismiss keyboard before closing sheet to prevent warnings
                        isNameFieldFocused = false
                        // Small delay to let keyboard dismiss cleanly
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
        }
    }
    
    // MARK: - Time Picker Section
    
    private var timePickerSection: some View {
        VStack(spacing: 8) {
            Text("Time")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                TextField("Alarm name", text: $userInput.label)
                    .font(.body)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Schedule Toggle Section
    
    private var scheduleToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                Text("Repeat Weekly")
                    .font(.body)
                
                Spacer()
                
                Toggle("", isOn: $userInput.scheduleEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            
            if !userInput.scheduleEnabled {
                Text("One-time alarm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userInput.scheduleEnabled)
    }
    
    // MARK: - Repeat Section
    
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            daysOfTheWeekSection
                .padding(.horizontal, 4)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var daysOfTheWeekSection: some View {
        HStack(spacing: 8) {
            ForEach(Locale.autoupdatingCurrent.orderedWeekdays, id: \.self) { weekday in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if userInput.isSelected(day: weekday) {
                            userInput.selectedDays.remove(weekday)
                        } else {
                            userInput.selectedDays.insert(weekday)
                        }
                    }
                } label: {
                    Text(weekdayAbbreviation(weekday))
                        .font(.system(size: 15, weight: userInput.isSelected(day: weekday) ? .semibold : .regular))
                        .foregroundStyle(userInput.isSelected(day: weekday) ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(userInput.isSelected(day: weekday) ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            // Dismiss keyboard first to prevent RTI warnings
            isNameFieldFocused = false
            
            // Small delay to let keyboard animation complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Delete old alarm
                alarmModel.unscheduleAlarm(with: alarm.id)
                
                // Schedule updated alarm
                alarmModel.scheduleAlarm(with: userInput)
                
                dismiss()
            }
        } label: {
            Text("Save Changes")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
                .foregroundStyle(.white)
        }
        .disabled(!userInput.isValidAlarm)
        .opacity(userInput.isValidAlarm ? 1.0 : 0.5)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    
    private func weekdayAbbreviation(_ weekday: Locale.Weekday) -> String {
        switch weekday {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

