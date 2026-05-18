import SwiftUI

/// Shared image loader for the Library, with three caching layers + background decode:
///
/// 1. **In-memory `NSCache`** of fully-decoded `UIImage`s — repeat appears skip the
///    decode entirely (the most expensive step on the main thread).
/// 2. **Disk-backed `URLCache`** — survives across app launches; handles bytes only.
/// 3. **`data:` URI fast path** — base64-decoded directly on a background task,
///    bypassing `URLSession` entirely (legacy saves can be hundreds of KB inline).
///
/// Decoding + `preparingForDisplay()` runs on a detached background task so scroll
/// stays smooth even when several cells materialize at once.
enum LibraryImageCache {
    static let session: URLSession = {
        let cache = URLCache(memoryCapacity: 32 * 1024 * 1024,
                             diskCapacity:   256 * 1024 * 1024,
                             directory: nil)
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = cache
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.timeoutIntervalForRequest = 15
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    static let memory: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 200
        c.totalCostLimit = 64 * 1024 * 1024 // ~64 MB of decoded bitmaps
        return c
    }()

    /// Decode + display-prep off the main thread. `preparingForDisplay()` forces
    /// CoreGraphics to do its decode work now instead of on the next render pass,
    /// which is what causes the visible hitch when a cell scrolls into view.
    static func decode(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let raw = UIImage(data: data) else { return nil }
            return raw.preparingForDisplay() ?? raw
        }.value
    }
}

struct CachedAsyncImage: View {
    let url: URL
    var contentMode: ContentMode = .fill

    @State private var phase: Phase
    @State private var attempt: Int = 0

    enum Phase { case loading, success(UIImage), failure }

    init(url: URL, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
        // Hit the in-memory cache synchronously so recycled cells don't blink
        // through the loading state on every scroll-back.
        if let cached = LibraryImageCache.memory.object(forKey: url as NSURL) {
            self._phase = State(initialValue: .success(cached))
        } else {
            self._phase = State(initialValue: .loading)
        }
    }

    var body: some View {
        ZStack {
            switch phase {
            case .loading:
                Rectangle().fill(Theme.surface)
                    .overlay(ProgressView().tint(Theme.gold))
            case .success(let image):
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                Rectangle().fill(Theme.surface)
                    .overlay(VStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                        Text("Tap to retry")
                            .font(TFont.body(10, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    })
                    .contentShape(Rectangle())
                    .onTapGesture { attempt += 1 }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: TaskKey(url: url, attempt: attempt)) { await load() }
    }

    private struct TaskKey: Hashable { let url: URL; let attempt: Int }

    private func load() async {
        // Memory cache — cheap, synchronous, almost always the right answer
        // for a re-appearing cell.
        if let cached = LibraryImageCache.memory.object(forKey: url as NSURL) {
            if case .success = phase { return }
            phase = .success(cached)
            return
        }

        // data: URI — decode the base64 directly. Going through URLSession works
        // but allocates an entire request/response just to round-trip the bytes.
        if url.scheme == "data" {
            if let img = await Self.decodeDataURI(url) {
                LibraryImageCache.memory.setObject(img, forKey: url as NSURL, cost: cost(of: img))
                phase = .success(img)
            } else {
                print("[LibraryImage] data URI decode failed")
                phase = .failure
            }
            return
        }

        // Network path — bytes from URLCache (disk) or origin, then off-main decode.
        var req = URLRequest(url: url)
        req.cachePolicy = .returnCacheDataElseLoad
        do {
            let (data, response) = try await LibraryImageCache.session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                print("[LibraryImage] HTTP \(http.statusCode) for \(url.absoluteString)")
                phase = .failure
                return
            }
            if let img = await LibraryImageCache.decode(data) {
                LibraryImageCache.memory.setObject(img, forKey: url as NSURL, cost: cost(of: img))
                phase = .success(img)
            } else {
                print("[LibraryImage] decode failed for \(url.absoluteString)")
                phase = .failure
            }
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                print("[LibraryImage] load failed:", url.absoluteString, "—", error.localizedDescription)
            }
            phase = .failure
        }
    }

