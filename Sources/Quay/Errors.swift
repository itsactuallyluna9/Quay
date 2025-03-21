import Foundation

extension Quay {
    public enum ErrorCode: Int {
        case invalidMagicNumber
        case invalidHeader
        case decompressionFailed
        case compressionFailed
        case decodeFailed
        case unimplemented = 69
        case unknown
    }
    
    static func createError(_ code: ErrorCode, description: String?, failureReason: String?) -> Error {
        let errorInfo: [String: Any] = [
            NSLocalizedDescriptionKey: description ?? "Unknown error",
            NSLocalizedFailureReasonErrorKey: failureReason ?? "Unknown failure reason",
        ]
        return NSError(domain: "QuayError", code: code.rawValue, userInfo: errorInfo)
    }
}
