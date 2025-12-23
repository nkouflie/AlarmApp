
import SwiftUI
import AlarmKit

struct AlarmCell: View {
    var alarm: Alarm
    var label: LocalizedStringResource
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let alertingTime = alarm.alertingTime {
                    Text(alertingTime, style: .time)
                        .font(.title)
                        .fontWeight(.medium)
                } else if let countdown = alarm.countdownDuration?.preAlert {
                    Text(countdown.customFormatted())
                        .font(.title)
                        .fontWeight(.medium)
                }
                Spacer()
                tag
            }
            
            Text(label)
                .font(.headline)
        }
    }
    
    var tag: some View {
        Text(tagLabel)
            .textCase(.uppercase)
            .font(.caption.bold())
            .padding(4)
            .background(tagColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    var tagLabel: String {
        switch alarm.state {
        case .scheduled: "Scheduled"
        case .countdown: "Running"
        case .paused: "Paused"
        case .alerting: "Alert"
        @unknown default: "!"
        }
    }
    
    var tagColor: Color {
        switch alarm.state {
        case .scheduled: .blue
        case .countdown: .green
        case .paused: .yellow
        case .alerting: .red
        @unknown default: .gray
        }
    }
}
