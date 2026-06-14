import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService

    @Query private var allTerms: [Term]
    @Query private var collections: [TermCollection]

    @AppStorage(AppConstants.apiKeyDefaultsKey) private var apiKey = ""
    @AppStorage(AppConstants.remindersPerDayKey) private var remindersPerDay = AppConstants.defaultRemindersPerDay
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showAPIKey = false
    @State private var apiKeyInput = ""
    @State private var showResetAlert = false
    @State private var showAPIKeySheet = false

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                apiSection
                aboutSection
                dangerSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAPIKeySheet) {
                apiKeySheet
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAllData() }
            } message: {
                Text("This will permanently delete all terms, collections, and progress. This cannot be undone.")
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Permission", systemImage: "bell.fill")
                Spacer()
                if notificationService.isAuthorized {
                    Label("Allowed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.accent)
                        .font(AppFonts.caption())
                } else {
                    Button("Enable") {
                        Task { await notificationService.requestAuthorization() }
                    }
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.primary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Reminders per day", systemImage: "clock")
                    Spacer()
                    Text("\(remindersPerDay)")
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(remindersPerDay) },
                    set: { remindersPerDay = Int($0.rounded()) }
                ), in: 1...10, step: 1)
                .tint(AppColors.primary)
            }

            if notificationService.isAuthorized {
                Button {
                    Task {
                        await notificationService.scheduleReminders(terms: allTerms, remindersPerDay: remindersPerDay)
                    }
                } label: {
                    Label("Reschedule Reminders", systemImage: "arrow.clockwise")
                }

                HStack {
                    Label("Scheduled", systemImage: "calendar")
                    Spacer()
                    Text("\(notificationService.pendingCount) pending")
                        .foregroundStyle(.secondary)
                        .font(AppFonts.caption())
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    private var apiSection: some View {
        Section {
            HStack {
                Label("Claude API Key", systemImage: "key.fill")
                Spacer()
                if apiKey.isEmpty {
                    Text("Not set")
                        .foregroundStyle(AppColors.secondary)
                        .font(AppFonts.caption())
                } else {
                    Text("Set ✓")
                        .foregroundStyle(AppColors.accent)
                        .font(AppFonts.caption())
                }
            }
            .onTapGesture { showAPIKeySheet = true }

            Button {
                showAPIKeySheet = true
            } label: {
                Label(apiKey.isEmpty ? "Add API Key" : "Change API Key", systemImage: "pencil")
            }
        } header: {
            Text("AI")
        } footer: {
            Text("Your API key is stored securely on this device only. Your data is never used to train Claude.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Total Terms", systemImage: "text.book.closed")
                Spacer()
                Text("\(allTerms.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Collections", systemImage: "books.vertical")
                Spacer()
                Text("\(collections.count)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Danger Zone")
        }
    }

    private var apiKeySheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude API Key")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)

                    HStack {
                        if showAPIKey {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                        }
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary.opacity(0.3), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Get a free API key at console.anthropic.com", systemImage: "link")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                    Label("Your key is stored only on this device", systemImage: "lock.shield")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                    Label("Never used for AI training", systemImage: "hand.raised.fill")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(AppColors.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !apiKey.isEmpty {
                    Button(role: .destructive) {
                        apiKey = ""
                        apiKeyInput = ""
                    } label: {
                        Text("Remove Key")
                    }
                }

                Spacer()
            }
            .padding(24)
            .onAppear { apiKeyInput = apiKey }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAPIKeySheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
                        showAPIKeySheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func resetAllData() {
        for term in allTerms { modelContext.delete(term) }
        for col in collections { modelContext.delete(col) }
        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: "currentStreak")
        UserDefaults.standard.removeObject(forKey: "lastStudyDate")
    }
}
