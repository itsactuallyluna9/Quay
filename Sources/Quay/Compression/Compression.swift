import Foundation

public enum CompressionAlgorithm: Int, CaseIterable, Sendable, Equatable {
    case none = 0
    case brotli
    case gzip
    case zstd
    
    static func fromProtobuf(_ protobuf: PBCompressionAlgorithm) throws -> CompressionAlgorithm {
        guard let algo = CompressionAlgorithm.init(rawValue: protobuf.rawValue) else {
            throw Quay.createError(.invalidHeader, description: "Invalid compression algorithm", failureReason: "Unknown compression algorithm with value \(protobuf.rawValue)")
        }
        return algo
    }
}

public struct CompressionSettings : Sendable, Equatable {
    public var algorithm: CompressionAlgorithm
    public var quality: Int32 = 0
    
    public static let transportDefault: CompressionSettings = .init(algorithm: .brotli, quality: 1)
    public static let longTermDefault: CompressionSettings = .init(algorithm: .brotli, quality: 9)
    public static let none: CompressionSettings = .init(algorithm: .none, quality: 0)
    
    public init(algorithm: CompressionAlgorithm, quality: Int32) {
        self.algorithm = algorithm
        self.quality = quality
    }
    
    init(protobuf: PBCompressionSettings) throws {
        self.algorithm = try .fromProtobuf(protobuf.algorithm)
        self.quality = protobuf.quality
    }

    func protobuf() -> PBCompressionSettings {
        var settings = PBCompressionSettings()
        settings.algorithm = PBCompressionAlgorithm(rawValue: algorithm.rawValue)!
        settings.quality = quality
        return settings
    }
}
