import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15
    @State private var subtitleOpacity: Double = 0
    @State private var particlesVisible = false
    @State private var glowRadius: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            // Particles
            if particlesVisible {
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(i % 3 == 0 ? Color.sunYellow : i % 3 == 1 ? Color.woodMid : Color.natureDark)
                        .frame(width: CGFloat.random(in: 3...8))
                        .offset(
                            x: CGFloat.random(in: -160...160),
                            y: CGFloat.random(in: -160...160)
                        )
                        .opacity(0.6)
                        .animation(.easeOut(duration: 2.0).delay(Double(i) * 0.1), value: particlesVisible)
                }
            }
            
            VStack(spacing: 20) {
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.woodMid.opacity(0.15))
                        .frame(width: 140 + glowRadius, height: 140 + glowRadius)
                        .blur(radius: 20)
                    
                    // Logo background
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient.woodGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.woodDark.opacity(0.5), radius: 20)
                    
                    // Grid lines inside logo
                    VStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 14) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                    }
                    
                    // Chicken emoji overlay
                    Text("🐔")
                        .font(.system(size: 44))
                        .offset(x: 2, y: 2)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Color.woodMid.opacity(0.4), radius: glowRadius / 2)
                
                VStack(spacing: 8) {
                    Text("Grid Coop")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Smart Poultry Planning")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.woodLight.opacity(0.8))
                        .tracking(2)
                }
                .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                opacity = 1
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.4)) {
                glowRadius = 40
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.8)) {
                particlesVisible = true
            }
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Design Your Coop",
            subtitle: "Drag and drop elements onto a smart grid to plan your perfect poultry space.",
            icon: "square.grid.3x3.fill",
            accentColor: .woodLight,
            gradientColors: [Color.woodDark, Color.woodLight],
            interactiveHint: "Tap the grid cells below"
        ),
        OnboardingPage(
            title: "Optimize Space",
            subtitle: "Smart calculators ensure every bird has enough room, ventilation, and light.",
            icon: "chart.bar.fill",
            accentColor: .techBlue,
            gradientColors: [Color.techBlue, Color(hex: "#5B4BFF")],
            interactiveHint: "Watch the indicators"
        ),
        OnboardingPage(
            title: "Improve Conditions",
            subtitle: "Get real-time recommendations based on your climate, flock size, and goals.",
            icon: "sparkles",
            accentColor: .sunYellow,
            gradientColors: [Color.sunYellow, Color(hex: "#FF9F5A")],
            interactiveHint: "Swipe to continue"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 15, weight: .medium))
                    .padding()
                }
                
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page, isActive: currentPage == idx)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                
                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(currentPage == i ? Color.sunYellow : Color.white.opacity(0.3))
                            .frame(width: currentPage == i ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                
                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        appState.completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.sunYellow.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let gradientColors: [Color]
    let interactiveHint: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var iconScale: CGFloat = 0.8
    @State private var gridCells: [Bool] = Array(repeating: false, count: 9)
    @State private var scoreValue: Double = 0
    @State private var bubbleScale: [CGFloat] = [1, 1, 1]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            ZStack {
                // Background circle
                Circle()
                    .fill(LinearGradient(colors: page.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.15))
                    .frame(width: 220, height: 220)
                
                Circle()
                    .stroke(LinearGradient(colors: page.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    .frame(width: 220, height: 220)
                    .opacity(0.4)
                
                // Page-specific interactive illustration
                if page.icon == "square.grid.3x3.fill" {
                    // Grid illustration
                    VStack(spacing: 6) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 6) {
                                ForEach(0..<3) { col in
                                    let idx = row * 3 + col
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(gridCells[idx] ? Color.sunYellow : Color.cardBg)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(gridCells[idx] ? "🪺" : "")
                                                .font(.system(size: 20))
                                        )
                                        .scaleEffect(gridCells[idx] ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: gridCells[idx])
                                        .onTapGesture {
                                            gridCells[idx].toggle()
                                        }
                                }
                            }
                        }
                    }
                } else if page.icon == "chart.bar.fill" {
                    // Score illustration
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.cardBg, lineWidth: 8)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: scoreValue / 100)
                                .stroke(LinearGradient(colors: page.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: scoreValue)
                            Text("\(Int(scoreValue))%")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 20) {
                            ForEach(0..<3) { i in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(page.gradientColors[0])
                                        .frame(width: 28, height: CGFloat([30, 50, 40][i]) * (scoreValue / 100))
                                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(Double(i) * 0.15), value: scoreValue)
                                }
                                .frame(height: 60, alignment: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if isActive {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                scoreValue = 78
                            }
                        }
                    }
                } else {
                    // Tips illustration
                    VStack(spacing: 10) {
                        ForEach(["💡 Add nest boxes", "💨 Improve airflow", "🌿 More space needed"], id: \.self) { tip in
                            HStack(spacing: 10) {
                                Text(tip)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .scaleEffect(iconScale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    iconScale = 1.0
                }
            }
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Text(page.interactiveHint)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(page.accentColor.opacity(0.8))
                .tracking(1)
            
            Spacer()
        }
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
