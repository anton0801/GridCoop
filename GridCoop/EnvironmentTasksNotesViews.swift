import SwiftUI

// MARK: - Environment Analysis
struct EnvironmentAnalysisView: View {
    @EnvironmentObject var environmentStore: EnvironmentStore
    @State private var showingSetup = false
    
    var env: EnvironmentData { environmentStore.environmentData }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Overall status
                    VStack(spacing: 8) {
                        Image(systemName: env.overallStatus.icon)
                            .font(.system(size: 50))
                            .foregroundColor(env.overallStatus.color)
                        Text("Overall: \(env.overallStatus.label)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(env.overallStatus.color)
                    }
                    .padding(.top, 20)
                    
                    // Conditions
                    VStack(spacing: 12) {
                        ConditionCard(
                            title: "Temperature",
                            value: "\(Int(env.temperature))°C",
                            status: env.temperatureStatus,
                            icon: "thermometer",
                            idealRange: "15–25°C",
                            icon2: "thermometer"
                        )
                        ConditionCard(
                            title: "Humidity",
                            value: "\(Int(env.humidity))%",
                            status: env.humidityStatus,
                            icon: "humidity.fill",
                            idealRange: "50–70%",
                            icon2: "humidity.fill"
                        )
                    }
                    .padding(.horizontal, 18)
                    
                    // Climate info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: env.climate.icon)
                                .foregroundColor(.techBlue)
                                .font(.system(size: 20))
                            Text("\(env.climate.rawValue) Climate")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        let tips = climateTips(for: env.climate)
                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•").foregroundColor(.techBlue)
                                Text(tip).font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    // Edit button
                    Button {
                        showingSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Update Environment Settings")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Environment Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSetup) {
            EnvironmentSetupView()
        }
    }
    
    func climateTips(for climate: ClimateType) -> [String] {
        switch climate {
        case .tropical: return ["Prioritize shade and ventilation.", "Use nipple waterers to reduce spills.", "Monitor for fungal diseases in wet season."]
        case .arid: return ["Provide ample water and shade.", "Use evaporative cooling if possible.", "Consider misting systems in extreme heat."]
        case .temperate: return ["Insulate coop for winter months.", "Ensure good drainage.", "Adjust supplemental lighting seasonally."]
        case .continental: return ["Insulate heavily for cold winters.", "Provide windbreaks.", "Ensure water doesn't freeze."]
        case .polar: return ["Heavily insulated coop essential.", "Use heated waterers.", "Limit outdoor access in extreme cold."]
        }
    }
}

struct ConditionCard: View {
    let title: String
    let value: String
    let status: ConditionStatus
    let icon: String
    let idealRange: String
    let icon2: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .font(.system(size: 24))
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(status.color)
                Text("Ideal: \(idealRange)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                Text(status.label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Environment Setup
struct EnvironmentSetupView: View {
    @EnvironmentObject var environmentStore: EnvironmentStore
    @Environment(\.presentationMode) var dismiss
    @State private var temp: Double = 20
    @State private var humidity: Double = 60
    @State private var climate: ClimateType = .temperate
    @State private var showSaved = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Temperature: \(Int(temp))°C")
                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                Spacer()
                                Text(temp < 10 ? "❄️ Cold" : temp > 28 ? "🔥 Hot" : "✅ Good")
                                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                            }
                            Slider(value: $temp, in: -20...45, step: 1)
                                .accentColor(.sunYellow)
                            HStack {
                                Text("-20°C").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("45°C").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(16).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Humidity: \(Int(humidity))%")
                                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                Spacer()
                                Text(humidity < 40 ? "🌵 Dry" : humidity > 75 ? "💦 Moist" : "✅ Good")
                                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                            }
                            Slider(value: $humidity, in: 0...100, step: 1)
                                .accentColor(.techBlue)
                        }
                        .padding(16).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Climate Type")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.6))
                            ForEach(ClimateType.allCases, id: \.self) { ct in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { climate = ct }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: ct.icon)
                                            .foregroundColor(climate == ct ? .sunYellow : .white.opacity(0.4))
                                            .frame(width: 24)
                                        Text(ct.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if climate == ct {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.sunYellow)
                                        }
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 12)
                                    .background(climate == ct ? Color.cardBgLight : Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        
                        if showSaved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.natureDark)
                                Text("Settings saved!").font(.system(size: 14, weight: .medium)).foregroundColor(.natureDark)
                            }
                        }
                        
                        Button {
                            environmentStore.environmentData.temperature = temp
                            environmentStore.environmentData.humidity = humidity
                            environmentStore.environmentData.climate = climate
                            environmentStore.save()
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss.wrappedValue.dismiss()
                            }
                        } label: {
                            Text("Save Settings")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(LinearGradient.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Environment Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.white.opacity(0.6))
                }
            }
            .onAppear {
                temp = environmentStore.environmentData.temperature
                humidity = environmentStore.environmentData.humidity
                climate = environmentStore.environmentData.climate
            }
        }
    }
}

