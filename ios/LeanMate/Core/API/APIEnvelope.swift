import Foundation

struct APIEnvelope<Payload: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: Payload?
}

struct APIErrorResponse: Decodable {
    let code: Int
    let message: String
    let data: String?
}

struct EmptyResponseData: Decodable, Sendable {}

struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
