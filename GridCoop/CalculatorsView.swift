import SwiftUI

// MARK: - Calculators Hub
struct CalculatorsHubView: View {
    @EnvironmentObject var projectStore: ProjectStore
    
    let project: CoopProject? = nil
    
    var currentProject: CoopProject? { projectStore.projects.first }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calculators")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Smart tools for your coop")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        
                        if let p = currentProject {
                            // Live stats from current project
                            VStack(alignment: .leading, spacing: 10) {
                                Text("📊 Current Project: \(p.name)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 18)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        LiveStatCard(title: "Space", value: "\(String(format: "%.0f", p.totalArea))m²", subtitle: "Need \(String(format: "%.0f", p.requiredSpace))m²", color: p.spaceStatus.color)
                                        LiveStatCard(title: "Max Birds", value: "\(projectStore.maxCapacity(for: p))", subtitle: "Currently \(p.birdCount)", color: .techBlue)
                                        LiveStatCard(title: "Ventilation", value: "\(Int(projectStore.ventilationProvided(for: p))) CFM", subtitle: "Need \(Int(projectStore.ventilationRequired(for: p))) CFM", color: projectStore.ventilationProvided(for: p) >= projectStore.ventilationRequired(for: p) ? .natureDark : .alertRed)
                                        LiveStatCard(title: "Light", value: "\(Int(p.birdType.lightHoursNeeded))h/day", subtitle: "Required", color: .sunYellow)
                                    }
                                    .padding(.horizontal, 18)
                                }
                            }
                        }
                        
                        // Calculator Cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            if let p = currentProject {
                                NavigationLink(destination: SpaceCalculatorView(project: p)) {
                                    CalcCard(icon: "square.dashed", title: "Space\nCalculator", color: .techBlue, description: "Check if area is sufficient")
                                }
                                NavigationLink(destination: CapacityAnalyzerView(project: p)) {
                                    CalcCard(icon: "person.3.fill", title: "Capacity\nAnalyzer", color: .sunYellow, description: "Max bird count")
                                }
                                NavigationLink(destination: VentilationCalculatorView(project: p)) {
                                    CalcCard(icon: "wind", title: "Ventilation\nCalc", color: .natureDark, description: "Airflow requirements")
                                }
                                NavigationLink(destination: LightCalculatorView(project: p)) {
                                    CalcCard(icon: "lightbulb.fill", title: "Light\nCalculator", color: .sunLight, description: "Daily light needs")
                                }
                                NavigationLink(destination: CostEstimatorView(project: p)) {
                                    CalcCard(icon: "dollarsign.circle.fill", title: "Cost\nEstimator", color: .woodLight, description: "Project cost estimate")
                                }
                                NavigationLink(destination: EnvironmentAnalysisView()) {
                                    CalcCard(icon: "thermometer.sun.fill", title: "Environment\nAnalysis", color: .alertLight, description: "Condition check")
                                }
                            } else {
                                Text("Create a project to use calculators")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 14))
                                    .padding(20)
                            }
                        }
                        .padding(.horizontal, 18)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct LiveStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(width: 110)
    }
}

struct CalcCard: View {
    let icon: String
    let title: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Space Calculator
struct SpaceCalculatorView: View {
    let project: CoopProject
    @State private var customBirdCount: Double
    @State private var customWidth: String
    @State private var customHeight: String
    
    init(project: CoopProject) {
        self.project = project
        self._customBirdCount = State(initialValue: Double(project.birdCount))
        self._customWidth = State(initialValue: String(format: "%.1f", project.plotWidth))
        self._customHeight = State(initialValue: String(format: "%.1f", project.plotHeight))
    }
    
    var area: Double { (Double(customWidth) ?? 0) * (Double(customHeight) ?? 0) }
    var required: Double { customBirdCount * project.birdType.spacePerBird }
    var ratio: Double { required > 0 ? area / required : 0 }
    