// MARK: - Suggestions View
struct SuggestionsView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingOptimization = false
    
    var suggestions: [CoopSuggestion] {
        projectStore.suggestions(for: project)
    }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            if suggestions.isEmpty {
                VStack(spacing: 16) {
                    Text("✅").font(.system(size: 60))
                    Text("All Clear!")
                        .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                    Text("Your coop is well-optimized. Keep maintaining these conditions.")
                        .font(.system(size: 15)).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary
                        HStack(spacing: 12) {
                            let highCount = suggestions.filter { $0.impact == .high }.count
                            let medCount = suggestions.filter { $0.impact == .medium }.count
                            let lowCount = suggestions.filter { $0.impact == .low }.count
                            if highCount > 0 { ImpactPill(count: highCount, impact: .high) }
                            if medCount > 0 { ImpactPill(count: medCount, impact: .medium) }
                            if lowCount > 0 { ImpactPill(count: lowCount, impact: .low) }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        
                        // Auto Optimize
                        Button {
                            showingOptimization = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16))
                                Text("Auto-Optimize Layout")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.bgPrimary)
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(LinearGradient.techGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 18)
                        
                        ForEach(suggestions) { suggestion in
                            SuggestionDetailCard(suggestion: suggestion)
                                .padding(.horizontal, 18)
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .navigationTitle("Suggestions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingOptimization) {
            OptimizationModeView(project: project)
        }
    }
}

struct ImpactPill: View {
    let count: Int
    let impact: CoopSuggestion.ImpactLevel
    
