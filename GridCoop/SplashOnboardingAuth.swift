import SwiftUI

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
 
    var body: some View {
        ZStack {
            Color(hex: "#111118").ignoresSafeArea()
 
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(currentPage == i ? Color(hex: "#C08A5A") : Color.white.opacity(0.15))
                                .frame(width: currentPage == i ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    Spacer()
                    Button("Skip") {
                        withAnimation(.easeInOut(duration: 0.3)) { appState.completeOnboarding() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24).padding(.top, 56).padding(.bottom, 24)
 
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
 
                Button {
                    if currentPage < 2 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage += 1 }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { appState.completeOnboarding() }
                    }
                } label: {
                    ZStack {
                        LinearGradient(
                            colors: currentPage < 2
                                ? [Color(hex: "#C08A5A"), Color(hex: "#A47148")]
                                : [Color(hex: "#FFC933"), Color(hex: "#FF9F5A")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        HStack(spacing: 12) {
                            Text(currentPage < 2 ? "Continue" : "Start Planning")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(currentPage < 2 ? .white : Color(hex: "#111118"))
                    }
                    .frame(height: 56).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: currentPage < 2 ? Color(hex: "#A47148").opacity(0.4) : Color(hex: "#FFC933").opacity(0.4),
                        radius: 16, x: 0, y: 6
                    )
                }
                .padding(.horizontal, 24).padding(.bottom, 48)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}
 
// MARK: - Onboarding Page 1: Build Your Coop
struct OnboardingPage1: View {
    @State private var filledCells: Set<Int> = []
    @State private var cellEmojis: [Int: String] = [:]
    @State private var appeared = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var hintPulse = false
 
    let cols = 5, rows = 4
    let cellSize: CGFloat = 52, gap: CGFloat = 7
    let birds = ["🐔", "🐓", "🐣"]
    let elems = ["🪺", "🍽️", "🌬️", "💡"]
 
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
 
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [Color(hex: "#2A1E0E").opacity(0.9), .clear], center: .center, startRadius: 40, endRadius: 180))
                    .frame(width: 360, height: 280).blur(radius: 20)
 
                VStack(spacing: 0) {
                    // Hint chip
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#FFC933")).frame(width: 6, height: 6)
                            .scaleEffect(hintPulse ? 1.4 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: hintPulse)
                        Text("Tap cells to place your flock")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "#FFC933"))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color(hex: "#FFC933").opacity(0.12)).clipShape(Capsule())
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : -10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: appeared)
 
                    // Grid
                    VStack(spacing: gap) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let idx = row * cols + col
                                    let filled = filledCells.contains(idx)
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(filled ? Color(hex: "#2A1E0E") : Color(hex: "#1A1810").opacity(0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .stroke(filled ? Color(hex: "#C08A5A").opacity(0.6) : Color(hex: "#3A3020").opacity(0.5),
                                                            lineWidth: filled ? 1.5 : 1)
                                            )
                                        if let e = cellEmojis[idx] {
                                            Text(e).font(.system(size: 24))
                                                .transition(.asymmetric(
                                                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                                                    removal: .scale(scale: 0.5).combined(with: .opacity)
                                                )).id(e + "\(idx)")
                                        } else if filled {
                                            Circle().fill(Color(hex: "#C08A5A").opacity(0.3)).frame(width: 10, height: 10)
                                        }
                                    }
                                    .frame(width: cellSize, height: cellSize)
                                    .scaleEffect(appeared ? 1.0 : 0.7)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.65).delay(Double(row * cols + col) * 0.025), value: appeared)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                                            if filledCells.contains(idx) {
                                                filledCells.remove(idx); cellEmojis.removeValue(forKey: idx)
                                            } else {
                                                filledCells.insert(idx)
                                                cellEmojis[idx] = Int.random(in: 0...3) < 2 ? birds.randomElement()! : elems.randomElement()!
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: 320)
 
            Spacer().frame(height: 36)
 
            VStack(spacing: 12) {
                Text("Design Your Coop")
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("Tap the grid to place birds, nests, feeders and more — then let our calculators optimize every square metre.")
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center).lineSpacing(5).padding(.horizontal, 32)
            }
            .offset(y: titleOffset).opacity(titleOpacity)
 
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true; titleOffset = 0; titleOpacity = 1
            }
            hintPulse = true
            let demo: [(Int, String)] = [(0,"🪺"),(1,"🪺"),(5,"🐔"),(6,"🐓"),(10,"🍽️"),(12,"🐣"),(16,"🌬️")]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                for (i, (idx, emoji)) in demo.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            filledCells.insert(idx); cellEmojis[idx] = emoji
                        }
                    }
                }
            }
        }
    }
}
 
