import SwiftUI
import Combine
import UserNotifications

// MARK: - App State
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appTheme") var appTheme: String = "dark" {
        didSet { objectWillChange.send() }
    }
    @Published var showSplash: Bool = true
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showSplash = false
            }
        }
    }
    
    func completeOnboarding() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("userName") var userName: String = ""
    @Published var profile: UserProfile?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    func loginDemo() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.userEmail = "demo@gridcoop.app"
            self.userName = "Demo Farmer"
            self.profile = UserProfile(name: "Demo Farmer", email: "demo@gridcoop.app", birdCount: 12, primaryBirdType: .chicken, primaryGoal: .eggs, setupComplete: true)
            self.isLoggedIn = true
            self.isLoading = false
        }
    }
    
    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email."
            return
        }
        isLoading = true
        errorMessage = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.userEmail = email
            self.userName = email.components(separatedBy: "@").first?.capitalized ?? "Farmer"
            self.profile = UserProfile(name: self.userName, email: email, setupComplete: false)
            self.isLoggedIn = true
            self.isLoading = false
        }
    }
    
    func register(name: String, email: String, password: String) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.userEmail = email
            self.userName = name
            self.profile = UserProfile(name: name, email: email, setupComplete: false)
            self.isLoggedIn = true
            self.isLoading = false
        }
    }
    
    func logout() {
        isLoggedIn = false
        userEmail = ""
        userName = ""
        profile = nil
    }
    
    func deleteAccount() {
        logout()
    }
    
    func saveSetup(birdCount: Int, birdType: BirdType, goal: CoopGoal) {
        profile?.birdCount = birdCount
        profile?.primaryBirdType = birdType
        profile?.primaryGoal = goal
        profile?.setupComplete = true
    }
}

// MARK: - Project Store
class ProjectStore: ObservableObject {
    @Published var projects: [CoopProject] = []
    @Published var selectedProject: CoopProject?
    
    private let storageKey = "coopProjects"
    
    init() {
        load()
        if projects.isEmpty {
            projects = [CoopProject.sampleProject()]
            save()
        }
    }
    
    func addProject(_ project: CoopProject) {
        projects.insert(project, at: 0)
        save()
    }
    