    var body: some View {
        HStack(spacing: 5) {
            Text("\(count)").font(.system(size: 12, weight: .bold)).foregroundColor(impact.color)
            Text(impact.rawValue).font(.system(size: 11, weight: .medium)).foregroundColor(impact.color.opacity(0.8))
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(impact.color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(impact.color.opacity(0.25), lineWidth: 1))
    }
}

struct SuggestionDetailCard: View {
    let suggestion: CoopSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(suggestion.impact.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: suggestion.icon)
                        .foregroundColor(suggestion.impact.color)
                        .font(.system(size: 20, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text(suggestion.impact.rawValue)
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(suggestion.impact.color)
                }
                Spacer()
                Text(suggestion.category.rawValue)
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.4))
            }
            Text(suggestion.description)
                .font(.system(size: 14)).foregroundColor(.white.opacity(0.7)).lineSpacing(3)
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(suggestion.impact.color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Optimization Mode
struct OptimizationModeView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.presentationMode) var dismiss
    @State private var isOptimizing = false
    @State private var optimized = false
    @State private var progress: Double = 0
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            VStack(spacing: 30) {
                Text("🧠 Auto-Optimize")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if optimized {
                    VStack(spacing: 16) {
                        Text("✅").font(.system(size: 60))
                        Text("Optimization Complete!")
                            .font(.system(size: 20, weight: .bold)).foregroundColor(.natureDark)
                        Text("We've analyzed your layout and added the most important missing elements to improve efficiency.")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center)
                        Button {
                            dismiss.wrappedValue.dismiss()
                        } label: {
                            Text("View Updated Layout")
                                .font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(LinearGradient.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                } else if isOptimizing {
                    VStack(spacing: 16) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .techBlue))
                        Text("Analyzing layout... \(Int(progress * 100))%")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("The optimizer will:")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                        ForEach(["Add missing nest boxes", "Ensure adequate feeders and waterers", "Add ventilation if missing", "Suggest lighting improvements"], id: \.self) { action in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.techBlue)
                                Text(action).font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                        }
                    }
                    .padding(20).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Button {
                        runOptimization()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "wand.and.stars")
                            Text("Start Optimization")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.bgPrimary)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LinearGradient.techGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(24)
        }
    }
    
    func runOptimization() {
        isOptimizing = true
        withAnimation(.linear(duration: 2.5)) {
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Add missing elements
            if project.nestBoxCount < project.recommendedNestBoxes {
                let toAdd = project.recommendedNestBoxes - project.nestBoxCount
                for i in 0..<toAdd {
                    let el = LayoutElement(type: .nestBox, gridX: i * 2, gridY: 0, width: 2, height: 2, label: "Auto Nest Box \(i+1)")
                    projectStore.addElement(el, to: project.id)
                }
            }
            if project.feederCount < project.recommendedFeeders {
                let el = LayoutElement(type: .feeder, gridX: 0, gridY: 4, width: 1, height: 1, label: "Auto Feeder")
                projectStore.addElement(el, to: project.id)
            }
            if !project.elements.contains(where: { $0.type == .ventFan || $0.type == .window }) {
                let el = LayoutElement(type: .ventFan, gridX: 5, gridY: 0, width: 1, height: 1, label: "Auto Vent Fan")
                projectStore.addElement(el, to: project.id)
            }
            if !project.elements.contains(where: { $0.type == .light }) {
                let el = LayoutElement(type: .light, gridX: 3, gridY: 3, width: 1, height: 1, label: "Auto Light")
                projectStore.addElement(el, to: project.id)
            }
            isOptimizing = false
            optimized = true
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @Binding var project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingAdd = false
    @State private var filterCategory: CoopTask.TaskCategory? = nil
    
    var currentProject: CoopProject {
        projectStore.projects.first { $0.id == project.id } ?? project
    }
    
    var filteredTasks: [CoopTask] {
        if let cat = filterCategory {
            return currentProject.tasks.filter { $0.category == cat }
        }
        return currentProject.tasks
    }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                // Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: filterCategory == nil) { filterCategory = nil }
                        ForEach(CoopTask.TaskCategory.allCases, id: \.self) { cat in
                            FilterChip(label: cat.rawValue, isSelected: filterCategory == cat) { filterCategory = cat }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                .background(Color.bgSecondary)
                
                if filteredTasks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("📋").font(.system(size: 50))
                        Text("No tasks yet").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        Text("Add maintenance tasks and reminders").font(.system(size: 14)).foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredTasks) { task in
                                TaskRowView(task: task, projectId: currentProject.id)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.sunYellow)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTaskView(projectId: currentProject.id)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .bgPrimary : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(isSelected ? Color.sunYellow : Color.cardBg)
                .clipShape(Capsule())
        }
    }
}

