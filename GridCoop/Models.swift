import SwiftUI
import Foundation

// MARK: - Color Palette
extension Color {
    // Primary (Wood)
    static let woodDark     = Color(hex: "#8B5E3C")
    static let woodMid      = Color(hex: "#A47148")
    static let woodLight    = Color(hex: "#C08A5A")
    
    // Accent (Sun)
    static let sunYellow    = Color(hex: "#FFC933")
    static let sunLight     = Color(hex: "#FFD95A")
    
    // Nature (Green)
    static let natureDark   = Color(hex: "#4CAF50")
    static let natureLight  = Color(hex: "#6BCB77")
    
    // Technical (Blue)
    static let techBlue     = Color(hex: "#4DA6FF")
    static let techLight    = Color(hex: "#7CC4FF")
    
    // Alert
    static let alertRed     = Color(hex: "#FF6B6B")
    static let alertLight   = Color(hex: "#FF8787")
    
    // Backgrounds
    static let bgPrimary    = Color(hex: "#1E1E24")
    static let bgSecondary  = Color(hex: "#262630")
    static let bgTertiary   = Color(hex: "#2F2F3A")
    static let cardBg       = Color(hex: "#343444")
    static let cardBgLight  = Color(hex: "#3F3F52")
    
    // Grid
    static let gridLine     = Color(hex: "#3A3A50").opacity(0.3)

