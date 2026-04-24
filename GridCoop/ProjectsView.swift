import SwiftUI

// MARK: - Projects List
struct ProjectsListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingCreate = false
    @State private var searchText = ""
    
    var filteredProjects: [CoopProject] {
        if searchText.isEmpty { return projectStore.projects }
        return projectStore.projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Projects")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("\(projectStore.projects.count) coop project\(projectStore.projects.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                        Button {
                            showingCreate = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.bgPrimary)
                                .frame(width: 40, height: 40)
                                .background(LinearGradient.accentGradient)
                                .clipShape(Circle())
                                .shadow(color: Color.sunYellow.opacity(0.35), radius: 8)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search projects...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                    
                    if filteredProjects.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("🏗").font(.system(size: 50))
                            Text("No Projects")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text("Tap + to create your first coop project")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredProjects) { project in
                                    NavigationLink(destination: ProjectOverviewView(project: project)) {
                                        ProjectCard(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreate) {
                CreateProjectView()
            }
        }
    }
}

struct ProjectCard: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient.woodGradient)
                        .frame(width: 48, height: 48)
                    Text(project.birdType.icon)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(project.birdCount) \(project.birdType.rawValue)s · \(project.goal.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                StatusBadge(status: project.spaceStatus)
            }
            
            Divider().background(Color.white.opacity(0.07))
            
            HStack(spacing: 0) {
                MiniStat(label: "Area", value: "\(String(format: "%.1f", project.totalArea))m²")
                MiniStat(label: "Elements", value: "\(project.elements.count)")
                MiniStat(label: "Efficiency", value: "\(project.efficiencyScore)%")
                MiniStat(label: "Tasks", value: "\(project.tasks.filter { !$0.isCompleted }.count)")
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Project", systemImage: "trash.fill")
            }
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                projectStore.deleteProject(project)
            }
        } message: {
            Text("This will permanently delete '\(project.name)' and all its data.")
        }
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Create Project
struct CreateProjectView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var plotWidth = "4.0"
    @State private var plotHeight = "3.0"
    @State private var birdCount = "10"
    @State private var birdType: BirdType = .chicken
    @State private var goal: CoopGoal = .eggs
    @State private var notes = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Project Name
                        FormSection(title: "Project Name") {
                            GCTextField(text: $name, placeholder: "e.g. Backyard Coop", icon: "house.fill")
                        }
                        
                        // Plot Size
                        FormSection(title: "Plot Size (meters)") {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Width").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                    GCTextField(text: $plotWidth, placeholder: "4.0", icon: "arrow.left.and.right", keyboardType: .decimalPad)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Height").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                    GCTextField(text: $plotHeight, placeholder: "3.0", icon: "arrow.up.and.down", keyboardType: .decimalPad)
                                }
                            }
                        }
                        
                        // Bird Info
                        FormSection(title: "Flock") {
                            VStack(spacing: 10) {
                                GCTextField(text: $birdCount, placeholder: "Number of birds", icon: "number", keyboardType: .numberPad)
                                
                                // Bird Type Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bird Type").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(BirdType.allCases, id: \.self) { bt in
                                                Button {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        birdType = bt
                                                    }
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Text(bt.icon)
                                                        Text(bt.rawValue)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(birdType == bt ? .bgPrimary : .white.opacity(0.7))
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .frame(height: 36)
                                                    .background(birdType == bt ? Color.sunYellow : Color.cardBgLight)
                                                    .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                                
                                // Goal Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Goal").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6))
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(CoopGoal.allCases, id: \.self) { g in
                                                Button {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        goal = g
                                                    }
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Text(g.icon)
                                                        Text(g.rawValue)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(goal == g ? .bgPrimary : .white.opacity(0.7))
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .frame(height: 36)
                                                    .background(goal == g ? Color.sunYellow : Color.cardBgLight)
                                                    .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        FormSection(title: "Notes (optional)") {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $notes)
                                    .foregroundColor(.white)
                                    .colorScheme(.dark)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                if notes.isEmpty {
                                    Text("Add any initial notes...")
                                        .foregroundColor(.white.opacity(0.3))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                            .padding(14)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.alertRed)
                                .font(.system(size: 13))
                                .padding(.horizontal, 18)
                        }
                        
                        Button {
                            createProject()
                        } label: {
                            Text("Create Project")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(LinearGradient.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    func createProject() {
        guard !name.isEmpty else { errorMessage = "Please enter a project name."; return }
        guard let w = Double(plotWidth), w > 0 else { errorMessage = "Invalid width."; return }
        guard let h = Double(plotHeight), h > 0 else { errorMessage = "Invalid height."; return }
        guard let count = Int(birdCount), count > 0 else { errorMessage = "Invalid bird count."; return }
        
        let project = CoopProject(
            name: name,
            birdType: birdType,
            birdCount: count,
            goal: goal,
            plotWidth: w,
            plotHeight: h,
            elements: [],
            createdAt: Date(),
            updatedAt: Date(),
            notes: notes
        )
        projectStore.addProject(project)
        dismiss.wrappedValue.dismiss()
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 18)
            content()
                .padding(.horizontal, 18)
        }
    }
}

// MARK: - Project Overview
struct ProjectOverviewView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingEdit = false
    
    var currentProject: CoopProject {
        projectStore.projects.first { $0.id == project.id } ?? project
    }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentProject.name)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("\(currentProject.birdType.icon) \(currentProject.birdCount) \(currentProject.birdType.rawValue)s · \(currentProject.goal.icon) \(currentProject.goal.rawValue)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            Spacer()
                            StatusBadge(status: currentProject.spaceStatus)
                        }
                        
                        HStack(spacing: 12) {
                            ScoreCard(title: "Efficiency", value: currentProject.efficiencyScore, icon: "bolt.fill", gradient: .accentGradient)
                            ScoreCard(title: "Comfort", value: currentProject.comfortScore, icon: "heart.fill", gradient: .natureGradient)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    
                    // Quick Actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        NavigationLink(destination: LayoutBuilderView(project: currentProject)) {
                            ActionButton(icon: "square.grid.3x3.fill", label: "Layout Builder", color: .sunYellow)
                        }
                        NavigationLink(destination: SuggestionsView(project: currentProject)) {
                            ActionButton(icon: "lightbulb.fill", label: "Suggestions", color: .techBlue)
                        }
                        NavigationLink(destination: TasksView(project: .constant(currentProject))) {
                            ActionButton(icon: "checklist", label: "Tasks", color: .natureDark)
                        }
                        NavigationLink(destination: CostEstimatorView(project: currentProject)) {
                            ActionButton(icon: "dollarsign.circle.fill", label: "Budget", color: .woodLight)
                        }
                    }
                    
                    // Space Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📐 Space Analysis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            InfoCell(title: "Total Area", value: "\(String(format: "%.1f", currentProject.totalArea)) m²", icon: "square.fill", color: .techBlue)
                            InfoCell(title: "Required", value: "\(String(format: "%.1f", currentProject.requiredSpace)) m²", icon: "person.2.fill", color: .woodLight)
                            InfoCell(title: "Max Birds", value: "\(projectStore.maxCapacity(for: currentProject))", icon: currentProject.birdType.icon, color: .natureDark, isEmoji: true)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Elements summary
                    if !currentProject.elements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🏗 Layout Elements")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            let grouped = Dictionary(grouping: currentProject.elements) { $0.type }
                            ForEach(ElementType.allCases.filter { grouped[$0] != nil }, id: \.self) { type in
                                HStack {
                                    Text(type.icon)
                                        .font(.system(size: 18))
                                    Text(type.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(grouped[type]?.count ?? 0)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.sunYellow)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .navigationTitle(currentProject.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct InfoCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isEmoji: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            if isEmoji {
                Text(icon).font(.system(size: 18))
            } else {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
            }
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
