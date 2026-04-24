import SwiftUI

// MARK: - Layout Builder (Main Screen)
struct LayoutBuilderView: View {
    let project: CoopProject
    @EnvironmentObject var projectStore: ProjectStore
    @State private var gridSize: Int = 20  // grid cell size in points
    @State private var showingElementLibrary = false
    @State private var selectedElement: LayoutElement? = nil
    @State private var showingElementEditor = false
    @State private var showingGridSettings = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var isDraggingElement: Bool = false
    @State private var draggingElementId: UUID? = nil
    @State private var dragLocation: CGPoint = .zero
    
    var currentProject: CoopProject {
        projectStore.projects.first { $0.id == project.id } ?? project
    }
    
    let gridColumns = 20
    let gridRows = 16
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 12) {
                    Button {
                        showingGridSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    Spacer()
                    
                    Text("Layout Builder")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            scale = 1.0
                            offset = .zero
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(Color.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    Button {
                        showingElementLibrary = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.bgPrimary)
                            .frame(width: 36, height: 36)
                            .background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.bgSecondary)
                
                // Stats bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        GridStatChip(label: "Space", value: currentProject.spaceStatus.label, color: currentProject.spaceStatus.color)
                        GridStatChip(label: "Nests", value: "\(currentProject.nestBoxCount)/\(currentProject.recommendedNestBoxes)", color: currentProject.nestBoxCount >= currentProject.recommendedNestBoxes ? .natureDark : .sunYellow)
                        GridStatChip(label: "Feeders", value: "\(currentProject.feederCount)/\(currentProject.recommendedFeeders)", color: currentProject.feederCount >= currentProject.recommendedFeeders ? .natureDark : .sunYellow)
                        GridStatChip(label: "Efficiency", value: "\(currentProject.efficiencyScore)%", color: currentProject.efficiencyScore >= 70 ? .natureDark : .alertRed)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                }
                .background(Color.bgSecondary)
                
                // Grid Canvas
                GeometryReader { geo in
                    ZStack {
                        // Background
                        Color.bgTertiary
                        
                        // Grid
                        GridCanvas(
                            columns: gridColumns,
                            rows: gridRows,
                            cellSize: CGFloat(gridSize),
                            projectWidth: currentProject.plotWidth,
                            projectHeight: currentProject.plotHeight
                        )
                        .scaleEffect(scale)
                        .offset(offset)
                        
                        // Elements
                        ForEach(currentProject.elements) { element in
                            ElementView(
                                element: element,
                                cellSize: CGFloat(gridSize),
                                isSelected: selectedElement?.id == element.id
                            )
                            .scaleEffect(scale)
                            .offset(
                                x: offset.width + CGFloat(element.gridX) * CGFloat(gridSize) * scale,
                                y: offset.height + CGFloat(element.gridY) * CGFloat(gridSize) * scale
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedElement?.id == element.id {
                                        selectedElement = nil
                                    } else {
                                        selectedElement = element
                                    }
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Move element
                                    }
                                    .onEnded { value in
                                        let newX = max(0, min(gridColumns - element.width, Int(value.location.x / CGFloat(gridSize))))
                                        let newY = max(0, min(gridRows - element.height, Int(value.location.y / CGFloat(gridSize))))
                                        var updated = element
                                        updated.gridX = newX
                                        updated.gridY = newY
                                        projectStore.updateElement(updated, in: project.id)
                                    }
                            )
                        }
                    }
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { val in
                                    let newScale = lastScale * val
                                    scale = min(max(newScale, 0.5), 3.0)
                                }
                                .onEnded { _ in lastScale = scale },
                            DragGesture()
                                .onChanged { val in
                                    offset = CGSize(
                                        width: val.translation.width,
                                        height: val.translation.height
                                    )
                                }
                                .onEnded { _ in }
                        )
                    )
                    .clipShape(Rectangle())
                }
                
                // Bottom panel
                if let sel = selectedElement {
                    ElementActionBar(
                        element: sel,
                        onEdit: {
                            showingElementEditor = true
                        },
                        onDelete: {
                            projectStore.deleteElement(sel.id, from: project.id)
                            selectedElement = nil
                        },
                        onRotate: {
                            var updated = sel
                            updated.rotation = (updated.rotation + 90).truncatingRemainder(dividingBy: 360)
                            projectStore.updateElement(updated, in: project.id)
                            selectedElement = updated
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingElementLibrary) {
            ElementLibraryView(project: currentProject) { type in
                addElement(type: type)
                showingElementLibrary = false
            }
        }
        .sheet(isPresented: $showingElementEditor) {
            if let sel = selectedElement {
                ElementEditorView(element: sel, projectId: project.id) { updated in
                    projectStore.updateElement(updated, in: project.id)
                    selectedElement = updated
                }
            }
        }
        .sheet(isPresented: $showingGridSettings) {
            GridSettingsView(cellSize: $gridSize)
        }
    }
    
    func addElement(type: ElementType) {
        let element = LayoutElement(
            type: type,
            gridX: 0,
            gridY: 0,
            width: Int(type.defaultSize.width),
            height: Int(type.defaultSize.height),
            label: type.rawValue
        )
        projectStore.addElement(element, to: project.id)
    }
}