    var status: SpaceStatus {
        if ratio >= 1.5 { return .optimal }
        if ratio >= 1.0 { return .adequate }
        return .cramped
    }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Visual indicator
                    ZStack {
                        Circle()
                            .stroke(Color.cardBgLight, lineWidth: 12)
                            .frame(width: 160, height: 160)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(ratio) / 2.0, 1.0))
                            .stroke(status.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: ratio)
                        
                        VStack(spacing: 4) {
                            Text(status.label)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(status.color)
                            Image(systemName: status.icon)
                                .foregroundColor(status.color)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    HStack(spacing: 12) {
                        ResultCard(title: "Available", value: "\(String(format: "%.1f", area)) m²", color: .techBlue)
                        ResultCard(title: "Required", value: "\(String(format: "%.1f", required)) m²", color: .woodLight)
                        ResultCard(title: "Ratio", value: "\(String(format: "%.2f", ratio))x", color: status.color)
                    }
                    .padding(.horizontal, 18)
                    
                    // Inputs
                    VStack(spacing: 16) {
                        FormSection(title: "Bird Count: \(Int(customBirdCount))") {
                            Slider(value: $customBirdCount, in: 1...500, step: 1)
                                .accentColor(.sunYellow)
                        }
                        
                        FormSection(title: "Plot Dimensions") {
                            HStack(spacing: 12) {
                                GCTextField(text: $customWidth, placeholder: "Width (m)", icon: "arrow.left.and.right", keyboardType: .decimalPad)
                                GCTextField(text: $customHeight, placeholder: "Height (m)", icon: "arrow.up.and.down", keyboardType: .decimalPad)
                            }
                        }
                    }
                    
                    // Recommendation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Analysis")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        let message: String = {
                            switch status {
                            case .optimal: return "✅ Your coop space is excellent! Birds have \(String(format: "%.1f", area - required)) m² extra space beyond minimum requirements."
                            case .adequate: return "⚠️ Space meets minimum requirements. Consider expanding by \(String(format: "%.1f", required * 1.5 - area)) m² for optimal conditions."
                            case .cramped: return "❌ Insufficient space! You need at least \(String(format: "%.1f", required - area)) m² more. Overcrowding causes stress, disease and reduced production."
                            }
                        }()
                        
                        Text(message)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Space Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Capacity Analyzer
struct CapacityAnalyzerView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var selectedBird: BirdType
    
    init(project: CoopProject) {
        self.project = project
        self._selectedBird = State(initialValue: project.birdType)
    }
    