    func updateProject(_ project: CoopProject) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            if selectedProject?.id == project.id {
                selectedProject = project
            }
            save()
        }
    }
    
    func deleteProject(_ project: CoopProject) {
        projects.removeAll { $0.id == project.id }
        if selectedProject?.id == project.id {
            selectedProject = projects.first
        }
        save()
    }
    
    func addElement(_ element: LayoutElement, to projectId: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[idx].elements.append(element)
            projects[idx].updatedAt = Date()
            if selectedProject?.id == projectId {
                selectedProject = projects[idx]
            }
            save()
        }
    }
    
    func updateElement(_ element: LayoutElement, in projectId: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectId }),
           let eIdx = projects[pIdx].elements.firstIndex(where: { $0.id == element.id }) {
            projects[pIdx].elements[eIdx] = element
            projects[pIdx].updatedAt = Date()
            if selectedProject?.id == projectId {
                selectedProject = projects[pIdx]
            }
            save()
        }
    }
    
    func deleteElement(_ elementId: UUID, from projectId: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[pIdx].elements.removeAll { $0.id == elementId }
            projects[pIdx].updatedAt = Date()
            if selectedProject?.id == projectId {
                selectedProject = projects[pIdx]
            }
            save()
        }
    }
    
    func addTask(_ task: CoopTask, to projectId: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[idx].tasks.append(task)
            save()
        }
    }
    
    func toggleTask(_ taskId: UUID, in projectId: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectId }),
           let tIdx = projects[pIdx].tasks.firstIndex(where: { $0.id == taskId }) {
            projects[pIdx].tasks[tIdx].isCompleted.toggle()
            save()
        }
    }
    
    func deleteTask(_ taskId: UUID, from projectId: UUID) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectId }) {
            projects[pIdx].tasks.removeAll { $0.id == taskId }
            save()
        }
    }
    
    func addBudgetItem(_ item: BudgetItem, to projectId: UUID) {
        // Budget items stored in project notes for simplicity
        save()
    }
    
    func saveProjects() {
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CoopProject].self, from: data) {
            projects = decoded
        }
    }
    
    // Suggestions for a project
    func suggestions(for project: CoopProject) -> [CoopSuggestion] {
        var suggestions: [CoopSuggestion] = []
        
        if project.spaceStatus == .cramped {
            suggestions.append(CoopSuggestion(title: "Increase Space", description: "Your birds need more room. Current space is \(String(format: "%.1f", project.totalArea)) m², but \(String(format: "%.1f", project.requiredSpace)) m² is required.", impact: .high, category: .space, icon: "arrow.up.left.and.arrow.down.right"))
        }
        
        if project.nestBoxCount < project.recommendedNestBoxes {
            suggestions.append(CoopSuggestion(title: "Add More Nest Boxes", description: "You have \(project.nestBoxCount) nest boxes but need \(project.recommendedNestBoxes) for \(project.birdCount) birds.", impact: .high, category: .comfort, icon: "square.stack.3d.up.fill"))
        }
        
        if !project.elements.contains(where: { $0.type == .ventFan || $0.type == .window }) {
            suggestions.append(CoopSuggestion(title: "Add Ventilation", description: "No ventilation detected. Poor air quality can cause respiratory disease in birds.", impact: .high, category: .ventilation, icon: "wind"))
        }
        
        if !project.elements.contains(where: { $0.type == .light }) {
            suggestions.append(CoopSuggestion(title: "Install Lighting", description: "\(project.birdType.rawValue)s need \(Int(project.birdType.lightHoursNeeded)) hours of light daily for optimal production.", impact: .medium, category: .lighting, icon: "lightbulb.fill"))
        }
        
        if project.feederCount < project.recommendedFeeders {
            suggestions.append(CoopSuggestion(title: "Add Feeders", description: "You need at least \(project.recommendedFeeders) feeder(s) for \(project.birdCount) birds.", impact: .medium, category: .feeding, icon: "leaf.fill"))
        }
        
        if !project.elements.contains(where: { $0.type == .dustBath }) {
            suggestions.append(CoopSuggestion(title: "Add Dust Bath Area", description: "Dust bathing is essential for birds' feather and skin health.", impact: .low, category: .hygiene, icon: "cloud.fill"))
        }
        
        if !project.elements.contains(where: { $0.type == .roost }) {
            suggestions.append(CoopSuggestion(title: "Add Roost Bars", description: "Birds need elevated roost bars for sleeping. This reduces stress and improves health.", impact: .medium, category: .comfort, icon: "minus"))
        }
        
        return suggestions
    }
    
    // Ventilation calculation
    func ventilationRequired(for project: CoopProject) -> Double {
        Double(project.birdCount) * project.birdType.ventilationPerBird
    }
    
    func ventilationProvided(for project: CoopProject) -> Double {
        let fans = project.elements.filter { $0.type == .ventFan }.count
        let windows = project.elements.filter { $0.type == .window }.count
        return Double(fans) * 50.0 + Double(windows) * 20.0 // CFM
    }
    
    // Max capacity
    func maxCapacity(for project: CoopProject) -> Int {
        Int(project.totalArea / project.birdType.spacePerBird)
    }
    
    // Cost estimate
    func estimateCost(for project: CoopProject) -> Double {
        var cost = project.totalArea * 80.0 // base per sqm
        cost += Double(project.elements.filter { $0.type == .nestBox }.count) * 45.0
        cost += Double(project.elements.filter { $0.type == .feeder }.count) * 25.0
        cost += Double(project.elements.filter { $0.type == .waterer }.count) * 30.0
        cost += Double(project.elements.filter { $0.type == .ventFan }.count) * 120.0
        cost += Double(project.elements.filter { $0.type == .light }.count) * 35.0
        cost += Double(project.elements.filter { $0.type == .roost }.count) * 20.0
        return cost
    }
}