    private func cost(of img: UIImage) -> Int {
        Int(img.size.width * img.size.height * img.scale * img.scale * 4)
    }

    private static func decodeDataURI(_ url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let s = url.absoluteString
            guard let comma = s.firstIndex(of: ",") else { return nil }
            let payload = String(s[s.index(after: comma)...])
            guard let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters),
                  let raw = UIImage(data: data) else { return nil }
            return raw.preparingForDisplay() ?? raw
        }.value
    }
}

struct LibraryView: View {
    @State private var grid: Bool = true
    @State private var detailCut: SavedCut?
    @State private var fullscreenCut: SavedCut?
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                if app.savedCuts.isEmpty {
                    emptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                } else {
                    if grid {
                        let cols = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
                        LazyVGrid(columns: cols, spacing: 10) {
                            ForEach(app.savedCuts) { cut in tile(cut, grid: true) }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(app.savedCuts) { cut in tile(cut, grid: false) }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Spacer().frame(height: 110)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .task { await app.loadSavedCuts() }
        .refreshable { await app.loadSavedCuts(force: true) }
        .sheet(item: $detailCut) { cut in
            LibraryDetailView(cut: cut, onDelete: { app.removeSavedCut(cut) })
        }
        .fullScreenCover(item: $fullscreenCut) { cut in
            LibraryFullscreenImage(
                imageUrl: cut.image,
                title: cut.name,
                onDelete: { app.removeSavedCut(cut) }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(TFont.display(26))
                    .tracking(-0.4)
                    .foregroundStyle(Theme.text)
            }
            Spacer()
            if !app.savedCuts.isEmpty {
                Button { grid.toggle() } label: {
                    Image(systemName: grid ? "square.grid.2x2.fill" : "list.bullet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 38, height: 38)
                        .background(Theme.card)
                        .overlay(Circle().stroke(Theme.border))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func savedImage(_ raw: String) -> some View {
        if let url = URL(string: raw), !raw.isEmpty {
            CachedAsyncImage(url: url)
        } else {
            Rectangle().fill(Theme.surface)
                .overlay(Image(systemName: "photo").foregroundStyle(Theme.muted))
        }
    }

    private func tile(_ cut: SavedCut, grid: Bool) -> some View {
        Button {
            switch cut.kind {
            case .analysis:
                detailCut = cut
            case .hairstyleTryon, .hairColor:
                fullscreenCut = cut
            }
        } label: {
            // Color.clear is the size enforcer: it accepts whatever bounds the
            // LazyVGrid column proposes, then aspectRatio locks it to 3:4 (or
            // 16:7 in list mode). Every overlay below paints into that exact
            // bounded box, so the image truly fills the cell and all cells
            // come out the same height.
            Color.clear
                .aspectRatio(grid ? 3.0/4.0 : 16.0/7.0, contentMode: .fit)
                .overlay(
                    savedImage(cut.image)
                        .clipped()
                )
                .overlay(
                    LinearGradient(colors: [.clear, .clear, Color(hex: 0x080604).opacity(0.9)],
                                   startPoint: .top, endPoint: .bottom)
                        .allowsHitTesting(false)
                )
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        Text(cut.name)
                            .font(TFont.body(13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: cut.kind == .analysis ? "doc.text.magnifyingglass" : "bookmark.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.35))
                }
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border))
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                app.removeSavedCut(cut)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.1))
                Image(systemName: "bookmark")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Theme.gold)
            }
            .frame(width: 78, height: 78)

            VStack(spacing: 6) {
                Text("No cuts saved yet")
                    .font(TFont.display(18))
                    .tracking(-0.2)
                    .foregroundStyle(Theme.text)
                Text("Tap Save on any result to keep it here.")
                    .font(TFont.body(13))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }

            Button {
                app.activeTab = .analyze
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Analyse my face")
                        .font(TFont.body(13, weight: .semibold))
                }
                .foregroundStyle(Color(hex: 0x0A0804))
                .padding(.horizontal, 18).padding(.vertical, 11)
                .background(Theme.goldGlow)
                .clipShape(Capsule())
                .shadow(color: Theme.gold.opacity(0.3), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
