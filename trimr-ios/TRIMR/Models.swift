import Foundation

struct Haircut: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: String  // asset name (local)
    let referenceFile: String  // filename in the `reference-haircuts` Supabase storage bucket

    init(name: String, image: String, referenceFile: String) {
        self.name = name
        self.image = image
        self.referenceFile = referenceFile
    }

    /// Public URL for the AI try-on reference image.
    var referenceUrl: URL {
        TrimrConfig.supabaseURL.appendingPathComponent("storage/v1/object/public/reference-haircuts/\(referenceFile)")
    }
}

enum SavedKind: String, Codable, Hashable {
    case analysis = "analysis"
    case hairstyleTryon = "hairstyle-tryon"
    case hairColor = "hair-color"
}

struct SavedProduct: Codable, Hashable {
    let name: String
    let purpose: String
}

struct CompatibilityBreakdown: Codable, Hashable {
    let faceShapeMatch: Int?
    let hairTextureMatch: Int?
    let ageAppropriateness: Int?
    let maintenance: Int?
    let trendScore: Int?
    let stylingDifficulty: Int?
}

struct SavedCut: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    /// Either a remote URL (FAL or signed Supabase URL) or a Supabase storage path
    /// (resolved into a signed URL by AppState.loadSavedCuts before this struct is shown).
    let image: String
    let storagePath: String?
    let score: Int?
    let faceShape: String?
    let whyItWorks: String?
    let barberInstructions: String?
    let stylingTips: [String]?
    let products: [SavedProduct]?
    let compatibilityBreakdown: CompatibilityBreakdown?
    let createdAt: Date?

    var kind: SavedKind {
        if score != nil || whyItWorks != nil || barberInstructions != nil || compatibilityBreakdown != nil {
            return .analysis
        }
        if name.lowercased().contains("hair color") { return .hairColor }
        return .hairstyleTryon
    }
}

struct HaircutResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let stars: Int
    let why: String
    let script: String
    let image: String
}

struct BannerItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let sub: String
    let cta: String
    let image: String
    let target: BannerTarget
    enum BannerTarget: Hashable { case analyze, tryon, haircolor }
}

struct Product: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let sub: String
    let image: String
}

struct HairColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: UInt32
    let image: String
}

enum CatalogData {
    static let banners: [BannerItem] = [
        .init(title: "Face Analysis & Hairstyle Recommendation", sub: "Find the perfect cut based on your features.", cta: "Try Now", image: "Analyse",   target: .analyze),
        .init(title: "Change Hairstyle",                         sub: "Try new hairstyles on your own photo.",       cta: "Try Now", image: "Tryon",     target: .tryon),
        .init(title: "Hair Color Lab",                           sub: "Try on different hair colors.",                cta: "Try Now", image: "Haircolor", target: .haircolor),
    ]

    static let inspo: [String] = ["Texturedfringe", "Edgarcut", "Fluffyhair", "Middlepart", "Sidepart", "Slickback"]

    static let tryOnCuts: [Haircut] = [
        .init(name: "Textured Fringe", image: "Texturedfringe", referenceFile: "Texturedfringe.jpg"),
        .init(name: "Edgar Cut",       image: "Edgarcut",       referenceFile: "Edgarcut.jpg"),
        .init(name: "Fluffy Hair",     image: "Fluffyhair",     referenceFile: "Fluffyhair.jpg"),
        .init(name: "Buzz Cut",        image: "Buzzcut",        referenceFile: "Buzzcut.jpg"),
        .init(name: "Slick Back",      image: "Slickback",      referenceFile: "Slickback.png"),
        .init(name: "Middle Part",     image: "Middlepart",     referenceFile: "Middlepart.jpg"),
        .init(name: "Middle Part Flow", image: "Middlepartflow", referenceFile: "Middlepartflow.jpg"),
        .init(name: "Side Part",       image: "Sidepart",       referenceFile: "Sidepart.png"),
        .init(name: "Waves",           image: "Modcut",         referenceFile: "Waves.jpg"),
        .init(name: "Curly Top",       image: "Curlytop",       referenceFile: "Curlytop.png"),
        .init(name: "Mod Cut",         image: "Waves",          referenceFile: "Modcut.png"),
        .init(name: "Afro Top",        image: "Afrotop",        referenceFile: "Afrotop.png"),
        .init(name: "Braids",          image: "Braids",         referenceFile: "Braids.png"),
        .init(name: "French Crop",     image: "Texturedfringe", referenceFile: "Frenchcrop.png"),
        .init(name: "Pompadour",       image: "Pompadour",      referenceFile: "Pompadour.jpg"),
        .init(name: "Quiff",           image: "Quiff",          referenceFile: "Quiff.jpg"),
        .init(name: "Crew Cut",        image: "Crewcut",        referenceFile: "Crewcut.jpg"),
        .init(name: "Comb Over",       image: "Combover",       referenceFile: "Combover.jpg"),
        .init(name: "Caesar Cut",      image: "Caesarcut",      referenceFile: "Caesarcut.jpg"),
        .init(name: "Faux Hawk",       image: "Fauxhawk",       referenceFile: "Fauxhawk.jpg"),
        .init(name: "Man Bun",         image: "Manbun",         referenceFile: "Manbun.jpg"),
        .init(name: "Mullet",          image: "Mullet",         referenceFile: "Mullet.jpg"),
    ]