// MARK: - Grid Canvas
struct GridCanvas: View {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let projectWidth: Double
    let projectHeight: Double
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(Color.bgPrimary)
                .frame(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
            
            // Grid lines
            Canvas { ctx, size in
                let gridColor = Color(hex: "#3A3A50").opacity(0.5)
                
                // Vertical lines
                for col in 0...columns {
                    let x = CGFloat(col) * cellSize
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * cellSize))
                    ctx.stroke(path, with: .color(gridColor), lineWidth: col % 5 == 0 ? 1.0 : 0.5)
                }
                
                // Horizontal lines
                for row in 0...rows {
                    let y = CGFloat(row) * cellSize
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: CGFloat(columns) * cellSize, y: y))
                    ctx.stroke(path, with: .color(gridColor), lineWidth: row % 5 == 0 ? 1.0 : 0.5)
                }
            }
            .frame(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
            
            // Scale indicator
            VStack(alignment: .trailing) {
                Spacer()
                HStack(spacing: 4) {
                    Spacer()
                    Text("\(String(format: "%.1f", projectWidth))m × \(String(format: "%.1f", projectHeight))m")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.techBlue.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bgPrimary.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .padding(6)
            }
            .frame(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
        }
    }
}

// MARK: - Element View
struct ElementView: View {
    let element: LayoutElement
    let cellSize: CGFloat
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(element.type.color.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isSelected ? Color.sunYellow : element.type.color.opacity(0.7), lineWidth: isSelected ? 2 : 1)
                )
            
            VStack(spacing: 2) {
                Text(element.type.icon)
                    .font(.system(size: min(cellSize * CGFloat(element.width) / 3, 24)))
                if element.width >= 2 {
                    Text(element.label)
                        .font(.system(size: min(8, cellSize / 3)))
                        .foregroundColor(element.type.color)
                        .lineLimit(1)
                }
            }
            
            if isSelected {
                // Selection handles
                VStack {
                    HStack {
                        SelectionHandle()
                        Spacer()
                        SelectionHandle()
                    }
                    Spacer()
                    HStack {
                        SelectionHandle()
                        Spacer()
                        SelectionHandle()
                    }
                }
                .padding(2)
            }
        }
        .frame(
            width: CGFloat(element.width) * cellSize,
            height: CGFloat(element.height) * cellSize
        )
        .rotationEffect(.degrees(element.rotation))
        .shadow(color: isSelected ? Color.sunYellow.opacity(0.3) : .clear, radius: 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SelectionHandle: View {
    var body: some View {
        Circle()
            .fill(Color.sunYellow)
            .frame(width: 8, height: 8)
            .shadow(color: Color.sunYellow.opacity(0.5), radius: 4)
    }
}

// MARK: - Element Action Bar
struct ElementActionBar: View {
    let element: LayoutElement
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onRotate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(element.type.icon)
                Text(element.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            
            Button {
                onRotate()
            } label: {
                Image(systemName: "rotate.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.techBlue)
                    .frame(width: 36, height: 36)
                    .background(Color.techBlue.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.sunYellow)
                    .frame(width: 36, height: 36)
                    .background(Color.sunYellow.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.alertRed)
                    .frame(width: 36, height: 36)
                    .background(Color.alertRed.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .overlay(
            Rectangle()
                .fill(Color.sunYellow.opacity(0.3))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Grid Settings
struct GridSettingsView: View {
    @Binding var cellSize: Int
    @Environment(\.presentationMode) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Grid Cell Size: \(cellSize)pt")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { Double(cellSize) },
                            set: { cellSize = Int($0) }
                        ), in: 16...48, step: 4)
                        .accentColor(.sunYellow)
                        
                        HStack {
                            Text("Fine").foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("Large").foregroundColor(.white.opacity(0.4))
                        }
                        .font(.system(size: 12))
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Text("A larger cell size makes elements easier to select and drag. Use fine grids for precise layouts.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        dismiss.wrappedValue.dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LinearGradient.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Grid Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Element Library
struct ElementLibraryView: View {
    let project: CoopProject
    let onSelect: (ElementType) -> Void
    @Environment(\.presentationMode) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ElementType.allCases, id: \.self) { type in
                            Button {
                                onSelect(type)
                            } label: {
                                ElementLibraryCard(type: type, count: project.elements.filter { $0.type == type }.count)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Element Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

struct ElementLibraryCard: View {
    let type: ElementType
    let count: Int
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(type.icon)
                    .font(.system(size: 28))
            }
            Text(type.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            if type.capacityPerUnit > 0 {
                Text("Serves \(type.capacityPerUnit) birds")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            if count > 0 {
                Text("✓ \(count) placed")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.natureDark)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(type.color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Element Editor
struct ElementEditorView: View {
    @State var element: LayoutElement
    let projectId: UUID
    let onSave: (LayoutElement) -> Void
    @Environment(\.presentationMode) var dismiss
    @State private var showSaved = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.cardBg)
                                .frame(height: 120)
                            ElementView(element: element, cellSize: 30, isSelected: false)
                        }
                        .padding(.horizontal, 18)
                        
                        FormSection(title: "Label") {
                            GCTextField(text: $element.label, placeholder: "Element label", icon: "tag.fill")
                        }
                        
                        FormSection(title: "Notes") {
                            GCTextField(text: $element.notes, placeholder: "Optional notes", icon: "note.text")
                        }
                        
                        FormSection(title: "Size (grid cells)") {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Width (\(element.width))").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                    Slider(value: Binding(get: { Double(element.width) }, set: { element.width = Int($0) }), in: 1...8, step: 1)
                                        .accentColor(.sunYellow)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Height (\(element.height))").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                                    Slider(value: Binding(get: { Double(element.height) }, set: { element.height = Int($0) }), in: 1...8, step: 1)
                                        .accentColor(.sunYellow)
                                }
                            }
                        }
                        
                        FormSection(title: "Rotation") {
                            HStack(spacing: 10) {
                                ForEach([0.0, 90.0, 180.0, 270.0], id: \.self) { angle in
                                    Button {
                                        element.rotation = angle
                                    } label: {
                                        Text("\(Int(angle))°")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(element.rotation == angle ? .bgPrimary : .white.opacity(0.6))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(element.rotation == angle ? Color.sunYellow : Color.cardBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                            }
                        }
                        
                        if showSaved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.natureDark)
                                Text("Saved!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.natureDark)
                            }
                        }
                        
                        Button {
                            onSave(element)
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss.wrappedValue.dismiss()
                            }
                        } label: {
                            Text("Save Changes")
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
            .navigationTitle("Edit Element")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

struct GridStatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
    }
}
