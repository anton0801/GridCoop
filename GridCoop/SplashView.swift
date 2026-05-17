import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var phase: SplashPhase = .idle
 
    // Grid build state
    @State private var revealedCells: Set<Int> = []
    @State private var cellElements: [Int: CellElement] = [:]
 
    // Logo reveal
    @State private var logoScale: CGFloat = 0.0
    @State private var logoOpacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @StateObject private var viewModel = GridCoopViewModel()
    @State private var networkMonitor = NWPathMonitor()
    @State private var backgroundGlowScale: CGFloat = 0.3
    @State private var backgroundGlowOpacity: Double = 0.0
    
    @State private var cancellables = Set<AnyCancellable>()
    
    // Ambient particles
    @State private var particles: [SplashParticle] = SplashParticle.generate(count: 18)
    @State private var particlePhase: CGFloat = 0
 
    let cols = 7
    let rows = 5
    let cellSize: CGFloat = 38
    let cellGap: CGFloat = 5
 
    enum SplashPhase { case idle, buildingGrid, placingElements, revealLogo }
 
    struct CellElement {
        let emoji: String
        let color: Color
    }
 
    var totalCells: Int { cols * rows }
    var gridWidth: CGFloat { CGFloat(cols) * (cellSize + cellGap) - cellGap }
    var gridHeight: CGFloat { CGFloat(rows) * (cellSize + cellGap) - cellGap }
 
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#111118").ignoresSafeArea()
     
                // Organic glow blobs
                ZStack {
                    Ellipse()
                        .fill(Color(hex: "#3A2A1A").opacity(0.6))
                        .frame(width: 320, height: 200)
                        .blur(radius: 60)
                        .offset(x: -60, y: -180)
                        .scaleEffect(backgroundGlowScale)
                        .opacity(backgroundGlowOpacity)
     
                    Ellipse()
                        .fill(Color(hex: "#1A3020").opacity(0.5))
                        .frame(width: 280, height: 220)
                        .blur(radius: 60)
                        .offset(x: 80, y: 160)
                        .scaleEffect(backgroundGlowScale)
                        .opacity(backgroundGlowOpacity)
     
                    Ellipse()
                        .fill(Color(hex: "#8B5E3C").opacity(0.12))
                        .frame(width: 400, height: 300)
                        .blur(radius: 80)
                        .scaleEffect(backgroundGlowScale)
                        .opacity(backgroundGlowOpacity)
                }
                
                NavigationLink(
                    destination: GridCoopWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
     
                // Floating ambient particles
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x + sin(particlePhase * p.speed + p.phase) * 12,
                            y: p.y + cos(particlePhase * p.speed * 0.7 + p.phase) * 8
                        )
                        .opacity(p.opacity * (backgroundGlowOpacity > 0 ? 1 : 0))
                        .blur(radius: p.size > 4 ? 1 : 0)
                }
     
                VStack(spacing: 0) {
                    Spacer()
     
                    // The animated coop grid
                    ZStack {
                        VStack(spacing: cellGap) {
                            ForEach(0..<rows, id: \.self) { row in
                                HStack(spacing: cellGap) {
                                    ForEach(0..<cols, id: \.self) { col in
                                        let idx = row * cols + col
                                        let isRevealed = revealedCells.contains(idx)
                                        let element = cellElements[idx]
     
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .fill(cellFill(idx: idx, element: element))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                        .stroke(cellStroke(element: element), lineWidth: 1)
                                                )
     
                                            if let el = element {
                                                Text(el.emoji)
                                                    .font(.system(size: cellSize * 0.45))
                                                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                                            } else if isRevealed {
                                                Circle()
                                                    .fill(Color.white.opacity(0.04))
                                                    .frame(width: 3, height: 3)
                                            }
                                        }
                                        .frame(width: cellSize, height: cellSize)
                                        .scaleEffect(isRevealed ? 1.0 : 0.0)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isRevealed)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: gridWidth, height: gridHeight)
                    .opacity(phase == .idle ? 0 : 1)
     
                    Spacer().frame(height: 44)
     
                    // Logo reveal
                    VStack(spacing: 10) {
                        Text("Grid Coop")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#E8C57A"), Color(hex: "#C08A5A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
     
                        Text("Smart Poultry Planning")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.4))
                            .tracking(2.5)
                            .opacity(taglineOpacity)
                        
                        ProgressView().tint(Color(hex: "#E8C57A"))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
     
                    Spacer()
                }
            }
            .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
                particlePhase += 0.012
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                GridCoopConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
            .onAppear {
                setupStreams()
                runSplashSequence()
                setupNetworkMonitoring()
                viewModel.boot()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
 
    func cellFill(idx: Int, element: CellElement?) -> Color {
        if let el = element { return el.color.opacity(0.25) }
        let row = idx / cols, col = idx % cols
        let isEdge = row == 0 || row == rows-1 || col == 0 || col == cols-1
        return isEdge ? Color(hex: "#2A2218").opacity(0.9) : Color(hex: "#1E1C14").opacity(0.85)
    }
 
    func cellStroke(element: CellElement?) -> Color {
        if let el = element { return el.color.opacity(0.5) }
        return Color(hex: "#4A3E2A").opacity(0.4)
    }
 
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }
    
    func runSplashSequence() {
        withAnimation(.easeOut(duration: 1.2)) {
            backgroundGlowScale = 1.0
            backgroundGlowOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .buildingGrid
            buildGridWave()
        }
        let elemDelay = 0.3 + Double(totalCells) * 0.022 + 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + elemDelay) {
            phase = .placingElements
            placeElements()
        }
        let logoDelay = elemDelay + 0.65
        DispatchQueue.main.asyncAfter(deadline: .now() + logoDelay) {
            phase = .revealLogo
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0; logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                taglineOpacity = 1.0
            }
        }
    }
 
    func buildGridWave() {
        let sortedIndices = (0..<totalCells).sorted { a, b in
            let diagA = (a / cols) + (a % cols)
            let diagB = (b / cols) + (b % cols)
            return diagA != diagB ? diagA < diagB : a < b
        }
        for (i, idx) in sortedIndices.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.022) {
                withAnimation { _ = revealedCells.insert(idx) }
            }
        }
    }
 
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    func placeElements() {
        let placements: [(row: Int, col: Int, emoji: String, color: Color)] = [
            (1, 1, "🪺", Color(hex: "#C08A5A")), (1, 2, "🪺", Color(hex: "#C08A5A")),
            (1, 4, "🪺", Color(hex: "#C08A5A")), (1, 5, "🪺", Color(hex: "#C08A5A")),
            (3, 1, "🍽️", Color(hex: "#4CAF50")), (3, 3, "🍽️", Color(hex: "#4CAF50")),
            (3, 5, "🍽️", Color(hex: "#4CAF50")), (2, 3, "🐔", Color(hex: "#FFC933")),
            (0, 6, "🌬️", Color(hex: "#4DA6FF")), (4, 6, "💡", Color(hex: "#FFD95A")),
        ]
        for (i, p) in placements.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    cellElements[p.row * cols + p.col] = CellElement(emoji: p.emoji, color: p.color)
                }
            }
        }
    }
}
 
// MARK: - Splash Particle
struct SplashParticle: Identifiable {
    let id = UUID()
    let x, y, size: CGFloat
    let color: Color
    let opacity: Double
    let speed, phase: CGFloat
 
    static func generate(count: Int) -> [SplashParticle] {
        let colors: [Color] = [
            Color(hex: "#C08A5A").opacity(0.6), Color(hex: "#4CAF50").opacity(0.5),
            Color(hex: "#FFC933").opacity(0.5), Color(hex: "#4DA6FF").opacity(0.4),
        ]
        return (0..<count).map { _ in
            SplashParticle(
                x: .random(in: 20...370), y: .random(in: 20...824),
                size: .random(in: 2...7), color: colors.randomElement()!,
                opacity: .random(in: 0.3...0.8),
                speed: .random(in: 0.4...1.2), phase: .random(in: 0...CGFloat.pi * 2)
            )
        }
    }
}
