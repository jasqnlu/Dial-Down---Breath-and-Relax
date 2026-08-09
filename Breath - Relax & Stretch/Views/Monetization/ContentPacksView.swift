import SwiftUI

// MARK: - ContentPacksView
// Themed collections, all free. Kept as a browsing surface only — there
// is no purchase concept anywhere in the app.

struct ContentPacksView: View {

    var body: some View {
        List {
            ForEach(ContentPack.all) { pack in
                packSection(pack)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.luminaSurface)
        .listRowBackground(Color.luminaCardFill)
        .navigationTitle("Content Packs")
        .navigationBarTitleDisplayMode(.inline)
        .floatingTabBarClearance()
    }

    private func packSection(_ pack: ContentPack) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: pack.icon)
                    .font(.title2)
                    .foregroundStyle(Color.luminaPrimary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pack.title).font(.luminaCardTitle).foregroundStyle(Color.luminaOnSurface)
                    Text(pack.summary)
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                    Text("\(pack.exerciseNames.count) exercises included")
                        .font(.luminaCaption)
                        .foregroundStyle(Color.luminaOnSurfaceVariant)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ContentPacksView()
    }
}