// MARK: - Onboarding Page 2: Optimize Space
struct OnboardingPage2: View {
    @State private var appeared = false
    @State private var spaceScore: CGFloat = 0
    @State private var ventScore: CGFloat = 0
    @State private var lightScore: CGFloat = 0
    @State private var birdCount: CGFloat = 0
    @State private var floatPhase: CGFloat = 0
 
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
 
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [Color(hex: "#0D1E2E").opacity(0.9), .clear], center: .center, startRadius: 40, endRadius: 180))
                    .frame(width: 360, height: 300).blur(radius: 20)
 
                VStack(spacing: 20) {
                    // Ring gauge
                    ZStack {
                        Circle().stroke(Color(hex: "#1E2D3D"), lineWidth: 1).frame(width: 160, height: 160)
                        Circle().stroke(Color(hex: "#1A2030"), lineWidth: 14).frame(width: 130, height: 130)
                        Circle()
                            .trim(from: 0, to: spaceScore)
                            .stroke(
                                LinearGradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#6BCB77")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 130, height: 130).rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.2), value: spaceScore)
                        VStack(spacing: 2) {
                            Text("🐔").font(.system(size: 28)).offset(y: sin(floatPhase) * 3)
                            Text("\(Int(birdCount))").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(.white)
                                .contentTransition(.numericText())
                            Text("birds").font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.4))
                        }
                        ForEach(0..<12, id: \.self) { i in
                            Rectangle().fill(Color.white.opacity(0.08))
                                .frame(width: 1, height: i % 3 == 0 ? 8 : 4)
                                .offset(y: -80).rotationEffect(.degrees(Double(i) * 30))
                        }
                    }
                    .frame(width: 160, height: 160)
 
                    VStack(spacing: 10) {
                        OBMetricBar(label: "Space", value: spaceScore, color: Color(hex: "#4CAF50"), icon: "arrow.up.left.and.arrow.down.right", delay: 0.3)
                        OBMetricBar(label: "Ventilation", value: ventScore, color: Color(hex: "#4DA6FF"), icon: "wind", delay: 0.5)
                        OBMetricBar(label: "Light", value: lightScore, color: Color(hex: "#FFC933"), icon: "sun.max.fill", delay: 0.7)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .frame(height: 340)
 
            Spacer().frame(height: 28)
 
            VStack(spacing: 12) {
                Text("Optimize Every Metre")
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.white)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15), value: appeared)
                Text("Real-time calculators track space, airflow, and lighting so every bird lives in optimal conditions.")
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center).lineSpacing(5).padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.25), value: appeared)
            }
            Spacer()
        }
        .onAppear {
            appeared = true
            withAnimation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.3)) { spaceScore = 0.82 }
            withAnimation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.5)) { ventScore = 0.67 }
            withAnimation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.7)) { lightScore = 0.91 }
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) { birdCount = 24 }
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in floatPhase += 0.03 }
    }
}
 
struct OBMetricBar: View {
    let label: String
    let value: CGFloat
    let color: Color
    let icon: String
    let delay: Double
    @State private var animated: CGFloat = 0
 
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color).frame(width: 16)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.6)).frame(width: 72, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * animated)
                        .animation(.spring(response: 1.2, dampingFraction: 0.7).delay(delay), value: animated)
                }
            }
            .frame(height: 8).clipShape(RoundedRectangle(cornerRadius: 4))
            Text("\(Int(animated * 100))%")
                .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(color)
                .frame(width: 34, alignment: .trailing).contentTransition(.numericText())
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(delay)) { animated = value }
        }
    }
}
 
// MARK: - Onboarding Page 3: Smart Tips
struct OnboardingPage3: View {
    @State private var appeared = false
    @State private var cardOffsets: [CGFloat] = [60, 60, 60]
    @State private var cardOpacities: [Double] = [0, 0, 0]
    @State private var checkedItems: Set<Int> = []
    @State private var glowPhase: CGFloat = 0
 
