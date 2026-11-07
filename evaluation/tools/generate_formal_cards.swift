import Accelerate
import AppKit
import CoreText
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum GenerationError: Error {
    case usage, outputExists(URL), missingFont(String), missingGlyph(String, String)
    case lineOverflow(String), renderFailed, encodeFailed(URL)
}

struct Random {
    var state: UInt64

    mutating func pick(_ count: Int) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Int((state >> 32) % UInt64(count))
    }
}

struct Sample: Encodable {
    let sample_id: String
    let image: String
    let card_type: String
    let split = "formal"
    let verified = true
    let fields: [String: [String]]
}

struct Variant: Encodable {
    let angle_degrees: Double
    let blur_radius_px: Int
    let contrast: Double
    let render_scale: Double
    let patterned_background: Bool
}

struct ManifestEntry: Encodable {
    let sample_id: String
    let image: String
    let sha256: String
    let clear_image: String?
    let clear_sha256: String?
    let width_px: Int
    let height_px: Int
    let name_font_pt: Int
    let detail_font_pt: Int
    let palette_index: Int
    let layout: String
    let difficulty: String
    let field_order: [String]
    let variant: Variant
}

struct Manifest: Encodable {
    let schema_version = 1
    let seed: UInt64
    let fonts: [String]
    let macos_version: String
    let challenge_card_scale: Double
    let samples: [ManifestEntry]
}

let fieldKeys = ["name", "company", "job_title", "mobile", "office", "fax",
                 "other_phone", "email", "website", "address"]
let chineseNames = ["岑星禾", "郁见川", "仇云岫", "申予棠", "伏澄野", "蔺书遥", "商砚宁", "纪南霁"]
let englishNames = ["Avery Quillmere", "Rowan Vellstrand", "Ellis Fernwick", "Jules Amberfen",
                    "Mira Thornfold", "Morgan Wrenvale", "Tessa Brindlepath", "Sage Mossquay"]
let chineseJobs = ["产品设计师", "研发主管", "客户经理", "视觉设计师", "技术顾问", "质量工程师"]
let englishJobs = ["Product Designer", "Engineering Lead", "Account Manager", "Visual Designer",
                   "Technical Consultant", "Quality Engineer"]
let chineseCompanies = ["砂月", "雾杉", "星绢", "青砾", "苔舟", "雪缎", "墨穗", "霜灯"]
let englishCompanies = ["Sandmoon", "Mistcedar", "Starsilk", "Jadegrit", "Mossboat", "Snowweave", "Inkgrain", "Frostlamp"]
let labelKeys = ["mobile", "office", "fax", "other_phone", "email", "website", "address"]
let chineseLabels = ["手机", "办公电话", "传真", "其他电话", "邮箱", "网站", "地址"]
let englishLabels = ["Mobile", "Office", "Fax", "Other", "Email", "Website", "Address"]
let palettes: [(paper: UInt32, ink: UInt32, accent: UInt32)] = [
    (0xF6F3ED, 0x152842, 0x386D8B), (0xEFF6F2, 0x173A32, 0x29755F),
    (0xF7F0F6, 0x402943, 0x864C79), (0xFCF3E8, 0x38271F, 0xA94F2D),
    (0x182735, 0xF4F6F4, 0x8ACDC7), (0x29302A, 0xF8F5E7, 0xDABD78)
]
let seed: UInt64 = 20261106
let challengeCardScale = 0.80
let fontNames = ["HiraginoSansGB-W3", "HelveticaNeue"]

func color(_ rgb: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((rgb >> 16) & 255) / 255,
            green: CGFloat((rgb >> 8) & 255) / 255,
            blue: CGFloat(rgb & 255) / 255, alpha: alpha)
}

