import SwiftUI

// MARK: - Settings Tab

struct ProfileSettingsTab: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderHour")         private var reminderHour = 8
    @AppStorage("sessionReminderDays")  private var reminderDays = 5

    var body: some View {
        Group {
            // Reminders
            Section("Reminders") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Daily Reminders", systemImage: "bell.badge")
                }
                .onChange(of: notificationsEnabled) { _, enabled in
                    Task {
                        if enabled {
                            let granted = await NotificationService.shared.requestPermission()
                            if granted {
                                NotificationService.shared.scheduleDailyReminder(
                                    hour: reminderHour, daysPerWeek: reminderDays)
                            } else {
                                notificationsEnabled = false
                            }
                        } else {
                            NotificationService.shared.cancelReminders()
                        }
                    }
                }

                if notificationsEnabled {
                    Stepper(value: $reminderHour, in: 5...22) {
                        Label {
                            Text("Reminder at \(hourString(reminderHour))")
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                    .onChange(of: reminderHour) { _, h in
                        NotificationService.shared.scheduleDailyReminder(
                            hour: h, daysPerWeek: reminderDays)
                    }

                    Stepper(value: $reminderDays, in: 1...7) {
                        Label {
                            Text("\(reminderDays) day\(reminderDays == 1 ? "" : "s") per week")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    }
                }
            }

            // Data
            Section("Data") {
                NavigationLink(destination: DataExportView()) {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }
                NavigationLink {
                    ContentUnavailableView(
                        "Privacy Policy",
                        systemImage: "hand.raised.fill",
                        description: Text("Your data is stored locally on your device and synced to your private Supabase instance.")
                    )
                    .navigationTitle("Privacy & Data")
                } label: {
                    Label("Privacy & Data", systemImage: "hand.raised")
                }
            }

            // Health & Safety
            Section("Health & Safety") {
                NavigationLink {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Move safely", systemImage: "heart.text.square")
                                .font(.headline)
                            Text(Safety.disclaimer)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Divider()
                            Text("See a healthcare professional for:")
                                .font(.subheadline.weight(.semibold))
                            Text("• \(Safety.redFlags).")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .navigationTitle("Health & Safety")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Label("Health & Safety", systemImage: "cross.case")
                }
            }

            // About
            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
                Link(destination: URL(string: "https://github.com/jasqnlu/Breath-Relax-Stretch")!) {
                    Label("View on GitHub", systemImage: "curlybraces")
                }
            }
        }
    }

    // MARK: Helpers

    private func hourString(_ h: Int) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        c.hour = h; c.minute = 0
        return fmt.string(from: Calendar.current.date(from: c) ?? Date())
    }
}
