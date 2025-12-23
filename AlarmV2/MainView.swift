
import SwiftUI
import AlarmKit

struct MainView: View {
    
    @State private var alarmModel = AlarmModel()
    @State private var showAddAlarmSheet = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Alarm")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddAlarmSheet.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.medium)
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
            alarmList(alarms: sortedAlarms)
        } else {
            emptyState
        }
    }
    
    private var sortedAlarms: [AlarmModel.AlarmsMap.Value] {
        Array(alarmModel.alarmsMap.values).sorted { first, second in
            // Sort by alerting time if available, otherwise by ID
            guard let firstTime = first.0.alertingTime,
                  let secondTime = second.0.alertingTime else {
                return first.0.id.uuidString < second.0.id.uuidString
            }
            return firstTime < secondTime
        }
    }
    
    func alarmList(alarms: [AlarmModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            .onDelete { indexSet in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    for index in indexSet {
                        guard index < alarms.count else { continue }
                        alarmModel.unscheduleAlarm(with: alarms[index].0.id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Clock icon with subtle styling
            Image(systemName: "alarm.fill")
                .font(.system(size: 70, weight: .thin))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.bottom, 8)
            
            // Title
            Text("No Alarms")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // Description
            Text("Tap the + button to create\nyour first alarm")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    MainView()
}
