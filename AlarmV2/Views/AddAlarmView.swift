
import SwiftUI

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlarmModel.self) private var alarmModel
    
    @State private var userInput = AlarmForm()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack (spacing: 16) {
                    textfield
                    timePicker
                    scheduleSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
        }
    }
    
    var textfield: some View {
        Label(title: {
            TextField("Name your alarm", text: $userInput.label)
        }, icon: {
            Image(systemName: "character.cursor.ibeam")
        })
    }
    
    var timePicker: some View {
        DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
    }
    
    var scheduleSection: some View {
        VStack {
            Toggle("Schedule", systemImage: "calendar", isOn: $userInput.scheduleEnabled)
            if userInput.scheduleEnabled {
                daysOfTheWeekSection
            }
        }
    }
    
    var daysOfTheWeekSection: some View {
        HStack(spacing: -3) {
            ForEach(Locale.autoupdatingCurrent.orderedWeekdays, id: \.self) { weekday in
                Button(action: {
                    if userInput.isSelected(day: weekday) {
                        userInput.selectedDays.remove(weekday)
                    } else {
                        userInput.selectedDays.insert(weekday)
                    }
                }) {
                    Text(weekday.rawValue.localizedUppercase)
                        .font(.caption2)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                        .frame(width: 26, height: 26)
                }
                .tint(.accentColor.opacity(userInput.isSelected(day: weekday) ? 1 : 0.4))
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            alarmModel.scheduleAlarm(with: userInput)
            dismiss()
        } label: {
            Text("Set Alarm")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 12, y: 6)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
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
