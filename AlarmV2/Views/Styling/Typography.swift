import SwiftUI

// MARK: - App Typography

struct AppTypography {

    // MARK: - Title

    /// Title text: 34pt semibold
    static let title = Font.system(size: 34, weight: .semibold)

    // MARK: - Time Display

    /// Time display: 48pt semibold with monospaced digits
    static let time = Font.system(size: 48, weight: .semibold, design: .rounded)
        .monospacedDigit()

    /// AM/PM display: 18pt medium
    static let period = Font.system(size: 18, weight: .medium)

    // MARK: - Body Text

    /// Proof label: 14pt regular
    static let proofLabel = Font.system(size: 14, weight: .regular)

    /// Day chip text: 14pt medium
    static let dayChip = Font.system(size: 14, weight: .medium)

    /// Button text: 16pt semibold
    static let button = Font.system(size: 16, weight: .semibold)
}
