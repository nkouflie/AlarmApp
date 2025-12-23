
import SwiftUI

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmModel.self) private var alarmModel
    
    @State private var userInput = AlarmForm()
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Time Picker Section (Hero Element)
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
                    .padding(.bottom, 120) // Space for bottom button
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Add Alarm")
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
    
    /// Prominent time picker - the hero element of this screen
    private var timePickerSection: some View {
        VStack(spacing: 8) {
            // Label above picker
            Text("Time")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            // Large wheel picker
            DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Name Section
    
    /// Text field for alarm name/label
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
    
    // MARK: - Repeat Section
    
    /// Day-of-week selection for recurring alarms
    /// Only visible when scheduleEnabled is true
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            // Day buttons
            daysOfTheWeekSection
                .padding(.horizontal, 4)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    /// Day-of-week buttons with improved spacing and styling
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
    
    // MARK: - Schedule Toggle Section
    
    /// Toggle for enabling repeating schedule
    /// When enabled, day-of-week buttons appear below with smooth animation
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
    
    // MARK: - Save Button
    
    /// Primary action button anchored at bottom
    private var saveButton: some View {
        Button {
            // Dismiss keyboard first to prevent RTI warnings
            isNameFieldFocused = false
            
            // Small delay to let keyboard animation complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                alarmModel.scheduleAlarm(with: userInput)
                dismiss()
            }
        } label: {
            Text("Set Alarm")
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
    
    /// Returns a short abbreviation for the weekday (S, M, T, W, T, F, S)
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

struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var min: Int
    @Binding var sec: Int
    
    private let labelOffset = 40.0
    
    var body: some View {
        HStack(spacing: 0) {
            pickerRow(title: "hr", range: 0..<24, selection: $hour)
            pickerRow(title: "min", range: 0..<60, selection: $min)
            pickerRow(title: "sec", range: 0..<60, selection: $sec)
        }
    }
    
    func pickerRow(title: String, range: Range<Int>, selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(range, id: \.self) {
                Text("\($0)")
            }
            .background(.clear)
        }
        .pickerStyle(.wheel)
        .tint(.white)
        .overlay {
            Text(title)
                .font(.caption)
                .frame(width: labelOffset, alignment: .leading)
                .offset(x: labelOffset)
        }
    }
}

#Preview {
    AddAlarmView()
}
