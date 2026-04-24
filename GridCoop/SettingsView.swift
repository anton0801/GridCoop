import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var notifManager: NotificationManager

    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var showThemePicker = false
    @State private var showAbout = false
    @State private var toastMessage: String? = nil
    @State private var showToast = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.gcBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        themeSection
                        notificationsSection
                        dataSection
                        accountSection
                        appInfoSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }

                if showToast, let msg = toastMessage {
                    VStack {
                        Spacer()
                        ToastView(message: msg)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView()
                .environmentObject(projectStore)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.gcWood, Color.gcWoodLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                Text(authVM.userName.prefix(1).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(authVM.userName.isEmpty ? "Farmer" : authVM.userName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.gcTextPrimary)
                Text(authVM.userEmail.isEmpty ? "demo@gridcoop.app" : authVM.userEmail)
                    .font(.system(size: 13))
                    .foregroundColor(.gcTextSecondary)
                Text("\(projectStore.projects.count) project\(projectStore.projects.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.gcSun)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gcCard)
        .cornerRadius(16)
    }

    // MARK: - Theme Section
    private var themeSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush.fill", iconColor: .gcWood) {
            VStack(spacing: 0) {
                Text("App Theme")
                    .font(.system(size: 14))
                    .foregroundColor(.gcTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeOptionButton(
                            theme: theme,
                            isSelected: appState.appTheme == theme.rawValue
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                appState.appTheme = theme.rawValue
                            }
                            showToastMsg("Theme changed to \(theme.displayName)")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: .gcSun) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Enable Notifications",
                    subtitle: "Allow Grid Coop to send alerts",
                    icon: "bell.badge.fill",
                    iconColor: .gcSun,
                    isOn: Binding(
                        get: { notifManager.notificationsEnabled },
                        set: { val in
                            notifManager.notificationsEnabled = val
                            if val {
                                notifManager.requestPermission { isGranted in
                                    
                                }
                                showToastMsg("Notifications enabled")
                            } else {
                                showToastMsg("Notifications disabled")
                            }
                        }
                    )
                )

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsToggleRow(
                    title: "Maintenance Reminders",
                    subtitle: "Weekly coop cleaning alerts",
                    icon: "wrench.fill",
                    iconColor: Color.gcTech,
                    isOn: Binding(
                        get: { notifManager.maintenanceReminders },
                        set: { val in
                            notifManager.maintenanceReminders = val
                            notifManager.updateMaintenanceReminder()
                            showToastMsg(val ? "Maintenance reminders on" : "Maintenance reminders off")
                        }
                    )
                )
                .disabled(!notifManager.notificationsEnabled)
                .opacity(notifManager.notificationsEnabled ? 1 : 0.5)

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsToggleRow(
                    title: "Feeding Reminders",
                    subtitle: "Daily feeding time alerts",
                    icon: "fork.knife",
                    iconColor: Color.gcNature,
                    isOn: Binding(
                        get: { notifManager.feedingReminders },
                        set: { val in
                            notifManager.feedingReminders = val
                            notifManager.updateFeedingReminder()
                            showToastMsg(val ? "Feeding reminders on" : "Feeding reminders off")
                        }
                    )
                )
                .disabled(!notifManager.notificationsEnabled)
                .opacity(notifManager.notificationsEnabled ? 1 : 0.5)

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsToggleRow(
                    title: "Daily Tips",
                    subtitle: "Morning coop optimization tips",
                    icon: "lightbulb.fill",
                    iconColor: Color.gcSun,
                    isOn: Binding(
                        get: { notifManager.dailyTipEnabled },
                        set: { val in
                            notifManager.dailyTipEnabled = val
                            notifManager.updateDailyTip()
                            showToastMsg(val ? "Daily tips enabled" : "Daily tips disabled")
                        }
                    )
                )
                .disabled(!notifManager.notificationsEnabled)
                .opacity(notifManager.notificationsEnabled ? 1 : 0.5)
            }
        }
    }

    // MARK: - Data Section
    private var dataSection: some View {
        SettingsSection(title: "Data & Projects", icon: "folder.fill", iconColor: Color.gcTech) {
            VStack(spacing: 0) {
                SettingsNavRow(
                    title: "Export Projects",
                    subtitle: "Save your coop plans as JSON",
                    icon: "square.and.arrow.up.fill",
                    iconColor: Color.gcTech
                ) {
                    showExportSheet = true
                }

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsNavRow(
                    title: "Project Stats",
                    subtitle: "\(projectStore.projects.count) projects · \(totalElements) elements",
                    icon: "chart.bar.fill",
                    iconColor: Color.gcNature
                ) {
                    showToastMsg("You have \(projectStore.projects.count) projects with \(totalElements) elements total")
                }

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsDestructiveRow(
                    title: "Clear All Projects",
                    subtitle: "Permanently delete all coop plans",
                    icon: "trash.fill"
                ) {
                    withAnimation {
                        projectStore.projects.removeAll()
                        projectStore.saveProjects()
                        showToastMsg("All projects cleared")
                    }
                }
            }
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        SettingsSection(title: "Account", icon: "person.fill", iconColor: Color.gcWoodLight) {
            VStack(spacing: 0) {
                SettingsInfoRow(title: "Email", value: authVM.userEmail.isEmpty ? "demo@gridcoop.app" : authVM.userEmail)

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsInfoRow(title: "Name", value: authVM.userName.isEmpty ? "Demo Farmer" : authVM.userName)

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                // Log Out Button
                Button {
                    showLogoutAlert = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gcSun.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gcSun)
                        }

                        Text("Log Out")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gcSun)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gcTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
                .alert("Log Out", isPresented: $showLogoutAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Log Out", role: .destructive) {
                        withAnimation {
                            authVM.logout()
                        }
                    }
                } message: {
                    Text("Are you sure you want to log out of your account?")
                }

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                // Delete Account Button
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gcAlert.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gcAlert)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gcAlert)
                            Text("Permanently remove all data")
                                .font(.system(size: 12))
                                .foregroundColor(.gcTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gcTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
                .alert("Delete Account", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete Permanently", role: .destructive) {
                        withAnimation {
                            projectStore.projects.removeAll()
                            projectStore.saveProjects()
                            authVM.deleteAccount()
                        }
                    }
                } message: {
                    Text("This will permanently delete your account and all coop projects. This action cannot be undone.")
                }
            }
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        SettingsSection(title: "App Info", icon: "info.circle.fill", iconColor: Color.gcTech) {
            VStack(spacing: 0) {
                SettingsNavRow(
                    title: "About Grid Coop",
                    subtitle: "Version, licenses & credits",
                    icon: "square.grid.3x3.fill",
                    iconColor: Color.gcWood
                ) {
                    showAbout = true
                }

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsInfoRow(title: "Version", value: "1.0.0")

                Divider().background(Color.gcGridLine).padding(.leading, 56)

                SettingsInfoRow(title: "Build", value: "100")
            }
        }
    }

    // MARK: - Helpers
    private var totalElements: Int {
        projectStore.projects.reduce(0) { $0 + $1.elements.count }
    }

    private func showToastMsg(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable, Identifiable {
    case dark = "dark"
    case light = "light"
    case system = "system"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "System"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var iconColor: Color {
        switch self {
        case .dark: return Color.gcTech
        case .light: return Color.gcSun
        case .system: return Color.gcTextSecondary
        }
    }
}

// MARK: - Theme Option Button
struct ThemeOptionButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? theme.iconColor.opacity(0.2) : Color.gcBackground)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? theme.iconColor : Color.gcGridLine, lineWidth: isSelected ? 2 : 1)
                        )

                    Image(systemName: theme.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? theme.iconColor : .gcTextSecondary)
                }

                Text(theme.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? theme.iconColor : .gcTextSecondary)
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gcTextSecondary)
                    .tracking(1)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.gcCard)
            .cornerRadius(16)
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gcTextPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gcTextSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Nav Row
struct SettingsNavRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gcTextPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gcTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gcTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gcTextPrimary)
                .padding(.leading, 16)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.gcTextSecondary)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Settings Destructive Row