    // MARK: - GC-prefixed aliases (used throughout views)
    static let gcWood           = Color(hex: "#A47148")
    static let gcWoodDark       = Color(hex: "#8B5E3C")
    static let gcWoodLight      = Color(hex: "#C08A5A")
    static let gcSun            = Color(hex: "#FFC933")
    static let gcSunLight       = Color(hex: "#FFD95A")
    static let gcNature         = Color(hex: "#4CAF50")
    static let gcNatureLight    = Color(hex: "#6BCB77")
    static let gcTech           = Color(hex: "#4DA6FF")
    static let gcTechLight      = Color(hex: "#7CC4FF")
    static let gcAlert          = Color(hex: "#FF6B6B")
    static let gcAlertLight     = Color(hex: "#FF8787")
    static let gcBackground     = Color(hex: "#1E1E24")
    static let gcBackgroundSecondary = Color(hex: "#262630")
    static let gcBackgroundTertiary  = Color(hex: "#2F2F3A")
    static let gcCard           = Color(hex: "#343444")
    static let gcCardLight      = Color(hex: "#3F3F52")
    static let gcGridLine       = Color(hex: "#3A3A50").opacity(0.3)
    static let gcTextPrimary    = Color.white
    static let gcTextSecondary  = Color.white.opacity(0.55)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let woodGradient = LinearGradient(colors: [.woodDark, .woodLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let accentGradient = LinearGradient(colors: [.sunYellow, Color(hex: "#FF9F5A")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let techGradient = LinearGradient(colors: [.techBlue, Color(hex: "#5B4BFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let natureGradient = LinearGradient(colors: [.natureDark, .natureLight], startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Bird Type
enum BirdType: String, CaseIterable, Codable {
    case chicken = "Chicken"
    case duck = "Duck"
    case turkey = "Turkey"
    case quail = "Quail"
    case goose = "Goose"
    
    var icon: String {
        switch self {
        case .chicken: return "🐔"
        case .duck: return "🦆"
        case .turkey: return "🦃"
        case .quail: return "🐦"
        case .goose: return "🪿"
        }
    }
    
    var spacePerBird: Double { // sq meters
        switch self {
        case .chicken: return 0.37
        case .duck: return 0.5
        case .turkey: return 1.0
        case .quail: return 0.1
        case .goose: return 0.75
        }
    }
    
    var ventilationPerBird: Double { // CFM
        switch self {
        case .chicken: return 0.5
        case .duck: return 0.7
        case .turkey: return 1.2
        case .quail: return 0.2
        case .goose: return 1.0
        }
    }
    
    var lightHoursNeeded: Double {
        switch self {
        case .chicken: return 14.0
        case .duck: return 12.0
        case .turkey: return 14.0
        case .quail: return 16.0
        case .goose: return 12.0
        }
    }
}

// MARK: - Coop Goal
enum CoopGoal: String, CaseIterable, Codable {
    case eggs = "Egg Production"
    case meat = "Meat Production"
    case breeding = "Breeding"
    case hobby = "Hobby Farm"
    
    var icon: String {
        switch self {
        case .eggs: return "🥚"
        case .meat: return "🍗"
        case .breeding: return "🐣"
        case .hobby: return "🌾"
        }
    }
}

// MARK: - Element Type
enum ElementType: String, CaseIterable, Codable {
    case nestBox = "Nest Box"
    case feeder = "Feeder"
    case waterer = "Waterer"
    case roost = "Roost"
    case dustBath = "Dust Bath"
    case door = "Door"
    case window = "Window"
    case wall = "Wall"
    case yard = "Yard Zone"
    case light = "Light"
    case ventFan = "Vent Fan"
    
    var icon: String {
        switch self {
        case .nestBox: return "🪺"
        case .feeder: return "🌾"
        case .waterer: return "💧"
        case .roost: return "📏"
        case .dustBath: return "🌿"
        case .door: return "🚪"
        case .window: return "🪟"
        case .wall: return "🧱"
        case .yard: return "🌳"
        case .light: return "💡"
        case .ventFan: return "💨"
        }
    }
    
    var color: Color {
        switch self {
        case .nestBox: return .sunYellow
        case .feeder, .waterer, .dustBath: return .natureDark
        case .roost: return .woodMid
        case .door, .window, .wall: return .woodDark
        case .yard: return .natureLight
        case .light: return .sunLight
        case .ventFan: return .techBlue
        }
    }
    
    var defaultSize: CGSize {
        switch self {
        case .nestBox: return CGSize(width: 2, height: 2)
        case .feeder: return CGSize(width: 1, height: 1)
        case .waterer: return CGSize(width: 1, height: 1)
        case .roost: return CGSize(width: 4, height: 1)
        case .dustBath: return CGSize(width: 2, height: 2)
        case .door: return CGSize(width: 1, height: 2)
        case .window: return CGSize(width: 2, height: 1)
        case .wall: return CGSize(width: 4, height: 1)
        case .yard: return CGSize(width: 4, height: 4)
        case .light: return CGSize(width: 1, height: 1)
        case .ventFan: return CGSize(width: 1, height: 1)
        }
    }
    
    var capacityPerUnit: Int {
        switch self {
        case .nestBox: return 4
        case .feeder: return 10
        case .waterer: return 15
        case .roost: return 6
        default: return 0
        }
    }
}

// MARK: - Layout Element
struct LayoutElement: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: ElementType
    var gridX: Int
    var gridY: Int
    var width: Int
    var height: Int
    var label: String
    var notes: String = ""
    var rotation: Double = 0
    
    var gridRect: CGRect {
        CGRect(x: gridX, y: gridY, width: width, height: height)
    }
}

// MARK: - Project
struct CoopProject: Identifiable, Codable {
    var id = UUID()
    var name: String
    var birdType: BirdType
    var birdCount: Int
    var goal: CoopGoal
    var plotWidth: Double  // meters
    var plotHeight: Double
    var elements: [LayoutElement]
    var createdAt: Date
    var updatedAt: Date
    var notes: String = ""
    var estimatedBudget: Double = 0
    var actualSpend: Double = 0
    var tasks: [CoopTask] = []
    var environmentData: EnvironmentData?
    
    var totalArea: Double { plotWidth * plotHeight }
    
    var requiredSpace: Double {
        Double(birdCount) * birdType.spacePerBird
    }
    
    var spaceStatus: SpaceStatus {
        let ratio = totalArea / requiredSpace
        if ratio >= 1.5 { return .optimal }
        if ratio >= 1.0 { return .adequate }
        return .cramped
    }
    
    var nestBoxCount: Int { elements.filter { $0.type == .nestBox }.count }
    var feederCount: Int { elements.filter { $0.type == .feeder }.count }
    var watererCount: Int { elements.filter { $0.type == .waterer }.count }
    
    var recommendedNestBoxes: Int { max(1, birdCount / 4) }
    var recommendedFeeders: Int { max(1, birdCount / 10) }
    var recommendedWaterers: Int { max(1, birdCount / 15) }
    
    var efficiencyScore: Int {
        var score = 0
        // Space
        switch spaceStatus {
        case .optimal: score += 40
        case .adequate: score += 25
        case .cramped: score += 0
        }
        // Nest boxes
        if nestBoxCount >= recommendedNestBoxes { score += 20 }
        else { score += Int(20 * Double(nestBoxCount) / Double(recommendedNestBoxes)) }
        // Feeders
        if feederCount >= recommendedFeeders { score += 15 }
        else { score += Int(15 * Double(feederCount) / Double(recommendedFeeders)) }
        // Waterers
        if watererCount >= recommendedWaterers { score += 15 }
        else { score += Int(15 * Double(watererCount) / Double(recommendedWaterers)) }
        // Ventilation
        let hasVent = elements.contains { $0.type == .ventFan || $0.type == .window }
        if hasVent { score += 10 }
        return min(100, score)
    }
    
    var comfortScore: Int {
        var score = 0
        let hasLight = elements.contains { $0.type == .light }
        let hasVent = elements.contains { $0.type == .ventFan || $0.type == .window }
        let hasDustBath = elements.contains { $0.type == .dustBath }
        let hasRoost = elements.contains { $0.type == .roost }
        if hasLight { score += 25 }
        if hasVent { score += 25 }
        if hasDustBath { score += 20 }
        if hasRoost { score += 20 }
        switch spaceStatus {
        case .optimal: score += 10
        case .adequate: score += 5
        case .cramped: score += 0
        }
        return min(100, score)
    }
    
    static func sampleProject() -> CoopProject {
        var p = CoopProject(
            name: "Backyard Coop",
            birdType: .chicken,
            birdCount: 12,
            goal: .eggs,
            plotWidth: 4.0,
            plotHeight: 3.0,
            elements: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        p.elements = [
            LayoutElement(type: .nestBox, gridX: 0, gridY: 0, width: 2, height: 2, label: "Nest Box A"),
            LayoutElement(type: .nestBox, gridX: 2, gridY: 0, width: 2, height: 2, label: "Nest Box B"),
            LayoutElement(type: .feeder, gridX: 1, gridY: 3, width: 1, height: 1, label: "Feeder"),
            LayoutElement(type: .waterer, gridX: 3, gridY: 3, width: 1, height: 1, label: "Waterer"),
            LayoutElement(type: .roost, gridX: 0, gridY: 5, width: 4, height: 1, label: "Main Roost"),
            LayoutElement(type: .ventFan, gridX: 3, gridY: 0, width: 1, height: 1, label: "Vent"),
            LayoutElement(type: .light, gridX: 2, gridY: 2, width: 1, height: 1, label: "Light 1"),
        ]
        p.estimatedBudget = 1500
        p.actualSpend = 820
        return p
    }
}

enum SpaceStatus {
    case optimal, adequate, cramped
    var color: Color {
        switch self {
        case .optimal: return .natureDark
        case .adequate: return .sunYellow
        case .cramped: return .alertRed
        }
    }
    var label: String {
        switch self {
        case .optimal: return "Optimal"
        case .adequate: return "Adequate"
        case .cramped: return "Too Cramped"
        }
    }
    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .adequate: return "exclamationmark.triangle.fill"
        case .cramped: return "xmark.circle.fill"
        }
    }
}

// MARK: - Environment Data
struct EnvironmentData: Codable {
    var temperature: Double = 20  // Celsius
    var humidity: Double = 60     // percent
    var climate: ClimateType = .temperate
    var annualRainfall: Double = 600  // mm
    
    var temperatureStatus: ConditionStatus {
        if temperature >= 15 && temperature <= 25 { return .good }
        if temperature >= 5 && temperature < 15 { return .warning }
        if temperature > 25 && temperature <= 32 { return .warning }
        return .critical
    }
    
    var humidityStatus: ConditionStatus {
        if humidity >= 50 && humidity <= 70 { return .good }
        if humidity >= 40 && humidity < 50 { return .warning }
        if humidity > 70 && humidity <= 80 { return .warning }
        return .critical
    }
    
    var overallStatus: ConditionStatus {
        if temperatureStatus == .critical || humidityStatus == .critical { return .critical }
        if temperatureStatus == .warning || humidityStatus == .warning { return .warning }
        return .good
    }
}

enum ClimateType: String, CaseIterable, Codable {
    case tropical = "Tropical"
    case arid = "Arid"
    case temperate = "Temperate"
    case continental = "Continental"
    case polar = "Polar"
    
    var icon: String {
        switch self {
        case .tropical: return "sun.max.fill"
        case .arid: return "thermometer.sun.fill"
        case .temperate: return "cloud.sun.fill"
        case .continental: return "wind"
        case .polar: return "snowflake"
        }
    }
}

enum ConditionStatus {
    case good, warning, critical
    var color: Color {
        switch self {
        case .good: return .natureDark
        case .warning: return .sunYellow
        case .critical: return .alertRed
        }
    }
    var label: String {
        switch self {
        case .good: return "Good"
        case .warning: return "Monitor"
        case .critical: return "Critical"
        }
    }
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
}

// MARK: - Task
struct CoopTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date?
    var isCompleted: Bool = false
    var category: TaskCategory = .maintenance
    var priority: TaskPriority = .medium
    
    enum TaskCategory: String, CaseIterable, Codable {
        case maintenance = "Maintenance"
        case cleaning = "Cleaning"
        case health = "Health"
        case feeding = "Feeding"
        case construction = "Construction"
        
        var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver.fill"
            case .cleaning: return "sparkles"
            case .health: return "cross.case.fill"
            case .feeding: return "fork.knife"
            case .construction: return "hammer.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .maintenance: return .woodMid
            case .cleaning: return .techBlue
            case .health: return .natureLight
            case .feeding: return .sunYellow
            case .construction: return .woodDark
            }
        }
    }
    
    enum TaskPriority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .natureDark
            case .medium: return .sunYellow
            case .high: return .alertRed
            }
        }
    }
}

