import SwiftUI

// Tour creation — Step 1: metadata (title, creator, tags, mode)
// Then Step 2: map view to add waypoints

struct CreateTourView: View {
    @Environment(WalkingTourStore.self) var tourStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var creatorName = ""
    @State private var creatorIsLocal = false
    @State private var description = ""
    @State private var mode: TourMode = .walking
    @State private var selectedTags: Set<String> = []
    @State private var showMapEditor = false
    @State private var tour: WalkingTour?

    private let availableTags = [
        "history", "architecture", "nature", "botanical",
        "art", "food", "music", "poetry", "neighborhood",
        "culture", "science", "literary",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tour Details") {
                    TextField("Tour Title", text: $title)
                    TextField("Your Name", text: $creatorName)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("About You") {
                    Toggle("I'm a local resident", isOn: $creatorIsLocal)
                }

                Section("Tour Type") {
                    Picker("Mode", selection: $mode) {
                        ForEach(TourMode.allCases.filter { $0 != .driving }) { m in
                            Label(m.displayName, systemImage: m.iconName)
                                .tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Tags") {
                    FlowLayout(spacing: 8) {
                        ForEach(availableTags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains(tag)
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Stops") {
                        createTourAndShowMap()
                    }
                    .disabled(title.isEmpty || creatorName.isEmpty)
                    .bold()
                }
            }
            .navigationDestination(isPresented: $showMapEditor) {
                if let tour = tour {
                    WaypointMapEditorView(tour: tour, onSaved: { dismiss() })
                }
            }
        }
    }

    private func createTourAndShowMap() {
        let newTour = WalkingTour(
            id: UUID().uuidString,
            title: title,
            creatorName: creatorName,
            creatorIsLocal: creatorIsLocal,
            description: description,
            tags: Array(selectedTags),
            mode: mode,
            waypoints: [],
            createdAt: Date(),
            updatedAt: Date(),
            isAuthored: false
        )
        self.tour = newTour
        showMapEditor = true
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