struct TaskRowView: View {
    let task: CoopTask
    let projectId: UUID
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingDelete = false
    
    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    projectStore.toggleTask(task.id, in: projectId)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .natureDark : .white.opacity(0.3))
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                    .opacity(task.isCompleted ? 0.5 : 1)
                HStack(spacing: 6) {
                    Image(systemName: task.category.icon).font(.system(size: 10))
                    Text(task.category.rawValue).font(.system(size: 11))
                    if let due = task.dueDate {
                        Text("·")
                        Text(due, style: .date).font(.system(size: 11))
                            .foregroundColor(due < Date() && !task.isCompleted ? .alertRed : .white.opacity(0.4))
                    }
                }
                .foregroundColor(task.category.color.opacity(0.8))
            }
            Spacer()
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                projectStore.deleteTask(task.id, from: projectId)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct AddTaskView: View {
    let projectId: UUID
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.presentationMode) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var category: CoopTask.TaskCategory = .maintenance
    @State private var priority: CoopTask.TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 3600)
    @State private var error = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Task Title") {
                            GCTextField(text: $title, placeholder: "e.g. Clean nest boxes", icon: "checklist")
                        }
                        FormSection(title: "Notes") {
                            GCTextField(text: $notes, placeholder: "Optional notes", icon: "note.text")
                        }
                        FormSection(title: "Category") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(CoopTask.TaskCategory.allCases, id: \.self) { cat in
                                        Button {
                                            category = cat
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: cat.icon).font(.system(size: 11))
                                                Text(cat.rawValue).font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(category == cat ? .bgPrimary : .white.opacity(0.6))
                                            .padding(.horizontal, 12).frame(height: 34)
                                            .background(category == cat ? cat.color : Color.cardBg)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        FormSection(title: "Priority") {
                            HStack(spacing: 8) {
                                ForEach(CoopTask.TaskPriority.allCases, id: \.self) { p in
                                    Button {
                                        priority = p
                                    } label: {
                                        Text(p.rawValue).font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(priority == p ? .bgPrimary : .white.opacity(0.6))
                                            .frame(maxWidth: .infinity).frame(height: 36)
                                            .background(priority == p ? p.color : Color.cardBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                            }
                        }
                        FormSection(title: "Due Date") {
                            VStack(spacing: 10) {
                                Toggle("Set Due Date", isOn: $hasDueDate)
                                    .toggleStyle(SwitchToggleStyle(tint: .sunYellow))
                                    .foregroundColor(.white)
                                if hasDueDate {
                                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                        .colorScheme(.dark)
                                        .accentColor(.sunYellow)
                                }
                            }
                        }
                        if !error.isEmpty {
                            Text(error).foregroundColor(.alertRed).font(.system(size: 13)).padding(.horizontal, 18)
                        }
                        Button {
                            guard !title.isEmpty else { error = "Please enter a task title."; return }
                            let task = CoopTask(
                                title: title, notes: notes, dueDate: hasDueDate ? dueDate : nil,
                                isCompleted: false, category: category, priority: priority
                            )
                            projectStore.addTask(task, to: projectId)
                            dismiss.wrappedValue.dismiss()
                        } label: {
                            Text("Add Task").font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(LinearGradient.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 18).padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Notes View
struct NotesListView: View {
    @EnvironmentObject var notesStore: NotesStore
    @State private var showingAdd = false
    @State private var search = ""
    
    var filtered: [CoopNote] {
        var notes = notesStore.notes
        if !search.isEmpty { notes = notes.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.body.localizedCaseInsensitiveContains(search) } }
        return notes.sorted { $0.isPinned && !$1.isPinned }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notes").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Text("\(notesStore.notes.count) notes").font(.system(size: 13)).foregroundColor(.white.opacity(0.45))
                        }
                        Spacer()
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus").font(.system(size: 17, weight: .bold)).foregroundColor(.bgPrimary)
                                .frame(width: 40, height: 40).background(LinearGradient.accentGradient).clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 12)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
                        TextField("Search notes...", text: $search).foregroundColor(.white)
                    }
                    .padding(.horizontal, 14).frame(height: 44).background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 18).padding(.bottom, 12)
                    
                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("📝").font(.system(size: 50))
                            Text("No Notes").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { note in
                                    NoteCard(note: note)
                                }
                            }
                            .padding(.horizontal, 18).padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddNoteView()
            }
        }
    }
}

