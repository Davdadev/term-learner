import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let collection: TermCollection

    @State private var searchText = ""
    @State private var showStudy = false
    @State private var filterMode: FilterMode = .all
    @State private var termToEdit: Term?
    @State private var showAddTerm = false

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case due = "Due"
        case learned = "Learned"
        case new = "New"
    }

    private var filtered: [Term] {
        var terms = collection.terms
        if !searchText.isEmpty {
            terms = terms.filter {
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch filterMode {
        case .all: break
        case .due: terms = terms.filter { $0.isDueForReview }
        case .learned: terms = terms.filter { $0.isLearned }
        case .new: terms = terms.filter { $0.masteryLevel == 0 }
        }
        return terms.sorted { $0.word < $1.word }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBanner
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColors.background)

                List {
                    if filtered.isEmpty {
                        Text("No terms match this filter.")
                            .font(AppFonts.body())
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    }
                    ForEach(filtered) { term in
                        Button {
                            termToEdit = term
                        } label: {
                            TermRowView(term: term)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppColors.card)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete(perform: deleteTerms)
                }
                .listStyle(.plain)
            }
            .background(AppColors.background)
            .searchable(text: $searchText, prompt: "Search terms")
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showAddTerm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        if !collection.terms.filter({ $0.isDueForReview }).isEmpty {
                            Button {
                                showStudy = true
                            } label: {
                                Label("Study", systemImage: "play.fill")
                            }
                        }
                    }
                    .foregroundStyle(AppColors.primary)
                }
            }
            .fullScreenCover(isPresented: $showStudy) {
                StudyView(terms: collection.terms.filter { $0.isDueForReview })
            }
            .sheet(item: $termToEdit) { term in
                TermEditSheet(term: term)
            }
            .sheet(isPresented: $showAddTerm) {
                AddTermSheet(collection: collection)
            }
        }
    }

    private var headerBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(collection.termCount) Terms")
                        .font(AppFonts.title(28))
                        .foregroundStyle(.white)
                    Text("\(collection.learnedCount) learned · \(collection.dueCount) due")
                        .font(AppFonts.caption())
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                ProgressRing(progress: collection.progress, color: .white, size: 64)
                    .overlay(
                        Text("\(Int(collection.progress * 100))%")
                            .font(AppFonts.caption(13))
                            .foregroundStyle(.white)
                    )
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: collection.colorHex), Color(hex: collection.colorHex).opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Button {
                    filterMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(AppFonts.caption(13))
                        .foregroundStyle(filterMode == mode ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(filterMode == mode ? Color(hex: collection.colorHex) : AppColors.card)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25), value: filterMode)
            }
            Spacer()
        }
    }

    private func deleteTerms(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(filtered[i])
        }
        try? modelContext.save()
    }
}

struct TermEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let term: Term

    @State private var word: String
    @State private var definition: String
    @State private var notes: String

    init(term: Term) {
        self.term = term
        _word = State(initialValue: term.word)
        _definition = State(initialValue: term.definition)
        _notes = State(initialValue: term.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Term") {
                    TextField("Word", text: $word)
                    TextField("Definition", text: $definition)
                    TextField("Notes (optional)", text: $notes)
                }
                Section("Mastery") {
                    HStack {
                        Text("Level")
                        Spacer()
                        MasteryBadge(level: term.masteryLevel)
                    }
                    HStack {
                        Text("Correct")
                        Spacer()
                        Text("\(term.timesCorrect)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Incorrect")
                        Spacer()
                        Text("\(term.timesIncorrect)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Next Review")
                        Spacer()
                        Text(term.nextReviewDate.relativeDisplay)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Term")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        term.word = word
                        term.definition = definition
                        term.notes = notes
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(word.isEmpty || definition.isEmpty)
                }
            }
        }
    }
}

struct AddTermSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let collection: TermCollection

    @State private var word = ""
    @State private var definition = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Term") {
                    TextField("Word or phrase", text: $word)
                    TextField("Definition or translation", text: $definition)
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Term")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let term = Term(word: word, definition: definition, notes: notes)
                        term.collection = collection
                        modelContext.insert(term)
                        collection.terms.append(term)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(word.isEmpty || definition.isEmpty)
                }
            }
        }
    }
}
