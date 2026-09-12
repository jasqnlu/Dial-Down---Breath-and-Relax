import SwiftUI
import UserNotifications
import UIKit

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
                .foregroundStyle(Color.luminaPrimary)
                .padding(.bottom, 28)

            Text("Stay on Track")
                .font(.luminaDisplay)
                .foregroundStyle(Color.luminaOnSurface)
                .multilineTextAlignment(.center)

            Text("Get a gentle daily reminder to practise.")
                .font(.luminaBody)
                .foregroundStyle(Color.luminaOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)

            Spacer()

            VStack(spacing: 14) {
                Button(action: requestNotificationsAndComplete) {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView().tint(Color.luminaOnPrimary)
                        } else {
                            Image(systemName: "bell.fill")
                        }
                        Text("Enable Reminders")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LuminaPillButtonStyle())
                .disabled(isRequesting)
                .padding(.horizontal, 28)

                Button {
                    notificationsEnabled = false
                    onComplete()
                } label: {
                    Text("Skip for Now")
                        .font(.luminaSubheadline)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                        .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 52)
        }
        .background(Color.luminaSurface.ignoresSafeArea())
    }

    private func requestNotificationsAndComplete() {
        isRequesting = true
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                // Schedule Mon–Fri at 8 am (matches ProfileSettingsTab defaults)
                NotificationService.shared.scheduleReminders(
                    hour: 8, weekdays: [2, 3, 4, 5, 6])
                if shouldRegisterForRemotePush() {
                    UIApplication.shared.registerForRemoteNotifications()
                }
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