struct NoteCard: View {
    let note: CoopNote
    @EnvironmentObject var notesStore: NotesStore
    @State private var showingEdit = false
    
    var body: some View {
        Button { showingEdit = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if note.isPinned {
                        Image(systemName: "pin.fill").foregroundColor(.sunYellow).font(.system(size: 12))
                    }
                    Text(note.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Text(note.updatedAt, style: .date).font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                }
                if !note.body.isEmpty {
                    Text(note.body).font(.system(size: 13)).foregroundColor(.white.opacity(0.55)).lineLimit(3).lineSpacing(2)
                }
                if !note.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)").font(.system(size: 11, weight: .medium)).foregroundColor(.techBlue)
                                .padding(.horizontal, 8).padding(.vertical, 3).background(Color.techBlue.opacity(0.1)).clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(14).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button { notesStore.togglePin(note) } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
            }
            Button(role: .destructive) { notesStore.delete(note) } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditNoteView(note: note)
        }
    }
}

struct AddNoteView: View {
    @EnvironmentObject var notesStore: NotesStore
    @Environment(\.presentationMode) var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tagsText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 16) {
                    GCTextField(text: $title, placeholder: "Note title", icon: "note.text")
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bodyText)
                            .foregroundColor(.white).colorScheme(.dark).frame(minHeight: 160).scrollContentBackground(.hidden)
                        if bodyText.isEmpty {
                            Text("Write your note here...").foregroundColor(.white.opacity(0.3)).padding(.top, 8).padding(.leading, 4).allowsHitTesting(false)
                        }
                    }
                    .padding(14).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    GCTextField(text: $tagsText, placeholder: "Tags (comma separated)", icon: "tag.fill")
                    Button {
                        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        let note = CoopNote(title: title.isEmpty ? "Untitled" : title, body: bodyText, createdAt: Date(), updatedAt: Date(), tags: tags)
                        notesStore.add(note)
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Text("Save Note").font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                            .frame(maxWidth: .infinity).frame(height: 52).background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Spacer()
                }
                .padding(18).padding(.top, 8)
            }
            .navigationTitle("New Note").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

struct EditNoteView: View {
    let note: CoopNote
    @EnvironmentObject var notesStore: NotesStore
    @Environment(\.presentationMode) var dismiss
    @State private var title: String
    @State private var bodyText: String
    @State private var tagsText: String
    
    init(note: CoopNote) {
        self.note = note
        _title = State(initialValue: note.title)
        _bodyText = State(initialValue: note.body)
        _tagsText = State(initialValue: note.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 16) {
                    GCTextField(text: $title, placeholder: "Note title", icon: "note.text")
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bodyText)
                            .foregroundColor(.white).colorScheme(.dark).frame(minHeight: 160).scrollContentBackground(.hidden)
                    }
                    .padding(14).background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    GCTextField(text: $tagsText, placeholder: "Tags (comma separated)", icon: "tag.fill")
                    Button {
                        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        var updated = note
                        updated.title = title.isEmpty ? "Untitled" : title
                        updated.body = bodyText
                        updated.tags = tags
                        updated.updatedAt = Date()
                        notesStore.update(updated)
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Text("Save Changes").font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                            .frame(maxWidth: .infinity).frame(height: 52).background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Spacer()
                }
                .padding(18).padding(.top, 8)
            }
            .navigationTitle("Edit Note").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Budget Tracker
struct BudgetTrackerView: View {
    @EnvironmentObject var budgetStore: BudgetStore
    @State private var showingAdd = false
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Summary
                    HStack(spacing: 12) {
                        BudgetSummaryCard(title: "Expenses", value: budgetStore.totalExpenses, color: .alertRed)
                        BudgetSummaryCard(title: "Income", value: budgetStore.totalIncome, color: .natureDark)
                        BudgetSummaryCard(title: "Balance", value: budgetStore.balance, color: budgetStore.balance >= 0 ? .techBlue : .alertRed)
                    }
                    .padding(.horizontal, 18)
                    
