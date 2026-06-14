import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TermCollection.createdAt, order: .reverse) private var collections: [TermCollection]

    @State private var showAddCollection = false
    @State private var newName = ""
    @State private var selectedColor = collectionColors[0]
    @State private var searchText = ""

    private var filtered: [TermCollection] {
        searchText.isEmpty
            ? collections
            : collections.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if collections.isEmpty {
                    emptyState
                } else {
                    collectionList
                }
            }
            .background(AppColors.background)
            .navigationTitle("Collections")
            .searchable(text: $searchText, prompt: "Search collections")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCollection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddCollection) {
                addCollectionSheet
            }
        }
    }

    private var collectionList: some View {
        List {
            ForEach(filtered) { collection in
                NavigationLink(destination: CollectionDetailView(collection: collection)) {
                    CollectionRow(collection: collection)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteCollections)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary.opacity(0.3))
            Text("No Collections Yet")
                .font(AppFonts.title(24))
            Text("Upload images of vocabulary terms to create your first collection.")
                .font(AppFonts.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var addCollectionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("Collection name", text: $newName)
                    .font(AppFonts.heading())
                    .padding(16)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Colour")
                        .font(AppFonts.caption())
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(collectionColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .shadow(color: Color(hex: hex).opacity(0.4), radius: selectedColor == hex ? 6 : 0)
                                .onTapGesture { selectedColor = hex }
                                .animation(.spring(response: 0.3), value: selectedColor)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
            .background(AppColors.background)
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddCollection = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let col = TermCollection(
                            name: newName.trimmingCharacters(in: .whitespaces),
                            colorHex: selectedColor
                        )
                        modelContext.insert(col)
                        try? modelContext.save()
                        newName = ""
                        showAddCollection = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func deleteCollections(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(filtered[i])
        }
        try? modelContext.save()
    }
}