// MARK: - Environment Store
class EnvironmentStore: ObservableObject {
    @Published var environmentData = EnvironmentData()
    
    @AppStorage("envTemperature") var storedTemp: Double = 20.0
    @AppStorage("envHumidity") var storedHumidity: Double = 60.0
    @AppStorage("envClimate") var storedClimate: String = "Temperate"
    
    init() {
        environmentData.temperature = storedTemp
        environmentData.humidity = storedHumidity
        environmentData.climate = ClimateType(rawValue: storedClimate) ?? .temperate
    }
    
    func save() {
        storedTemp = environmentData.temperature
        storedHumidity = environmentData.humidity
        storedClimate = environmentData.climate.rawValue
    }
}

// MARK: - Notes Store
class NotesStore: ObservableObject {
    @Published var notes: [CoopNote] = []
    private let key = "coopNotes"
    
    init() { load() }
    
    func add(_ note: CoopNote) {
        notes.insert(note, at: 0)
        save()
    }
    
    func update(_ note: CoopNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            save()
        }
    }
    
    func delete(_ note: CoopNote) {
        notes.removeAll { $0.id == note.id }
        save()
    }
    
    func togglePin(_ note: CoopNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isPinned.toggle()
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([CoopNote].self, from: data) {
            notes = decoded
        }
    }
}

// MARK: - Budget Store
class BudgetStore: ObservableObject {
    @Published var items: [BudgetItem] = []
    private let key = "budgetItems"
    
    init() { load() }
    
    func add(_ item: BudgetItem) {
        items.append(item)
        save()
    }
    
    func delete(_ item: BudgetItem) {
        items.removeAll { $0.id == item.id }
        save()
    }
    
    var totalExpenses: Double { items.filter { $0.isExpense }.reduce(0) { $0 + $1.amount } }
    var totalIncome: Double { items.filter { !$0.isExpense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { totalIncome - totalExpenses }
    
    func expensesByCategory() -> [BudgetItem.BudgetCategory: Double] {
        var result: [BudgetItem.BudgetCategory: Double] = [:]
        for item in items where item.isExpense {
            result[item.category, default: 0] += item.amount
        }
        return result
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([BudgetItem].self, from: data) {
            items = decoded
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("maintenanceReminders") var maintenanceReminders: Bool = true
    @AppStorage("feedingReminders") var feedingReminders: Bool = true
    @AppStorage("dailyTipEnabled") var dailyTipEnabled: Bool = false
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                completion(granted)
                if granted { self.scheduleInitialNotifications() }
            }
        }
    }
    
    func scheduleInitialNotifications() {
        if maintenanceReminders {
            scheduleMaintenance()
        }
        if feedingReminders {
            scheduleFeeding()
        }
        if dailyTipEnabled {
            scheduleDailyTip()
        }
    }
    
    func scheduleMaintenance() {
        let content = UNMutableNotificationContent()
        content.title = "🐔 Coop Maintenance"
        content.body = "Time for weekly coop cleaning and inspection!"
        content.sound = .default
        var comps = DateComponents()
        comps.weekday = 2; comps.hour = 9; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "maintenance", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleFeeding() {
        let content = UNMutableNotificationContent()
        content.title = "🌾 Feeding Time"
        content.body = "Don't forget to check feed and water levels!"
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 7; comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "feeding", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDailyTip() {
        let tips = ["Ensure fresh water is always available.", "Check for signs of mites weekly.", "Collect eggs at least twice daily.", "Keep the coop dry to prevent disease."]
        let content = UNMutableNotificationContent()
        content.title = "💡 Daily Tip"
        content.body = tips.randomElement() ?? tips[0]
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 8; comps.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyTip", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func updateMaintenanceReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["maintenance"])
        if maintenanceReminders && notificationsEnabled { scheduleMaintenance() }
    }
    
    func updateFeedingReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["feeding"])
        if feedingReminders && notificationsEnabled { scheduleFeeding() }
    }
    
    func updateDailyTip() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyTip"])
        if dailyTipEnabled && notificationsEnabled { scheduleDailyTip() }
    }
}
