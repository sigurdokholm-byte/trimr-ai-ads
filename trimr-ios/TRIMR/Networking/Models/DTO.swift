import Foundation

/// Placeholder for edge-function calls we don't need a typed response from.
/// `functions.invoke` in supabase-swift requires an explicit `Decodable` return.
struct EmptyResponse: Decodable {}

// MARK: - Profile

struct ProfileDTO: Codable, Equatable {
    let userId: UUID
    var name: String?
    var email: String?
    var subscriptionTier: String
    var lookCredits: Int
    var analysisCount: Int
    var hairstyleTryonCount: Int
    var hairColorTryonCount: Int
    var appleExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case email
        case subscriptionTier = "subscription_tier"
        case lookCredits = "look_credits"
        case analysisCount = "analysis_count"
        case hairstyleTryonCount = "hairstyle_tryon_count"
        case hairColorTryonCount = "hair_color_tryon_count"
        case appleExpiresAt = "apple_expires_at"
    }

    var isPro: Bool { subscriptionTier == "pro" }
}

// MARK: - Subscription check (returned by check-subscription edge fn)

struct SubscriptionStatus: Codable {
    let subscribed: Bool
    let tier: String
    let subscriptionEnd: Date?

    enum CodingKeys: String, CodingKey {
        case subscribed
        case tier
        case subscriptionEnd = "subscription_end"
    }
}

// MARK: - Face analysis

struct AnalyzeRequest: Encodable {
    let image: String  // base64 data URL
    let preferences: [String: String]?
    let count: Int = 1
    /// Try-on mode: the catalog cut the user chose (nil for custom-reference uploads).
    var targetStyle: String? = nil
    /// Try-on mode: reference hairstyle image URL. Presence switches the edge fn to assess-the-chosen-cut.
    var referenceUrl: String? = nil
}

struct AnalyzeResponse: Decodable {
    let faceShape: String
    let faceDescription: String?
    let conclusion: String?
    let recommendation: Recommendation
    let imageGenerationFailed: Bool?

    struct Recommendation: Decodable {
        let name: String
        let rating: Int
        let description: String?
        let whyItWorks: String?
        let fadeRecommendation: String?
        let barberInstructions: String?
        let stylingTips: [String]?
        let products: [ProductSuggestion]?
        let generatedImage: String?
        let storagePath: String?
        let compatibilityBreakdown: CompatibilityBreakdown?
    }

    struct ProductSuggestion: Decodable {
        let name: String
        let purpose: String
    }

    enum CodingKeys: String, CodingKey {
        case faceShape, faceDescription, conclusion, recommendation, imageGenerationFailed
    }
}

// MARK: - Try-on (hairstyle)

struct HairstyleTryonRequest: Encodable {
    let userImage: String   // base64 data URL
    let referenceUrl: String
    let styleName: String

    enum CodingKeys: String, CodingKey {
        case userImage = "userImage"
        case referenceUrl = "referenceUrl"
        case styleName = "styleName"
    }
}

struct TryonResponse: Decodable {
    let imageUrl: String
    let storagePath: String?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "imageUrl"
        case storagePath = "storagePath"
    }
}

// MARK: - Hair colour

struct HairColorRequest: Encodable {
    let image: String     // base64 data URL
    let color: String     // colour name, e.g. "Platinum"
}

// MARK: - Saved haircuts

struct SavedHaircutRow: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let haircutName: String
    let score: Int?
    let faceShape: String?
    let whyItWorks: String?
    let barberInstructions: String?
    let stylingTips: [String]?
    let products: [SavedProduct]?
    let compatibilityBreakdown: CompatibilityBreakdown?
    let generatedImage: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case haircutName = "haircut_name"
        case score
        case faceShape = "face_shape"
        case whyItWorks = "why_it_works"
        case barberInstructions = "barber_instructions"
        case stylingTips = "styling_tips"
        case products
        case compatibilityBreakdown = "compatibility_breakdown"
        case generatedImage = "generated_image"
        case createdAt = "created_at"
    }
}

// MARK: - save-to-library edge function

struct SaveToLibraryRequest: Encodable {
    let kind: String
    let imageUrl: String?
    let haircutName: String
    let score: Int?
    let faceShape: String?
    let whyItWorks: String?
    let barberInstructions: String?
    let stylingTips: [String]?
    let products: [SavedProduct]?
    let compatibilityBreakdown: CompatibilityBreakdown?
}

// MARK: - Apple IAP validation

struct AppleIAPValidateRequest: Encodable {
    let signedTransaction: String   // JWS from StoreKit 2
    let productId: String
}

struct AppleIAPValidateResponse: Decodable {
    let success: Bool
    let tier: String?
    let looksAdded: Int?
    let appleExpiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case success, tier
        case looksAdded = "looks_added"
        case appleExpiresAt = "apple_expires_at"
    }
}

// MARK: - Anonymous → real account merge

struct MergeAnonRequest: Encodable {
    let anonymousAccessToken: String
    let anonymousRefreshToken: String
}

struct MergeAnonResponse: Decodable {
    let success: Bool
    let creditsMerged: Int?
    let transactionsReassigned: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case creditsMerged = "credits_merged"
        case transactionsReassigned = "transactions_reassigned"
    }
}