func values(for index: Int, language: Int) -> [String: [String]] {
    let j = (index - 1) % 8
    let number = String(format: "%02d", index)
    let shifted = (j + (index - 1) / 8) % chineseNames.count
    let person = String(chineseNames[j].prefix(1)) + chineseNames[shifted].dropFirst()
    let given = englishNames[j].split(separator: " ")[0]
    let surname = englishNames[shifted].split(separator: " ")[1]
    let personEN = "\(given) \(surname)"
    let company = chineseCompanies[j] + "虚构实验室"
    let companyEN = englishCompanies[j] + " Fiction Lab"
    let job = (index - 1) % chineseJobs.count
    func localized(_ zh: String, _ en: String) -> String {
        language == 0 ? zh : language == 1 ? en : zh + " / " + en
    }

    var fields = Dictionary(uniqueKeysWithValues: fieldKeys.map { ($0, [String]()) })
    fields["name"] = [localized(person, personEN)]
    fields["company"] = [localized(company, companyEN)]
    if index % 5 != 0 { fields["job_title"] = [localized(chineseJobs[job], englishJobs[job])] }
    fields["mobile"] = ["+1 202-555-01" + number]
    if index % 3 != 0 { fields["office"] = ["+1 212-555-01" + number] }
    if index % 4 == 0 { fields["fax"] = ["+1 415-555-01" + number] }
    if index % 9 == 0 { fields["other_phone"] = ["+1 617-555-01" + number] }
    if index % 6 != 0 {
        fields["email"] = ["card\(number)@slice.example"]
        if index % 4 == 1 { fields["email", default: []].append("desk\(number)@slice.example") }
    }
    if index % 4 != 2 { fields["website"] = ["https://card\(number).slice.example"] }
    if index % 7 != 0 {
        fields["address"] = [localized("虚构云屿市纸舟路\(index)号", "\(index) Paperboat Lane, Fiction Borough")]
    }
    return fields
}

func attributes(_ text: String, size: CGFloat, ink: NSColor) throws -> [NSAttributedString.Key: Any] {
    let fontName = text.unicodeScalars.contains { $0.value > 127 } ? fontNames[0] : fontNames[1]
    guard let font = NSFont(name: fontName, size: size) else { throw GenerationError.missingFont(fontName) }
    let ctFont = CTFontCreateWithName(fontName as CFString, size, nil)
    let characters = Array(text.utf16)
    var glyphs = [CGGlyph](repeating: 0, count: characters.count)
    guard CTFontGetGlyphsForCharacters(ctFont, characters, &glyphs, characters.count) else {
        throw GenerationError.missingGlyph(fontName, text)
    }
    return [.font: font, .foregroundColor: ink]
}

func draw(_ text: String, x: CGFloat, top: CGFloat, size: CGFloat, width: CGFloat, ink: NSColor) throws {
    let attrs = try attributes(text, size: size, ink: ink)
    let string = NSAttributedString(string: text, attributes: attrs)
    let bounds = string.size()
    guard bounds.width <= width else { throw GenerationError.lineOverflow(text) }
    string.draw(at: CGPoint(x: x, y: top - bounds.height))
}

func makeContext(width: Int, height: Int) throws -> CGContext {
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: space,
                                  bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw GenerationError.renderFailed
    }
    return context
}

