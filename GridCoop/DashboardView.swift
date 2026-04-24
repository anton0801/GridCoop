import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var notesStore = NotesStore()
    @StateObject var budgetStore = BudgetStore()
    @StateObject var notificationManager = NotificationManager()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case 0: DashboardView()
                case 1: ProjectsListView()
                case 2: CalculatorsHubView()
                case 3: NotesListView().environmentObject(notesStore)
                case 4: SettingsView()
                    .environmentObject(notificationManager)
                    .environmentObject(budgetStore)
                default: DashboardView()
                }
            }
            .padding(.bottom, 80)
            
            // Custom Tab Bar
            GCTabBar(selectedTab: $selectedTab)
        }
        .environmentObject(notesStore)
        .environmentObject(budgetStore)
        .environmentObject(notificationManager)
    }
}

struct GCTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("square.grid.2x2.fill", "Projects"),
        ("chart.bar.fill", "Calculate"),
        ("note.text", "Notes"),
        ("gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = idx
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[idx].icon)
                            .font(.system(size: 20, weight: selectedTab == idx ? .bold : .regular))
                            .foregroundColor(selectedTab == idx ? .sunYellow : .white.opacity(0.4))
                            .scaleEffect(selectedTab == idx ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)
                        Text(tabs[idx].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == idx ? .sunYellow : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.bgSecondary)
                .shadow(color: .black.opacity(0.3), radius: 16, y: -4)
        )
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var environmentStore: EnvironmentStore
    @State private var showingSetup = false
    
    var project: CoopProject? { projectStore.projects.first }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(timeOfDayGreeting)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Text(authViewModel.userName.isEmpty ? "Farmer" : authViewModel.userName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(LinearGradient.woodGradient)
                                .frame(width: 48, height: 48)
                            Text("🐔")
                                .font(.system(size: 22))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    
                    if let p = project {
                        // Project Score Cards
                        HStack(spacing: 12) {
                            ScoreCard(
                                title: "Efficiency",
                                value: p.efficiencyScore,
                                icon: "bolt.fill",
                                gradient: LinearGradient.accentGradient
                            )
                            ScoreCard(
                                title: "Comfort",
                                value: p.comfortScore,
                                icon: "heart.fill",
                                gradient: LinearGradient.natureGradient
                            )
                        }
                        .padding(.horizontal, 18)
                        
                        // Status Card
                        DashboardStatusCard(project: p)
                            .padding(.horizontal, 18)
                        
                        // Environment Card
                        EnvironmentCard()
                            .padding(.horizontal, 18)
                        
                        // Suggestions Preview
                        let suggestions = projectStore.suggestions(for: p)
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("💡 Suggestions")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    NavigationLink(destination: SuggestionsView(project: p)) {
                                        Text("See All")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.sunYellow)
                                    }
                                }
                                
                                ForEach(suggestions.prefix(2)) { suggestion in
                                    SuggestionCard(suggestion: suggestion)
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                        
                        // Upcoming Tasks
                        let pendingTasks = p.tasks.filter { !$0.isCompleted }.prefix(3)
                        if !pendingTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("📋 Upcoming Tasks")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    NavigationLink(destination: TasksView(project: .constant(p))) {
                                        Text("See All")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.sunYellow)
                                    }
                                }
                                ForEach(pendingTasks) { task in
                                    MiniTaskRow(task: task, projectId: p.id)
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                        
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Text("🏗").font(.system(size: 60))
                            Text("No Projects Yet")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("Create your first coop project to get started")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                            NavigationLink(destination: CreateProjectView()) {
                                Text("Create Project")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.bgPrimary)
                                    .frame(width: 200, height: 48)
                                    .background(LinearGradient.accentGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(40)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }
}

struct ScoreCard: View {
    let title: String
    let value: Int
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("/100")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 6)
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 5)
                    Capsule()
                        .fill(gradient)
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct DashboardStatusCard: View {
    let project: CoopProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🐔 \(project.name)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                StatusBadge(status: project.spaceStatus)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            HStack(spacing: 0) {
                StatCell(label: "Birds", value: "\(project.birdCount)", icon: project.birdType.icon, isEmoji: true)
                StatCell(label: "Area", value: "\(String(format: "%.1f", project.totalArea))m²", icon: "square.fill", isEmoji: false)
                StatCell(label: "Nests", value: "\(project.nestBoxCount)/\(project.recommendedNestBoxes)", icon: "🪺", isEmoji: true)
                StatCell(label: "Elements", value: "\(project.elements.count)", icon: "square.grid.3x3.fill", isEmoji: false)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct StatCell: View {
    let label: String
    let value: String
    let icon: String
    let isEmoji: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            if isEmoji {
                Text(icon).font(.system(size: 16))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.woodLight)
            }
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusBadge: View {
    let status: SpaceStatus
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct EnvironmentCard: View {
    @EnvironmentObject var environmentStore: EnvironmentStore
    
    var env: EnvironmentData { environmentStore.environmentData }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.sun.fill")
                    .foregroundColor(.sunYellow)
                Text("Environment")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: env.overallStatus.icon)
                    Text(env.overallStatus.label)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(env.overallStatus.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(env.overallStatus.color.opacity(0.15))
                .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                EnvironmentMetric(
                    label: "Temperature",
                    value: "\(Int(env.temperature))°C",
                    icon: "thermometer",
                    status: env.temperatureStatus
                )
                EnvironmentMetric(
                    label: "Humidity",
                    value: "\(Int(env.humidity))%",
                    icon: "humidity.fill",
                    status: env.humidityStatus
                )
                EnvironmentMetric(
                    label: "Climate",
                    value: env.climate.rawValue,
                    icon: env.climate.icon,
                    status: .good
                )
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct EnvironmentMetric: View {
    let label: String
    let value: String
    let icon: String
    let status: ConditionStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SuggestionCard: View {
    let suggestion: CoopSuggestion
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(suggestion.impact.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: suggestion.icon)
                    .foregroundColor(suggestion.impact.color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(suggestion.impact.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(suggestion.impact.color)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct MiniTaskRow: View {
    let task: CoopTask
    let projectId: UUID
    @EnvironmentObject var projectStore: ProjectStore
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                projectStore.toggleTask(task.id, in: projectId)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .natureDark : .white.opacity(0.3))
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                if let due = task.dueDate {
                    Text(due, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(due < Date() ? .alertRed : .white.opacity(0.4))
                }
            }
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: task.category.icon)
                    .font(.system(size: 10))
            }
            .foregroundColor(task.category.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