    var maxCapacity: Int { Int(project.totalArea / selectedBird.spacePerBird) }
    var nestBoxCapacity: Int { project.nestBoxCount * 4 }
    var feederCapacity: Int { project.feederCount * 10 }
    var watererCapacity: Int { project.watererCount * 15 }
    var bottleneck: Int { [maxCapacity, nestBoxCapacity > 0 ? nestBoxCapacity : maxCapacity, feederCapacity > 0 ? feederCapacity : maxCapacity].min() ?? maxCapacity }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Big number
                    VStack(spacing: 6) {
                        Text("\(bottleneck)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.sunYellow)
                        Text("Maximum Birds")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text("with current layout")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.top, 24)
                    
                    // Bird selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BirdType.allCases, id: \.self) { bt in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedBird = bt
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(bt.icon)
                                        Text(bt.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedBird == bt ? .bgPrimary : .white.opacity(0.7))
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(height: 36)
                                    .background(selectedBird == bt ? Color.sunYellow : Color.cardBg)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    
                    // Capacity breakdown
                    VStack(spacing: 12) {
                        CapacityRow(label: "Floor Space", capacity: maxCapacity, icon: "square.fill", color: .techBlue, note: "\(String(format: "%.2f", selectedBird.spacePerBird))m² per bird")
                        CapacityRow(label: "Nest Boxes", capacity: project.nestBoxCount > 0 ? nestBoxCapacity : 999, icon: "🪺", color: .sunYellow, note: project.nestBoxCount > 0 ? "\(project.nestBoxCount) boxes × 4 birds" : "No nest boxes", isEmoji: true, unlimited: project.nestBoxCount == 0)
                        CapacityRow(label: "Feeders", capacity: project.feederCount > 0 ? feederCapacity : 999, icon: "🌾", color: .natureDark, note: project.feederCount > 0 ? "\(project.feederCount) feeders × 10 birds" : "No feeders", isEmoji: true, unlimited: project.feederCount == 0)
                        CapacityRow(label: "Waterers", capacity: project.watererCount > 0 ? watererCapacity : 999, icon: "💧", color: .techLight, note: project.watererCount > 0 ? "\(project.watererCount) waterers × 15 birds" : "No waterers", isEmoji: true, unlimited: project.watererCount == 0)
                    }
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Capacity Analyzer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CapacityRow: View {
    let label: String
    let capacity: Int
    let icon: String
    let color: Color
    let note: String
    var isEmoji: Bool = false
    var unlimited: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                if isEmoji {
                    Text(icon).font(.system(size: 18))
                } else {
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(note)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Text(unlimited ? "∞" : "\(capacity)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(unlimited ? .white.opacity(0.3) : color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Ventilation Calculator
struct VentilationCalculatorView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var fanCount: Double
    @State private var windowCount: Double
    
    init(project: CoopProject) {
        self.project = project
        let fans = Double(project.elements.filter { $0.type == .ventFan }.count)
        let windows = Double(project.elements.filter { $0.type == .window }.count)
        self._fanCount = State(initialValue: fans)
        self._windowCount = State(initialValue: windows)
    }
    
    var required: Double { Double(project.birdCount) * project.birdType.ventilationPerBird }
    var provided: Double { fanCount * 50.0 + windowCount * 20.0 }
    var isAdequate: Bool { provided >= required }
    var ratio: Double { required > 0 ? provided / required : 0 }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Gauge
                    ZStack {
                        Circle()
                            .stroke(Color.cardBgLight, lineWidth: 14)
                            .frame(width: 170, height: 170)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(ratio / 2.0), 1.0))
                            .stroke(isAdequate ? Color.natureDark : Color.alertRed, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: ratio)
                        VStack(spacing: 2) {
                            Text("\(Int(provided))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(isAdequate ? .natureDark : .alertRed)
                            Text("CFM")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 12) {
                        ResultCard(title: "Provided", value: "\(Int(provided)) CFM", color: isAdequate ? .natureDark : .alertRed)
                        ResultCard(title: "Required", value: "\(Int(required)) CFM", color: .woodLight)
                    }
                    .padding(.horizontal, 18)
                    
                    // Controls
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("💨 Vent Fans: \(Int(fanCount))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("50 CFM each")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Slider(value: $fanCount, in: 0...20, step: 1)
                                .accentColor(.techBlue)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("🪟 Windows: \(Int(windowCount))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("20 CFM each")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Slider(value: $windowCount, in: 0...20, step: 1)
                                .accentColor(.natureDark)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    // Analysis
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isAdequate ? "✅ Adequate Ventilation" : "❌ Insufficient Ventilation")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isAdequate ? .natureDark : .alertRed)
                        Text(isAdequate
                             ? "Your ventilation provides \(Int(provided - required)) CFM above minimum. Good airflow prevents ammonia buildup and respiratory disease."
                             : "You need \(Int(required - provided)) more CFM. Add \(Int(ceil((required - provided) / 50))) fan(s) or \(Int(ceil((required - provided) / 20))) window(s).")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Ventilation Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Light Calculator
struct LightCalculatorView: View {
    let project: CoopProject
    @State private var currentDaylight: Double = 10.0
    @State private var hasSupplementalLight: Bool = false
    @State private var supplementalHours: Double = 0
    
    var neededHours: Double { project.birdType.lightHoursNeeded }
    var totalLight: Double { currentDaylight + (hasSupplementalLight ? supplementalHours : 0) }
    var isAdequate: Bool { totalLight >= neededHours }
    var lightGap: Double { max(0, neededHours - totalLight) }
    
    var season: String {
        if currentDaylight >= 14 { return "Summer ☀️" }
        if currentDaylight >= 10 { return "Spring/Fall 🌤" }
        return "Winter ❄️"
    }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Day light arc
                    ZStack {
                        Circle()
                            .stroke(Color.cardBgLight, lineWidth: 14)
                            .frame(width: 170, height: 170)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(totalLight) / 24.0, 1.0))
                            .stroke(LinearGradient.accentGradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: totalLight)
                        VStack(spacing: 2) {
                            Text("\(String(format: "%.1f", totalLight))h")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.sunYellow)
                            Text("of light")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 12) {
                        ResultCard(title: "Total Light", value: "\(String(format: "%.1f", totalLight))h", color: .sunYellow)
                        ResultCard(title: "Required", value: "\(String(format: "%.1f", neededHours))h", color: .woodLight)
                        ResultCard(title: "Gap", value: lightGap > 0 ? "\(String(format: "%.1f", lightGap))h" : "None", color: lightGap > 0 ? .alertRed : .natureDark)
                    }
                    .padding(.horizontal, 18)
                    
                    // Inputs
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("☀️ Current Daylight: \(String(format: "%.1f", currentDaylight))h")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(season)
                                    .font(.system(size: 12))
                                    .foregroundColor(.sunYellow)
                            }
                            Slider(value: $currentDaylight, in: 6...20, step: 0.5)
                                .accentColor(.sunYellow)
                        }
                        
                        Toggle(isOn: $hasSupplementalLight) {
                            Text("💡 Add Supplemental Lighting")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .sunYellow))
                        
