
import SwiftUI
import AlarmKit

struct MainView: View {
    
    @State private var alarmModel = AlarmModel()
    @State private var showAddAlarmSheet = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Alarms")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddAlarmSheet.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .sheet(isPresented: $showAddAlarmSheet) {
            AddAlarmView()
        }
        .environment(alarmModel)
    }
    
    @ViewBuilder var content: some View {
        if alarmModel.hasAlarms {
            alarmList(alarms: Array(alarmModel.alarmsMap.values))
        } else {
            ContentUnavailableView("No Alarms", systemImage: "clock.badge.exclamationmark", description: Text("Add a new alarm by tapping + button."))
        }
    }
    
    func alarmList(alarms: [AlarmModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    guard index < alarms.count else { continue }
                    alarmModel.unscheduleAlarm(with: alarms[index].0.id)
                }
            }
        }
    }
}

#Preview {
    MainView()
}