// MARK: - Note
struct CoopNote: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
    var projectId: UUID?
    var tags: [String] = []
    var isPinned: Bool = false
}

// MARK: - Budget Item
struct BudgetItem: Identifiable, Codable {
    var id = UUID()
    var description: String
    var amount: Double
    var category: BudgetCategory
    var date: Date
    var isExpense: Bool
    
    enum BudgetCategory: String, CaseIterable, Codable {
        case materials = "Materials"
        case tools = "Tools"
        case feed = "Feed"
        case health = "Health"
        case labor = "Labor"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .materials: return "shippingbox.fill"
            case .tools: return "wrench.fill"
            case .feed: return "leaf.fill"
            case .health: return "cross.fill"
            case .labor: return "person.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String
    var email: String
    var birdCount: Int = 0
    var primaryBirdType: BirdType = .chicken
    var primaryGoal: CoopGoal = .eggs
    var setupComplete: Bool = false
    var joinDate: Date = Date()
}

// MARK: - Suggestion
struct CoopSuggestion: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var impact: ImpactLevel
    var category: SuggestionCategory
    var icon: String
    
    enum ImpactLevel: String {
        case high = "High Impact"
        case medium = "Medium Impact"
        case low = "Low Impact"
        
        var color: Color {
            switch self {
            case .high: return .alertRed
            case .medium: return .sunYellow
            case .low: return .natureDark
            }
        }
    }
    
    enum SuggestionCategory: String {
        case space = "Space"
        case ventilation = "Ventilation"
        case lighting = "Lighting"
        case feeding = "Feeding"
        case hygiene = "Hygiene"
        case comfort = "Comfort"
    }
}