    static let savedCuts: [Haircut] = [
        .init(name: "Textured Fringe", image: "Texturedfringe", referenceFile: "Texturedfringe.jpg"),
        .init(name: "Edgar Cut",       image: "Edgarcut",       referenceFile: "Edgarcut.jpg"),
        .init(name: "Fluffy Hair",     image: "Fluffyhair",     referenceFile: "Fluffyhair.jpg"),
        .init(name: "Buzz Cut",        image: "Buzzcut",        referenceFile: "Buzzcut.jpg"),
        .init(name: "Slick Back",      image: "Slickback",      referenceFile: "Slickback.png"),
        .init(name: "Middle Part",     image: "Middlepart",     referenceFile: "Middlepart.jpg"),
    ]

    static let analyzedCuts: [HaircutResult] = [
        .init(name: "Textured Fringe", stars: 5, why: "Adds length, perfectly balances your oval proportions.",
              script: "\"Mid skin fade, textured fringe on top, leave 2.5 inches. Piece-y finish.\"",
              image: "Texturedfringe"),
        .init(name: "Mid Skin Fade + Crop", stars: 4, why: "Clean modern lines, works great with your jawline width.",
              script: "\"Mid skin fade, disconnected on top, natural texture, no product in chair.\"",
              image: "Edgarcut"),
        .init(name: "Edgar Cut", stars: 4, why: "Low maintenance and flattering for your face proportions.",
              script: "\"Edgar cut, blunt fringe, skin fade on the sides, leave 2 inches on top.\"",
              image: "Edgarcut"),
    ]

    static let products: [Product] = [
        .init(name: "Hair Clay",      sub: "Strong hold · Matte finish",  image: "Hairclay"),
        .init(name: "Sea Salt Spray", sub: "Texture · Light hold",        image: "Seasaltpray"),
        .init(name: "Texture Powder", sub: "Volume · Natural finish",     image: "Texturepowder"),
        .init(name: "Pomade",         sub: "High shine · Medium hold",    image: "Pomade"),
    ]

    // Must match the `VALID_COLORS` list in supabase/functions/hair-color/index.ts
    static let hairColors: [HairColor] = [
        .init(name: "Jet Black",         hex: 0x0E0A06, image: "HCJetBlack"),
        .init(name: "Dark Brown",        hex: 0x3D2010, image: "HCDarkBrown"),
        .init(name: "Medium Brown",      hex: 0x6B4023, image: "HCMediumBrown"),
        .init(name: "Light Brown",       hex: 0x9A6B3F, image: "HCLightBrown"),
        .init(name: "Dirty Blonde",      hex: 0xB99565, image: "HCDirtyBlonde"),
        .init(name: "Blonde",            hex: 0xC8942A, image: "HCBlonde"),
        .init(name: "Platinum Blonde",   hex: 0xD4C9B0, image: "HCPlatinumBlonde"),
        .init(name: "Auburn",            hex: 0x8B3A2C, image: "HCAuburn"),
        .init(name: "Copper Red",        hex: 0xB55233, image: "HCCopperRed"),
        .init(name: "Grey / Silver",     hex: 0x9A9A9A, image: "HCGreySilver"),
        .init(name: "Ash Brown",         hex: 0x5E4F44, image: "HCAshBrown"),
        .init(name: "Ash Blonde",        hex: 0xB5AB94, image: "HCAshBlonde"),
    ]
}