                        if hasSupplementalLight {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Supplemental Hours: \(String(format: "%.1f", supplementalHours))h")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                Slider(value: $supplementalHours, in: 0...12, step: 0.5)
                                    .accentColor(.sunLight)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasSupplementalLight)
                    
                    // Tip
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isAdequate ? "✅ Light Requirements Met" : "⚠️ Insufficient Light")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isAdequate ? .natureDark : .sunYellow)
                        Text(isAdequate
                             ? "\(project.birdType.rawValue)s are getting enough light for optimal production."
                             : "Add \(String(format: "%.1f", lightGap)) more hours of supplemental light to meet the \(Int(neededHours))-hour minimum for \(project.birdType.rawValue)s.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Light Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Cost Estimator
struct CostEstimatorView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var budgetStore: BudgetStore
    @State private var showingAddExpense = false
    @State private var laborCost: Double = 0
    @State private var landCost: Double = 0
    
    var materialCost: Double { projectStore.estimateCost(for: project) }
    var total: Double { materialCost + laborCost + landCost }
    var costPerBird: Double { project.birdCount > 0 ? total / Double(project.birdCount) : 0 }
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Total
                    VStack(spacing: 6) {
                        Text("$\(String(format: "%.0f", total))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.sunYellow)
                        Text("Estimated Total Cost")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.55))
                        Text("$\(String(format: "%.0f", costPerBird)) per bird")
                            .font(.system(size: 13))
                            .foregroundColor(.woodLight)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 18)
                    
                    // Breakdown
                    VStack(spacing: 12) {
                        CostRow(label: "Construction & Materials", icon: "hammer.fill", amount: materialCost, color: .woodMid)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Labor Cost")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("$\(String(format: "%.0f", laborCost))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.techBlue)
                            }
                            Slider(value: $laborCost, in: 0...5000, step: 50)
                                .accentColor(.techBlue)
                        }
                        .padding(14)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Land/Site Prep")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("$\(String(format: "%.0f", landCost))")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.natureDark)
                            }
                            Slider(value: $landCost, in: 0...3000, step: 50)
                                .accentColor(.natureDark)
                        }
                        .padding(14)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 18)
                    
                    // Budget tracker link
                    NavigationLink(destination: BudgetTrackerView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.sunYellow)
                            Text("Open Budget Tracker")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 13))
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.sunYellow.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal, 18)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Cost Estimator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CostRow: View {
    let label: String
    let icon: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text("$\(String(format: "%.0f", amount))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
