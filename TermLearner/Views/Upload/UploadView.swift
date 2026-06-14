import SwiftUI
import SwiftData
import PhotosUI

struct UploadView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [TermCollection]

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var extractedTerms: [ExtractedTerm] = []
    @State private var isProcessing = false
    @State private var processingError: String?
    @State private var copyrightWarning: String?
    @State private var showCollectionPicker = false
    @State private var selectedCollectionID: UUID?
    @State private var newCollectionName = ""
    @State private var showSaveSuccess = false
    @State private var phase: UploadPhase = .idle
    @State private var showCamera = false

    enum UploadPhase { case idle, preview, review, saving }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    switch phase {
                    case .idle:    idleContent
                    case .preview: previewContent
                    case .review:  reviewContent
                    case .saving:  savingContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppColors.background)
            .navigationTitle("Upload Terms")
            .navigationBarTitleDisplayMode(.large)
            .overlay(successOverlay)
        }
    }

    // MARK: - Phases

    private var idleContent: some View {
        VStack(spacing: 24) {
            uploadCard
            instructionsCard
        }
    }

    private var uploadCard: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.primary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(AppColors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )

                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(AppColors.primary)

                    VStack(spacing: 6) {
                        Text("Upload an Image")
                            .font(AppFonts.heading())
                        Text("Vocabulary lists, textbook pages, flashcard photos\nUp to 70 terms per image")
                            .font(AppFonts.caption())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .font(AppFonts.heading(14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppColors.primary)
                                .clipShape(Capsule())
                        }

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera.fill")
                                    .font(AppFonts.heading(14))
                                    .foregroundStyle(AppColors.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(AppColors.primary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(32)
            }
            .frame(minHeight: 280)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            Task { await loadImage(from: item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                showCamera = false
                guard let image else { return }
                Task { await processImage(image) }
            }
            .ignoresSafeArea()
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How it works")
                .font(AppFonts.heading())

            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(AppFonts.caption(12))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(AppFonts.heading(14))
                        Text(step.body)
                            .font(AppFonts.caption())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var steps = [
        (title: "Pick an image", body: "Select a photo from your library containing vocabulary terms"),
        (title: "AI extraction", body: "Claude AI reads and organises all terms — even 70+ per page"),
        (title: "Review & edit", body: "Check the extracted terms, remove or edit any mistakes"),
        (title: "Save to collection", body: "Add to an existing collection or create a new one"),
    ]

    private var previewContent: some View {
        VStack(spacing: 16) {
            if let img = selectedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8)
            }

            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(AppColors.primary)
                    Text("Claude AI is extracting terms…")
                        .font(AppFonts.body())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 32)
            }

            if let error = processingError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.secondary)
                    Text(error)
                        .font(AppFonts.body())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        processingError = nil
                        phase = .idle
                        selectedPhoto = nil
                        selectedImage = nil
                    }
                    .font(AppFonts.heading(15))
                    .foregroundStyle(AppColors.primary)
                }
                .cardStyle(padding: 24)
            }
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 16) {
            if let warning = copyrightWarning {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "c.circle.fill")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                }
                .cardStyle(padding: 14)
            }

            HStack {
                Text("\(extractedTerms.count) terms extracted")
                    .font(AppFonts.heading())
                Spacer()
                Button("Clear") {
                    phase = .idle
                    selectedPhoto = nil
                    selectedImage = nil
                    extractedTerms = []
                }
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.secondary)
            }

            ForEach($extractedTerms) { $term in
                ExtractedTermRow(term: $term, onDelete: {
                    extractedTerms.removeAll { $0.id == term.id }
                })
            }

            collectionPickerSection
        }
    }

    private var collectionPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save to Collection")
                .font(AppFonts.heading())

            if !collections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(collections) { col in
                            Button {
                                selectedCollectionID = col.id
                                newCollectionName = ""
                            } label: {
                                Text(col.name)
                                    .font(AppFonts.caption())
                                    .foregroundStyle(selectedCollectionID == col.id ? .white : AppColors.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCollectionID == col.id
                                            ? AppColors.primary
                                            : AppColors.primary.opacity(0.12)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            HStack(spacing: 12) {
                TextField("Or create new collection…", text: $newCollectionName)
                    .font(AppFonts.body())
                    .padding(12)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: newCollectionName) { _, val in
                        if !val.isEmpty { selectedCollectionID = nil }
                    }
            }

            Button {
                saveTerms()
            } label: {
                Text("Save \(extractedTerms.count) Terms")
                    .primaryButton()
            }
            .buttonStyle(.plain)
            .disabled(extractedTerms.isEmpty || (selectedCollectionID == nil && newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty))
            .opacity(extractedTerms.isEmpty || (selectedCollectionID == nil && newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.5 : 1)
        }
    }

    private var savingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(AppColors.primary)
            Text("Saving terms…")
                .font(AppFonts.body())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    @ViewBuilder
    private var successOverlay: some View {
        if showSaveSuccess {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.accent)
                Text("Terms Saved!")
                    .font(AppFonts.heading())
            }
            .frame(maxWidth: .infinity)
            .cardStyle(padding: 32)
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await processImage(image)
    }

    private func processImage(_ image: UIImage) async {
        await MainActor.run {
            selectedImage = image
            isProcessing = true
            processingError = nil
            phase = .preview
        }

        do {
            let result = try await ClaudeService.shared.extractTerms(from: image)
            await MainActor.run {
                extractedTerms = result.terms
                copyrightWarning = result.warning
                isProcessing = false
                phase = .review
            }
        } catch {
            await MainActor.run {
                processingError = error.localizedDescription
                isProcessing = false
            }
        }
    }

    private func saveTerms() {
        phase = .saving

        let collection: TermCollection
        if let id = selectedCollectionID, let existing = collections.first(where: { $0.id == id }) {
            collection = existing
        } else {
            let name = newCollectionName.trimmingCharacters(in: .whitespaces)
            let color = collectionColors.randomElement() ?? "6C63FF"
            collection = TermCollection(name: name, colorHex: color)
            modelContext.insert(collection)
        }

        for extracted in extractedTerms {
            let term = Term(word: extracted.word, definition: extracted.definition, notes: extracted.notes)
            term.collection = collection
            modelContext.insert(term)
            collection.terms.append(term)
        }

        try? modelContext.save()

        withAnimation(.spring(response: 0.4)) {
            showSaveSuccess = true
            phase = .idle
            extractedTerms = []
            selectedPhoto = nil
            selectedImage = nil
            newCollectionName = ""
            selectedCollectionID = nil
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveSuccess = false }
        }
    }
}

struct ExtractedTermRow: View {
    @Binding var term: ExtractedTerm
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    TextField("Term", text: $term.word)
                        .font(AppFonts.heading(15))
                    TextField("Definition", text: $term.definition)
                        .font(AppFonts.body())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if isExpanded {
                TextField("Notes (optional)", text: $term.notes)
                    .font(AppFonts.caption())
                    .foregroundStyle(.secondary)
            }

            Button(isExpanded ? "Less" : "Add notes") {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            }
            .font(AppFonts.caption(11))
            .foregroundStyle(AppColors.primary)
        }
        .cardStyle(padding: 14)
    }
}