    let tips: [(emoji: String, title: String, desc: String, color: Color)] = [
        ("🪺", "Add Nest Boxes", "1 box per 4–5 hens reduces egg-floor laying by 90%", Color(hex: "#C08A5A")),
        ("🌬️", "Improve Airflow", "Target 0.3 m³/min per bird to prevent respiratory disease", Color(hex: "#4DA6FF")),
        ("🌿", "Expand the Space", "Birds need ≥0.37 m² indoors. More space = happier flock.", Color(hex: "#4CAF50")),
    ]
 
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
 
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [Color(hex: "#1A2E1A").opacity(0.8), .clear], center: .center, startRadius: 20, endRadius: 180))
                    .frame(width: 360, height: 300).blur(radius: 24)
 
                VStack(spacing: 12) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { i, tip in
                        OBTipCard(emoji: tip.emoji, title: tip.title, desc: tip.desc, color: tip.color,
                                  isChecked: checkedItems.contains(i), glowPhase: glowPhase)
                            .offset(y: cardOffsets[i]).opacity(cardOpacities[i])
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    if checkedItems.contains(i) {
                                        checkedItems.remove(i)
                                    } else {
                                        checkedItems.insert(i)
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 320)
 
            Spacer().frame(height: 28)
 
            VStack(spacing: 12) {
                Text("Smart Suggestions")
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.white)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: appeared)
                Text("Grid Coop analyses your setup and surfaces actionable tips — tap any suggestion to mark it done.")
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center).lineSpacing(5).padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5), value: appeared)
            }
            Spacer()
        }
        .onAppear {
            appeared = true
            for i in 0..<3 {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(Double(i) * 0.14 + 0.1)) {
                    cardOffsets[i] = 0; cardOpacities[i] = 1
                }
            }
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in glowPhase += 0.02 }
    }
}
 
struct OBTipCard: View {
    let emoji, title, desc: String
    let color: Color
    let isChecked: Bool
    let glowPhase: CGFloat
 
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                    .shadow(color: isChecked ? color.opacity(0.4 + 0.15 * Double(sin(glowPhase))) : .clear, radius: 10)
                Text(emoji).font(.system(size: 22))
                    .scaleEffect(isChecked ? 1.15 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isChecked)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Text(desc).font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).lineLimit(2)
            }
            Spacer()
            ZStack {
                Circle().stroke(isChecked ? color : Color.white.opacity(0.15), lineWidth: 1.5).frame(width: 24, height: 24)
                if isChecked {
                    Circle().fill(color).frame(width: 24, height: 24).transition(.scale(scale: 0.2).combined(with: .opacity))
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white).transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isChecked)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#1C1A14"))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isChecked ? color.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1.5))
                .shadow(color: isChecked ? color.opacity(0.15) : .clear, radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Auth View
struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isRegistering = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var logoScale: CGFloat = 0.7
    @State private var formOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            // Background decoration
            Circle()
                .fill(Color.woodDark.opacity(0.08))
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .blur(radius: 40)
            
            Circle()
                .fill(Color.techBlue.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 200)
                .blur(radius: 40)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LinearGradient.woodGradient)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.woodDark.opacity(0.4), radius: 16)
                            Text("🐔")
                                .font(.system(size: 36))
                        }
                        .scaleEffect(logoScale)
                        
                        Text("Grid Coop")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Smart Poultry Planning")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                            .tracking(2)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Demo Account Button
                        Button {
                            authViewModel.loginDemo()
                        } label: {
                            HStack(spacing: 12) {
                                Text("🌾")
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Try Demo Account")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.bgPrimary)
                                    Text("No signup required")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.bgPrimary.opacity(0.6))
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.bgPrimary.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 64)
                            .background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.sunYellow.opacity(0.35), radius: 12)
                        }
                        
                        // Divider
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.35))
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 1)
                        }
                        
                        // Segmented toggle
                        HStack(spacing: 0) {
                            ForEach(["Sign In", "Register"], id: \.self) { tab in
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        isRegistering = tab == "Register"
                                        authViewModel.errorMessage = ""
                                    }
                                } label: {
                                    Text(tab)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(isRegistering == (tab == "Register") ? .white : .white.opacity(0.4))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(
                                            isRegistering == (tab == "Register") ?
                                            Color.cardBgLight : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        // Fields
                        VStack(spacing: 12) {
                            if isRegistering {
                                GCTextField(text: $name, placeholder: "Full Name", icon: "person.fill")
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            GCTextField(text: $email, placeholder: "Email Address", icon: "envelope.fill", keyboardType: .emailAddress)
                            GCSecureField(text: $password, placeholder: "Password", showPassword: $showPassword)
                        }
                        
                        // Error
                        if !authViewModel.errorMessage.isEmpty {
                            Text(authViewModel.errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.alertRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                        
                        // Submit
                        Button {
                            if isRegistering {
                                authViewModel.register(name: name, email: email, password: password)
                            } else {
                                authViewModel.login(email: email, password: password)
                            }
                        } label: {
                            ZStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .bgPrimary))
                                } else {
                                    Text(isRegistering ? "Create Account" : "Sign In")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.bgPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.woodGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .opacity(formOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                logoScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                formOpacity = 1
            }
        }
    }
}

// MARK: - Custom Text Fields
struct GCTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.woodLight.opacity(0.7))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct GCSecureField: View {
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.woodLight.opacity(0.7))
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .foregroundColor(.white)
            .autocapitalization(.none)
            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Setup View
