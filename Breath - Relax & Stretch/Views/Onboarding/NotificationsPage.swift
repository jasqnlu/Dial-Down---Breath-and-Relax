import SwiftUI
import UserNotifications

// MARK: - Notifications Page

struct NotificationsPage: View {
    let onComplete: () -> Void
    @State private var isRequesting = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 28)

            Text("Stay on Track")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Get a gentle daily reminder to practise.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)

            Spacer()

            VStack(spacing: 14) {
                Button(action: requestNotificationsAndComplete) {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                        }
                        Text("Enable Reminders")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isRequesting)
                .padding(.horizontal, 28)

                Button {
                    notificationsEnabled = false
                    onComplete()
                } label: {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 52)
        }
    }

    private func requestNotificationsAndComplete() {
        isRequesting = true
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                // Schedule Mon–Fri at 8 am (matches ProfileSettingsTab defaults)
                NotificationService.shared.scheduleReminders(
                    hour: 8, weekdays: [2, 3, 4, 5, 6])
            }
            await MainActor.run {
                // Keep the persisted flag in sync with what actually happened —
                // otherwise a denial here leaves notificationsEnabled at its
                // default true with nothing actually scheduled, and
                // ProfileSettingsTab's Reminders section would show as "on"
                // with no way to notice it's inert.
                notificationsEnabled = granted
                isRequesting = false
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview { NotificationsPage(onComplete: {}) }
