import SwiftUI

// MARK: - Settings Tab

struct ProfileSettingsTab: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderHour")         private var reminderHour = 8
    @AppStorage("reminderWeekdays")     private var weekdaysStr = "2,3,4,5,6" // Mon–Fri default
    @AppStorage("bodyMapSex")           private var bodyMapSex = "male"
    @AppStorage("onboardingGoals")      private var goalsStr = ""
    @AppStorage("voiceCuesEnabled")     private var voiceCuesEnabled = false
    @AppStorage("autoSkipGetReadyCountdown") private var autoSkipGetReadyCountdown = false
    @AppStorage("calendarSyncEnabled")  private var calendarSyncEnabled = false
    @State private var showingAppGuide = false

    private let allGoals: [(id: String, label: String, icon: String)] = [
        ("flexibility",      "Flexibility",       "figure.flexibility"),
        ("stress_relief",    "Stress Relief",     "leaf.fill"),
        ("pain_relief",      "Pain Relief",       "bandage.fill"),
        ("better_breathing", "Better Breathing",  "wind"),
    ]

    private var selectedGoals: Set<String> {
        Set(goalsStr.split(separator: ",").map(String.init))
    }

    private func toggleGoal(_ id: String) {
        var current = selectedGoals
        if current.contains(id) { current.remove(id) } else { current.insert(id) }
        goalsStr = current.sorted().joined(separator: ",")
    }

    // Calendar weekday numbers 1=Sun … 7=Sat, with display labels
    private let weekdays: [(Int, String)] = [
        (2,"Mo"), (3,"Tu"), (4,"We"), (5,"Th"), (6,"Fr"), (7,"Sa"), (1,"Su")
    ]

    private var selectedWeekdays: Set<Int> {
        get { Set(weekdaysStr.split(separator: ",").compactMap { Int($0) }) }
    }

    private func toggleWeekday(_ day: Int) {
        var current = selectedWeekdays
        if current.contains(day) {
            current.remove(day)
        } else {
            current.insert(day)
        }
        weekdaysStr = current.sorted().map(String.init).joined(separator: ",")
        reschedule(weekdays: current)
    }

    private func reschedule(weekdays days: Set<Int>) {
        guard notificationsEnabled, !days.isEmpty else { return }
        NotificationService.shared.scheduleReminders(hour: reminderHour, weekdays: days)
    }

    var body: some View {
        Group {
            // Goals
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(allGoals, id: \.id) { goal in
                        let selected = selectedGoals.contains(goal.id)
                        Button { toggleGoal(goal.id) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: goal.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                                Text(goal.label)
                                    .font(.subheadline)
                                    .foregroundStyle(selected ? Color.accentColor : .primary)
                                Spacer(minLength: 0)
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                selected
                                    ? Color.accentColor.opacity(0.10)
                                    : Color(.secondarySystemFill),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("My Goals")
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            } footer: {
                Text("Shapes the \"For You\" exercises in the Exercises tab.")
            }

            // Body Map
            Section("Body Map") {
                Picker("Body Type", selection: $bodyMapSex) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                .pickerStyle(.segmented)
            }

            // Session
            Section {
                Toggle(isOn: $voiceCuesEnabled) {
                    Label("Voice Cues", systemImage: "waveform")
                }
                Toggle(isOn: $autoSkipGetReadyCountdown) {
                    Label("Auto-Skip Get-Ready Countdown", systemImage: "forward.end")
                }
            } header: {
                Text("Session")
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            } footer: {
                Text("Announces exercise names and breathing phases aloud during sessions. Auto-skip jumps straight into each exercise without the 3-2-1 countdown.")
            }

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
                                reschedule(weekdays: selectedWeekdays)
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
                            Text("Remind me at \(hourString(reminderHour))")
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                    .onChange(of: reminderHour) { _, h in
                        reschedule(weekdays: selectedWeekdays)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            ForEach(weekdays, id: \.0) { (day, label) in
                                let selected = selectedWeekdays.contains(day)
                                Button {
                                    toggleWeekday(day)
                                } label: {
                                    Text(label)
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 34, height: 34)
                                        .background(
                                            selected ? Color.accentColor : Color(.secondarySystemFill),
                                            in: Circle()
                                        )
                                        .foregroundStyle(selected ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(fullDayName(day))
                                .accessibilityAddTraits(selected ? .isSelected : [])
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Integrations
            Section {
                Button {
                    Task { await HealthKitService.shared.requestAuthorization() }
                } label: {
                    Label("Connect Apple Health", systemImage: "heart.fill")
                        .foregroundStyle(.red)
                }

                Toggle(isOn: $calendarSyncEnabled) {
                    Label("Add Sessions to Calendar", systemImage: "calendar")
                }
                .onChange(of: calendarSyncEnabled) { _, enabled in
                    if enabled {
                        Task {
                            let granted = await CalendarService.shared.requestAccess()
                            if !granted { calendarSyncEnabled = false }
                        }
                    }
                }
            } header: {
                Text("Integrations")
                    .font(.luminaLabel)
                    .foregroundStyle(Color.luminaOnSurfaceVariant)
            } footer: {
                Text("Logs stretch sessions as Flexibility workouts and breathing sessions as Mindful Minutes, and reads last night's sleep to suggest a gentler routine when you're under-rested. Google Health and other apps that sync with Apple Health will receive the data automatically. Calendar sync adds a same-time event for each completed session and suggests a free slot for your next one.")
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

            // Help
            Section("Help") {
                Button {
                    showingAppGuide = true
                } label: {
                    Label("Replay App Tour", systemImage: "questionmark.circle")
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
        .listRowBackground(Color.luminaCardFill)
        .sheet(isPresented: $showingAppGuide) {
            AppGuideView()
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

    private func fullDayName(_ weekday: Int) -> String {
        let names = [1:"Sunday",2:"Monday",3:"Tuesday",4:"Wednesday",5:"Thursday",6:"Friday",7:"Saturday"]
        return names[weekday] ?? "Day \(weekday)"
    }
}
