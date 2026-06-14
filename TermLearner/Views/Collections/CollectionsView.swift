import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \TermCollection.createdAt, order: .reverse) private var collections: [TermCollection]

    @State private var showAddCollection = false
    @State private var newName = ""
    @State private var selectedColor = collectionColors[0]
    @State private var searchText = ""
    @State private var selectedCollection: TermCollection?

    private var filtered: [TermCollection] {
        searchText.isEmpty
            ? collections
            : collections.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad / Mac: NavigationSplitView
                NavigationSplitView {
                    sidebarList
                } detail: {
                    if let col = selectedCollection {
                        CollectionDetailView(collection: col)
                    } else {
                        placeholderDetail
                    }
                }
            } else {
                // iPhone: standard NavigationStack
                NavigationStack {
                    Group {
                        if collections.isEmpty {
                            emptyState
                        } else {
                            phoneList
                        }
                    }
                    .background(AppColors.background)
                    .navigationTitle("Collections")
                    .searchable(text: $searchText, prompt: "Search collections")
                    .toolbar { addButton }
                    .sheet(isPresented: $showAddCollection) { addCollectionSheet }
                }
            }
        }
    }

    // MARK: - iPad sidebar

    private var sidebarList: some View {
        List(selection: $selectedCollection) {
            ForEach(filtered) { collection in
                CollectionRow(collection: collection)
                    .tag(collection)
                    .listRowBackground(AppColors.card)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete(perform: deleteCollections)
        }
        .listStyle(.sidebar)
        .navigationTitle("Collections")
        .searchable(text: $searchText, prompt: "Search collections")
        .toolbar { addButton }
        .sheet(isPresented: $showAddCollection) { addCollectionSheet }
    }

    private var placeholderDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.primary.opacity(0.25))
            Text("Select a Collection")
                .font(AppFonts.heading(22))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    // MARK: - iPhone list

    private var phoneList: some View {
        List {
            ForEach(filtered) { collection in
                NavigationLink(destination: CollectionDetailView(collection: collection)) {
                    CollectionRow(collection: collection)
                }
                .listRowBackground(AppColors.card)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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

    // MARK: - Shared UI

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAddCollection = true } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppColors.primary)
            }
        }
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
                                .overlay(Circle().stroke(.white, lineWidth: selectedColor == hex ? 3 : 0))
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
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddCollection = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let col = TermCollection(name: newName.trimmingCharacters(in: .whitespaces), colorHex: selectedColor)
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
        for i in offsets { modelContext.delete(filtered[i]) }
        try? modelContext.save()
    }
}