                    if budgetStore.items.isEmpty {
                        VStack(spacing: 12) {
                            Text("💸").font(.system(size: 50))
                            Text("No transactions yet").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        }
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(budgetStore.items.sorted { $0.date > $1.date }) { item in
                                BudgetItemRow(item: item)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Budget Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.sunYellow)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddBudgetItemView()
        }
    }
}

struct BudgetSummaryCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("$\(String(format: "%.0f", abs(value)))")
                .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct BudgetItemRow: View {
    let item: BudgetItem
    @EnvironmentObject var budgetStore: BudgetStore
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(item.isExpense ? Color.alertRed.opacity(0.15) : Color.natureDark.opacity(0.15)).frame(width: 38, height: 38)
                Image(systemName: item.category.icon).foregroundColor(item.isExpense ? .alertRed : .natureDark).font(.system(size: 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.description).font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                Text(item.category.rawValue + " · " + item.date.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text((item.isExpense ? "-" : "+") + "$\(String(format: "%.2f", item.amount))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(item.isExpense ? .alertRed : .natureDark)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.cardBg).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { budgetStore.delete(item) } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct AddBudgetItemView: View {
    @EnvironmentObject var budgetStore: BudgetStore
    @Environment(\.presentationMode) var dismiss
    @State private var description = ""
    @State private var amount = ""
    @State private var category: BudgetItem.BudgetCategory = .materials
    @State private var isExpense = true
    @State private var date = Date()
    @State private var error = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FormSection(title: "Description") {
                            GCTextField(text: $description, placeholder: "e.g. Lumber for walls", icon: "tag.fill")
                        }
                        FormSection(title: "Amount ($)") {
                            GCTextField(text: $amount, placeholder: "0.00", icon: "dollarsign.circle.fill", keyboardType: .decimalPad)
                        }
                        FormSection(title: "Type") {
                            HStack(spacing: 10) {
                                Button { isExpense = true } label: {
                                    Text("Expense").font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isExpense ? .bgPrimary : .white.opacity(0.6))
                                        .frame(maxWidth: .infinity).frame(height: 40)
                                        .background(isExpense ? Color.alertRed : Color.cardBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                Button { isExpense = false } label: {
                                    Text("Income").font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(!isExpense ? .bgPrimary : .white.opacity(0.6))
                                        .frame(maxWidth: .infinity).frame(height: 40)
                                        .background(!isExpense ? Color.natureDark : Color.cardBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        FormSection(title: "Category") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(BudgetItem.BudgetCategory.allCases, id: \.self) { cat in
                                        Button { category = cat } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: cat.icon).font(.system(size: 11))
                                                Text(cat.rawValue).font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(category == cat ? .bgPrimary : .white.opacity(0.6))
                                            .padding(.horizontal, 12).frame(height: 34)
                                            .background(category == cat ? Color.woodLight : Color.cardBg)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        FormSection(title: "Date") {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .colorScheme(.dark).accentColor(.sunYellow).labelsHidden()
                        }
                        if !error.isEmpty {
                            Text(error).foregroundColor(.alertRed).font(.system(size: 13)).padding(.horizontal, 18)
                        }
                        Button {
                            guard !description.isEmpty else { error = "Please add a description."; return }
                            guard let amt = Double(amount), amt > 0 else { error = "Please enter a valid amount."; return }
                            let item = BudgetItem(description: description, amount: amt, category: category, date: date, isExpense: isExpense)
                            budgetStore.add(item)
                            dismiss.wrappedValue.dismiss()
                        } label: {
                            Text("Add Transaction").font(.system(size: 16, weight: .bold)).foregroundColor(.bgPrimary)
                                .frame(maxWidth: .infinity).frame(height: 52).background(LinearGradient.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal, 18).padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Transaction").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}