func drawCard(width: Int, height: Int, fields: [String: [String]], paletteIndex: Int,
              language: Int, layout: String, nameSize: Int, detailSize: Int,
              fieldOrder: [String], pattern: Bool) throws -> CGImage {
    let context = try makeContext(width: width, height: height)
    let w = CGFloat(width), h = CGFloat(height)
    let palette = palettes[paletteIndex]
    let ink = color(palette.ink)
    context.setFillColor(color(palette.paper).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: w, height: h))
    context.setFillColor(color(palette.accent).cgColor)
    context.fill(CGRect(x: 0, y: h - 14, width: w, height: 14))
    if pattern {
        context.setFillColor(color(palette.accent, alpha: 0.15).cgColor)
        for row in 0..<12 {
            for column in 0..<15 {
                context.fillEllipse(in: CGRect(x: CGFloat(column) * w / 15 + CGFloat(row % 2) * 16,
                                               y: CGFloat(row) * h / 12, width: 22, height: 12))
            }
        }
    }
    context.setStrokeColor(color(palette.accent, alpha: 0.5).cgColor)
    context.setLineWidth(2)
    context.move(to: CGPoint(x: 48, y: h - 192))
    context.addLine(to: CGPoint(x: w - 48, y: h - 192))
    context.strokePath()

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

    let nameFirst = layout != "company_first" && layout != "split_columns"
    let identity = nameFirst ? ["name", "company", "job_title"] : ["company", "name", "job_title"]
    var top = h - 42
    for key in identity {
        guard let text = fields[key]?.first else { continue }
        let size = CGFloat(key == "name" ? nameSize : detailSize + 3)
        try draw(text, x: 48, top: top, size: size, width: w - 96, ink: ink)
        top -= size + 15
    }

    let lineHeight = CGFloat(detailSize + 14)
    var contactTop = h - 214
    var secondaryTop = contactTop
    for key in fieldOrder {
        guard let field = labelKeys.firstIndex(of: key), let items = fields[key] else { continue }
        let label = language == 0 ? chineseLabels[field] : englishLabels[field]
        let rightColumn = layout == "split_columns" && ["email", "website", "address"].contains(key)
        let x: CGFloat = rightColumn ? w * 0.48 : 48
        let limit = layout == "split_columns" && !rightColumn ? w * 0.48 - 64 : w - x - 48
        for item in items {
            let separator = language == 0 ? "：" : ": "
            let text = label + separator + item
            let rowTop = rightColumn ? secondaryTop : contactTop
            try draw(text, x: x, top: rowTop, size: CGFloat(detailSize), width: limit, ink: ink)
            if rightColumn { secondaryTop -= lineHeight } else { contactTop -= lineHeight }
        }
    }
    guard min(contactTop, secondaryTop) >= 16, let image = context.makeImage() else {
        throw GenerationError.renderFailed
    }
    return image
}

func distort(_ image: CGImage, using variant: Variant) throws -> CGImage {
    let width = Int((Double(image.width) * variant.render_scale).rounded())
    let height = Int((Double(image.height) * variant.render_scale).rounded())
    let source = try makeContext(width: width, height: height)
    let output = try makeContext(width: width, height: height)
    source.setFillColor(color(0xA6A194).cgColor)
    source.fill(CGRect(x: 0, y: 0, width: width, height: height))
    source.translateBy(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
    source.rotate(by: CGFloat(variant.angle_degrees * .pi / 180))
    let cardWidth = CGFloat(width) * challengeCardScale
    let cardHeight = CGFloat(height) * challengeCardScale
    source.interpolationQuality = .high
    source.draw(image, in: CGRect(x: -cardWidth / 2, y: -cardHeight / 2,
                                  width: cardWidth, height: cardHeight))
    guard let src = source.data, let dst = output.data else { throw GenerationError.renderFailed }
    var inputBuffer = vImage_Buffer(data: src, height: vImagePixelCount(height),
                                    width: vImagePixelCount(width), rowBytes: source.bytesPerRow)
    var outputBuffer = vImage_Buffer(data: dst, height: vImagePixelCount(height),
                                     width: vImagePixelCount(width), rowBytes: output.bytesPerRow)
    let kernel = UInt32(variant.blur_radius_px * 2 + 1)
    let status = vImageBoxConvolve_ARGB8888(&inputBuffer, &outputBuffer, nil, 0, 0, kernel, kernel,
                                           nil, vImage_Flags(kvImageEdgeExtend))
    guard status == kvImageNoError else { throw GenerationError.renderFailed }
    let lookup = (0...255).map { value in
        UInt8(min(255, max(0, Int(((Double(value) - 127.5) * variant.contrast + 127.5).rounded()))))
    }
    let pixels = dst.assumingMemoryBound(to: UInt8.self)
    for y in 0..<height {
        for x in 0..<width {
            let index = y * output.bytesPerRow + x * 4
            for channel in 0..<3 {
                pixels[index + channel] = lookup[Int(pixels[index + channel])]
            }
        }
    }
    guard let result = output.makeImage() else { throw GenerationError.renderFailed }
    return result
}

func savePNG(_ image: CGImage, to url: URL) throws -> String {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw GenerationError.encodeFailed(url)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw GenerationError.encodeFailed(url) }
    return SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
}

func saveJSON<T: Encodable>(_ object: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(object)
    data.append(10)
    try data.write(to: url, options: .atomic)
}