struct SetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var birdCount: Double = 10
    @State private var selectedBird: BirdType = .chicken
    @State private var selectedGoal: CoopGoal = .eggs
    @State private var step = 0
    @State private var cardOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(step >= i ? Color.sunYellow : Color.cardBgLight)
                            .frame(height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)
                
                ScrollView {
                    VStack(spacing: 32) {
                        if step == 0 {
                            // Bird count
                            VStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("How Many Birds?")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("We'll calculate space and requirements")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.cardBg)
                                    VStack(spacing: 12) {
                                        Text(selectedBird.icon)
                                            .font(.system(size: 60))
                                        Text("\(Int(birdCount))")
                                            .font(.system(size: 56, weight: .bold, design: .rounded))
                                            .foregroundColor(.sunYellow)
                                        Text("birds")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(32)
                                }
                                .padding(.horizontal, 24)
                                
                                VStack(spacing: 8) {
                                    Slider(value: $birdCount, in: 1...200, step: 1)
                                        .accentColor(.sunYellow)
                                    HStack {
                                        Text("1").foregroundColor(.white.opacity(0.4))
                                        Spacer()
                                        Text("200").foregroundColor(.white.opacity(0.4))
                                    }
                                    .font(.system(size: 12))
                                }
                                .padding(.horizontal, 24)
                            }
                        } else if step == 1 {
                            // Bird type
                            VStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("Bird Type")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Space requirements vary by species")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                VStack(spacing: 10) {
                                    ForEach(BirdType.allCases, id: \.self) { bird in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedBird = bird
                                            }
                                        } label: {
                                            HStack(spacing: 16) {
                                                Text(bird.icon)
                                                    .font(.system(size: 28))
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(bird.rawValue)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                    Text("\(String(format: "%.2f", bird.spacePerBird)) m² per bird")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                                Spacer()
                                                if selectedBird == bird {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.sunYellow)
                                                        .font(.system(size: 20))
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .frame(height: 64)
                                            .background(selectedBird == bird ? Color.cardBgLight : Color.cardBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(selectedBird == bird ? Color.sunYellow.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        } else {
                            // Goal
                            VStack(spacing: 24) {
                                VStack(spacing: 8) {
                                    Text("Your Goal")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("We'll tailor recommendations accordingly")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(CoopGoal.allCases, id: \.self) { goal in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedGoal = goal
                                            }
                                        } label: {
                                            VStack(spacing: 12) {
                                                Text(goal.icon)
                                                    .font(.system(size: 36))
                                                Text(goal.rawValue)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 20)
                                            .background(selectedGoal == goal ? Color.cardBgLight : Color.cardBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(selectedGoal == goal ? Color.sunYellow.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                
                // Navigation
                HStack(spacing: 12) {
                    if step > 0 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(Color.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    
                    Button {
                        if step < 2 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step += 1 }
                        } else {
                            authViewModel.saveSetup(birdCount: Int(birdCount), birdType: selectedBird, goal: selectedGoal)
                        }
                    } label: {
                        Text(step < 2 ? "Continue" : "Start Planning")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