struct SettingsDestructiveRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    @State private var showConfirm = false

    var body: some View {
        Button {
            showConfirm = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gcAlert.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gcAlert)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gcAlert)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gcTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gcTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .alert("Confirm Delete", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive, action: action)
        } message: {
            Text("Are you sure? This action cannot be undone.")
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.gcCard)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
            )
    }
}

// MARK: - Export View
struct ExportView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) var dismiss

    @State private var exportText = ""
    @State private var exported = false
    @State private var selectedProject: CoopProject? = nil
    @State private var exportAll = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.gcBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.gcTech, Color(hex: "#5B4BFF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 64, height: 64)
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("Export Projects")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gcTextPrimary)
                        Text("Export your coop plans as JSON data")
                            .font(.system(size: 14))
                            .foregroundColor(.gcTextSecondary)
                    }
                    .padding(.top, 8)

                    // Scope picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXPORT SCOPE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gcTextSecondary)
                            .tracking(1)

                        // All Projects
                        Button {
                            exportAll = true
                            selectedProject = nil
                        } label: {
                            HStack {
                                Image(systemName: exportAll ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(exportAll ? .gcSun : .gcTextSecondary)
                                Text("All Projects (\(projectStore.projects.count))")
                                    .foregroundColor(.gcTextPrimary)
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.gcCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(exportAll ? Color.gcSun : Color.clear, lineWidth: 1.5))
                        }

                        // Individual projects
                        ForEach(projectStore.projects) { project in
                            let isSelected = !exportAll && selectedProject?.id == project.id
                            Button {
                                exportAll = false
                                selectedProject = project
                            } label: {
                                HStack {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected ? .gcSun : .gcTextSecondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .foregroundColor(.gcTextPrimary)
                                            .font(.system(size: 15, weight: .medium))
                                        Text("\(project.elements.count) elements · \(project.birdCount) birds")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gcTextSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.gcCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.gcSun : Color.clear, lineWidth: 1.5))
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Export Button
                    Button {
                        generateExport()
                    } label: {
                        HStack(spacing: 10) {
                            if exported {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Copied to Clipboard!")
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Export & Copy")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: exported ? [Color.gcNature, Color(hex: "#6BCB77")] : [Color.gcSun, Color(hex: "#FF9F5A")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                    }
                    .scaleEffect(exported ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: exported)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.gcTextSecondary)
                }
            }
        }
    }

    private func generateExport() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let projectsToExport: [CoopProject]
        if exportAll {
            projectsToExport = projectStore.projects
        } else if let proj = selectedProject {
            projectsToExport = [proj]
        } else {
            projectsToExport = projectStore.projects
        }

        if let data = try? encoder.encode(projectsToExport),
           let json = String(data: data, encoding: .utf8) {
            exportText = json
            UIPasteboard.general.string = json
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                exported = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { exported = false }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    let features = [
        ("Layout Builder", "grid.circle.fill", "Drag & drop coop planning with grid snap"),
        ("Space Calculator", "ruler.fill", "Real-time space analysis for your flock"),
        ("Ventilation Engine", "wind", "CFM calculations for healthy airflow"),
        ("Environment Analysis", "thermometer.medium", "Climate-aware condition monitoring"),
        ("Smart Suggestions", "lightbulb.fill", "AI-style recommendations for optimization"),
        ("Budget Tracker", "dollarsign.circle.fill", "Full project cost management"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.gcBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.gcWood, Color.gcWoodLight], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.gcWood.opacity(0.4), radius: 16, x: 0, y: 6)
                                Image(systemName: "square.grid.3x3.fill")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("Grid Coop")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.gcTextPrimary)

                            Text("Smart Poultry Space Planner")
                                .font(.system(size: 15))
                                .foregroundColor(.gcTextSecondary)

                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gcSun)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.gcSun.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(.top, 16)

                        // Features
                        VStack(alignment: .leading, spacing: 0) {
                            Text("FEATURES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gcTextSecondary)
                                .tracking(1)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(Array(features.enumerated()), id: \.offset) { idx, feature in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gcWood.opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            Image(systemName: feature.1)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.gcWood)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(feature.0)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.gcTextPrimary)
                                            Text(feature.2)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gcTextSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                    if idx < features.count - 1 {
                                        Divider().background(Color.gcGridLine).padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color.gcCard)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)

                        // Credits
                        VStack(spacing: 8) {
                            Text("Built with SwiftUI")
                                .font(.system(size: 13))
                                .foregroundColor(.gcTextSecondary)
                            Text("© 2025 Grid Coop. All rights reserved.")
                                .font(.system(size: 12))
                                .foregroundColor(.gcTextSecondary.opacity(0.6))
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.gcTextSecondary)
                }
            }
        }
    }
}
