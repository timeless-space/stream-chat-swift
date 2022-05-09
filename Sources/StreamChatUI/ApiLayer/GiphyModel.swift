import Foundation

// MARK: - Welcome
struct GiphyResponse: Codable {
    let data: [GiphyModelItem]
    let pagination: GiphyPagination
}

// MARK: - Data
struct GiphyModelItem: Codable {
    let type, id: String
    let images: Images

    enum CodingKeys: String, CodingKey {
        case type, id
        case images
    }
}

// MARK: - Images
struct Images: Codable {
    let fixedWidthDownsampled: FixedHeight

    enum CodingKeys: String, CodingKey {
        case fixedWidthDownsampled = "fixed_width_downsampled"
    }
}

// MARK: - FixedHeight
struct FixedHeight: Codable {
    let url: String
}

// MARK: - GiphyPagination
struct GiphyPagination: Codable {
    let totalCount, count, offset: Int

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case count, offset
    }
}