func generate(output: URL) throws {
    let manager = FileManager.default
    guard !manager.fileExists(atPath: output.path) else { throw GenerationError.outputExists(output) }
    let images = output.appendingPathComponent("images")
    let clear = output.appendingPathComponent("clear")
    try manager.createDirectory(at: images, withIntermediateDirectories: true)
    try manager.createDirectory(at: clear, withIntermediateDirectories: false)
    var random = Random(state: seed)
    var samples: [Sample] = []
    var manifest: [ManifestEntry] = []
    let categories = ["中文", "英文", "中英双语", "竖版或特殊布局", "低清晰度或复杂背景"]

    for index in 1...36 {
        let category = index <= 24 ? (index - 1) / 8 : index <= 30 ? 3 : 4
        let language = category < 3 ? category : (index - 1) % 3
        let isChallenge = category == 4
        let layout = category == 3 ? (index <= 28 ? "portrait" : "split_columns")
            : (index % 3 == 0 ? "company_first" : "name_first")
        let size = layout == "portrait" ? (880, 1100) : layout == "split_columns" ? (1420, 610)
            : (index % 2 == 0 ? 1150 : 1260, index % 2 == 0 ? 650 : 690)
        let palette = random.pick(palettes.count)
        let nameSize = 35 + random.pick(15)
        let detailSize = layout == "split_columns" ? 19 + random.pick(3) : 20 + random.pick(8)
        let order = index % 3 == 0 ? ["address", "website", "email", "office", "fax", "mobile", "other_phone"] : labelKeys
        let variant = isChallenge
            ? Variant(angle_degrees: Double((index % 2 == 0 ? 1 : -1) * (2 + random.pick(5))),
                      blur_radius_px: [1, 1, 2][random.pick(3)],
                      contrast: [0.62, 0.74, 0.85][random.pick(3)],
                      render_scale: [0.53, 0.65, 0.76][random.pick(3)],
                      patterned_background: index % 2 == 0)
            : Variant(angle_degrees: 0, blur_radius_px: 0, contrast: 1, render_scale: 1, patterned_background: false)
        let fields = values(for: index, language: language)
        let id = String(format: "F%02d", index)
        let name = id + ".png"
        let path = "evaluation/formal/images/" + name
        let clean = try drawCard(width: size.0, height: size.1, fields: fields, paletteIndex: palette,
                                 language: language, layout: layout, nameSize: nameSize, detailSize: detailSize,
                                 fieldOrder: order, pattern: false)
        var clearPath: String?
        var clearHash: String?
        if isChallenge {
            clearPath = "evaluation/formal/clear/" + name
            clearHash = try savePNG(clean, to: clear.appendingPathComponent(name))
        }
        let input = variant.patterned_background
            ? try drawCard(width: size.0, height: size.1, fields: fields, paletteIndex: palette,
                           language: language, layout: layout, nameSize: nameSize, detailSize: detailSize,
                           fieldOrder: order, pattern: true)
            : clean
        let image = isChallenge ? try distort(input, using: variant) : input
        let hash = try savePNG(image, to: images.appendingPathComponent(name))
        samples.append(Sample(sample_id: id, image: path, card_type: categories[category], fields: fields))
        manifest.append(ManifestEntry(sample_id: id, image: path, sha256: hash, clear_image: clearPath,
                                      clear_sha256: clearHash, width_px: image.width, height_px: image.height,
                                      name_font_pt: nameSize, detail_font_pt: detailSize, palette_index: palette,
                                      layout: layout, difficulty: isChallenge ? "challenge" : "clean",
                                      field_order: order, variant: variant))
    }

    try saveJSON(["samples": samples], to: output.appendingPathComponent("ground_truth.json"))
    try saveJSON(Manifest(seed: seed, fonts: fontNames,
                          macos_version: ProcessInfo.processInfo.operatingSystemVersionString,
                          challenge_card_scale: challengeCardScale, samples: manifest), to: output.appendingPathComponent("dataset_manifest.json"))
    print("Generated \(samples.count) formal images and \(manifest.compactMap(\.clear_image).count) clear originals in \(output.path)")
}

do {
    guard CommandLine.arguments.count == 2 else { throw GenerationError.usage }
    try generate(output: URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true))
} catch {
    FileHandle.standardError.write(Data("Generation failed: \(error)\n".utf8))
    exit(1)
}
