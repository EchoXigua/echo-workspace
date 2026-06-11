import XCTest
@testable import LeanMate

final class APICodingTests: XCTestCase {
    func testDecoderParsesBusinessDateAndDateTime() throws {
        let json = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "nickname": "LeanMate",
          "avatarUrl": null,
          "status": "active",
          "profileCompleted": true,
          "createdAt": "2026-06-06T12:34:56Z"
        }
        """

        let user = try APICoding.makeDecoder().decode(CurrentUser.self, from: Data(json.utf8))

        XCTAssertEqual(user.id.uuidString.lowercased(), "11111111-1111-1111-1111-111111111111")
        XCTAssertEqual(user.status, .active)
        XCTAssertTrue(user.profileCompleted)
        XCTAssertEqual(user.createdAt.timeIntervalSince1970, 1_780_749_296, accuracy: 1)
    }

    func testEncoderUsesBusinessDateForRequests() throws {
        let request = SaveWeightEntryRequest(
            recordDate: try XCTUnwrap(APICoding.dateFormatter.date(from: "2026-06-06")),
            weightKg: 55.8,
            note: nil
        )

        let data = try APICoding.makeEncoder().encode(request)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(object["recordDate"] as? String, "2026-06-06")
        XCTAssertEqual(object["weightKg"] as? Double, 55.8)
    }

    func testBusinessDateStringUsesBusinessTimezone() throws {
        let formatter = ISO8601DateFormatter()
        let earlyMorningInShanghai = try XCTUnwrap(formatter.date(from: "2026-06-05T16:30:00Z"))
        let shanghai = try XCTUnwrap(TimeZone(secondsFromGMT: 8 * 60 * 60))

        XCTAssertEqual(
            APICoding.dateString(from: earlyMorningInShanghai, timeZone: shanghai),
            "2026-06-06"
        )
    }

    func testEnumsDecodeOpenAPIValues() throws {
        let json = """
        {
          "gender": "unknown",
          "age": 30,
          "heightCm": 168,
          "currentWeightKg": 55.8,
          "targetWeightKg": 52,
          "activityLevel": "very_active",
          "timezone": "Asia/Shanghai",
          "targetDate": null,
          "bmi": 19.8,
          "bmrKcal": 1320,
          "dailyCalorieTargetKcal": 1800
        }
        """

        let profile = try APICoding.makeDecoder().decode(UserProfile.self, from: Data(json.utf8))

        XCTAssertEqual(profile.gender, .unknown)
        XCTAssertEqual(profile.activityLevel, .veryActive)
        XCTAssertEqual(profile.dailyCalorieTargetKcal, 1800)
    }
}
