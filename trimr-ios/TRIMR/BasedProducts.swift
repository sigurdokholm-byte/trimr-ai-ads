import SwiftUI

struct BasedProduct: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let sub: String
    let image: String
    let shop: String
    let url: URL
}

enum BasedProducts {
    private static let affiliateRef = "?ref=wemlazazc"

    private static func based(_ slug: String) -> URL {
        URL(string: "https://basedbodyworks.com/products/\(slug)\(affiliateRef)")!
    }

    static let catalog: [String: BasedProduct] = [
        "texturePowder": BasedProduct(name: "Based - Texture Powder",       sub: "Instant texture & volume",        image: "Texturepowder",     shop: "BASED", url: based("texture-powder")),
        "seaSaltSpray":  BasedProduct(name: "Based - Sea Salt Spray",       sub: "Fluffy, beachy texture",          image: "Seasaltpray",       shop: "BASED", url: based("sea-salt-spray")),
        "hairClay":      BasedProduct(name: "Based - Hair Clay",            sub: "Matte texture & strong hold",     image: "Hairclay",          shop: "BASED", url: based("hair-clay")),
        "pomade":        BasedProduct(name: "Based - Pomade",               sub: "Wet, slicked, shiny finish",      image: "Pomade",            shop: "BASED", url: based("pomade")),
        "leaveIn":       BasedProduct(name: "Based - Leave-In Conditioner", sub: "Deep hydration & frizz control",  image: "Leaveinconditinor", shop: "BASED", url: based("leave-in-conditioner")),
        "curlCream":     BasedProduct(name: "Based - Curl Cream",           sub: "Curl definition & hold",          image: "Curlcream",         shop: "BASED", url: based("curl-cream")),
        "curlMousse":    BasedProduct(name: "Based - Curl Mousse",          sub: "Volume & curl definition",        image: "Curlmousse",        shop: "BASED", url: based("curl-mousse")),
        "curlGel":       BasedProduct(name: "Based - Curl Gel",             sub: "Maximum curl hold & definition",  image: "Curlgel",           shop: "BASED", url: based("curl-gel")),
    ]

    private static let styleMap: [String: [String]] = [
        "Textured Fringe": ["hairClay", "seaSaltSpray"],
        "Edgar Cut":       ["pomade", "texturePowder"],
        "Curly Top":       ["curlCream", "leaveIn"],
        "Fluffy Hair":     ["curlMousse", "seaSaltSpray"],
        "Slick Back":      ["pomade", "leaveIn"],
        "Side Part":       ["pomade", "hairClay"],
        "Middle Part":     ["seaSaltSpray", "hairClay"],
        "Buzz Cut":        ["leaveIn", "texturePowder"],
        "Afro Top":        ["curlCream", "curlMousse"],
        "Braids":          ["leaveIn", "curlCream"],
        "Waves":           ["pomade", "seaSaltSpray"],
        "Mod Cut":         ["hairClay", "seaSaltSpray"],
        "French Crop":     ["hairClay", "texturePowder"],
    ]

    static func products(for styleName: String) -> [BasedProduct] {
        if let keys = styleMap[styleName] {
            return keys.compactMap { catalog[$0] }
        }
        let n = styleName.lowercased()
        let keys: [String]
        if n.range(of: #"curl|afro|coil|kink"#, options: .regularExpression) != nil { keys = ["curlCream", "curlMousse"] }
        else if n.range(of: #"braid|twist|loc"#, options: .regularExpression) != nil { keys = ["leaveIn", "curlCream"] }
        else if n.range(of: #"wave"#, options: .regularExpression) != nil { keys = ["pomade", "seaSaltSpray"] }
        else if n.range(of: #"slick|executive|business|pomp"#, options: .regularExpression) != nil { keys = ["pomade", "leaveIn"] }
        else if n.range(of: #"buzz|crew|induction|short"#, options: .regularExpression) != nil { keys = ["leaveIn", "texturePowder"] }
        else if n.range(of: #"fringe|crop|caesar|french"#, options: .regularExpression) != nil { keys = ["hairClay", "texturePowder"] }
        else if n.range(of: #"quiff|messy|textured|tousle|fluff"#, options: .regularExpression) != nil { keys = ["hairClay", "seaSaltSpray"] }
        else if n.range(of: #"mid|middle|curtain"#, options: .regularExpression) != nil { keys = ["seaSaltSpray", "hairClay"] }
        else if n.range(of: #"side part|ivy|taper"#, options: .regularExpression) != nil { keys = ["pomade", "hairClay"] }
        else { keys = ["hairClay", "seaSaltSpray"] }
        return keys.compactMap { catalog[$0] }
    }
}

struct BasedProductsBlock: View {
    let products: [BasedProduct]

    var body: some View {
        if products.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                    Text("RECOMMENDED PRODUCTS")
                        .font(TFont.mono(10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Theme.text)
                }
                .padding(.bottom, 14)

                VStack(spacing: 10) {
                    ForEach(products) { p in
                        Link(destination: p.url) {
                            HStack(spacing: 12) {
                                Image(p.image).resizable().scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .padding(6)
                                    .background(Color(hex: 0x0F0B07))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(p.name)
                                        .font(TFont.body(12, weight: .semibold))
                                        .foregroundStyle(Theme.text)
                                        .lineLimit(2)
                                    Text(p.sub)
                                        .font(TFont.body(10))
                                        .foregroundStyle(Theme.muted)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        Text("SHOP ON \(p.shop)")
                                            .font(TFont.mono(8, weight: .bold))
                                            .tracking(1.2)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    .foregroundStyle(Theme.text)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("AFFILIATE · WE EARN A COMMISSION ON BASED PURCHASES")
                    .font(TFont.mono(8))
                    .tracking(1.3)
                    .foregroundStyle(Theme.muted2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .padding(EdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: 0x0A0A0A))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
