import XCTest
@testable import LeanMate

final class FileLocalStoreTests: XCTestCase {
    func testGuestSessionAndProfilePersistAcrossStoreInstances() async throws {
        let directory = temporaryDirectory()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let session = GuestSession(startedAt: Date(), updatedAt: Date())
        let firstStore = FileLocalStore(directory: directory)
        try await firstStore.saveGuestSession(session)
        try await firstStore.saveLocalProfile(MockData.profile)

        let secondStore = FileLocalStore(directory: directory)
        let loadedSession = try await secondStore.guestSession()
        let loadedProfile = try await secondStore.localProfile()

        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedProfile?.currentWeightKg, 55.8)
        XCTAssertEqual(loadedProfile?.dailyCalorieTargetKcal, 1600)
    }

    func testDietDraftPersistsAcrossStoreInstances() async throws {
        let directory = temporaryDirectory()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let request = SaveFoodEntryRequest(
            recognitionTaskId: nil,
            mealDate: try XCTUnwrap(APICoding.dateFormatter.date(from: "2026-06-06")),
            mealType: .breakfast,
            sourceType: .manual,
            rawText: nil,
            imageUrl: nil,
            items: [
                SaveFoodItemRequest(
                    id: nil,
                    name: "鸡蛋",
                    quantityText: "2 个",
                    weightG: 100,
                    caloriesKcal: 140,
                    proteinG: 12,
                    fatG: 10,
                    carbsG: 1,
                    confidence: nil,
                    userEdited: true
                )
            ]
        )
        let draft = DietDraft(id: UUID(), updatedAt: Date(), request: request)

        let firstStore = FileLocalStore(directory: directory)
        try await firstStore.saveDietDraft(draft)

        let secondStore = FileLocalStore(directory: directory)
        let drafts = try await secondStore.dietDrafts()

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts[0].id, draft.id)
        XCTAssertEqual(drafts[0].request.items.first?.name, "鸡蛋")
    }

    func testPendingWeightCanBeDeleted() async throws {
        let directory = temporaryDirectory()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let draft = PendingWeightDraft(
            id: UUID(),
            updatedAt: Date(),
            request: SaveWeightEntryRequest(
                recordDate: try XCTUnwrap(APICoding.dateFormatter.date(from: "2026-06-06")),
                weightKg: 55.8,
                note: "morning"
            )
        )

        let store = FileLocalStore(directory: directory)
        try await store.savePendingWeight(draft)
        try await store.deletePendingWeight(id: draft.id)

        let drafts = try await store.pendingWeights()
        XCTAssertTrue(drafts.isEmpty)
    }

    func testLocalWeightPersistsAcrossStoreInstances() async throws {
        let directory = temporaryDirectory()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let entry = WeightEntry(
            recordDate: try XCTUnwrap(APICoding.dateFormatter.date(from: "2026-06-06")),
            weightKg: 56.2,
            note: "local",
            id: UUID(),
            createdAt: Date()
        )
        let firstStore = FileLocalStore(directory: directory)
        try await firstStore.saveLocalWeightEntry(entry)

        let secondStore = FileLocalStore(directory: directory)
        let entries = try await secondStore.localWeightEntries()

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].weightKg, 56.2)
    }

    func testClearAllLocalDataRemovesPersistedFiles() async throws {
        let directory = temporaryDirectory()
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        let draft = DietDraft(
            id: UUID(),
            updatedAt: Date(),
            request: SaveFoodEntryRequest(
                recognitionTaskId: nil,
                mealDate: MockData.today,
                mealType: .breakfast,
                sourceType: .manual,
                rawText: nil,
                imageUrl: nil,
                items: []
            )
        )
        let weight = WeightEntry(
            recordDate: MockData.today,
            weightKg: 56.2,
            note: "local",
            id: UUID(),
            createdAt: Date()
        )
        let pendingWeight = PendingWeightDraft(
            id: UUID(),
            updatedAt: Date(),
            request: SaveWeightEntryRequest(recordDate: MockData.today, weightKg: 56.2, note: nil)
        )

        let store = FileLocalStore(directory: directory)
        try await store.saveGuestSession(GuestSession(startedAt: Date(), updatedAt: Date()))
        try await store.saveLocalProfile(MockData.profile)
        try await store.saveLocalDietEntry(MockData.foodEntry)
        try await store.saveLocalWeightEntry(weight)
        try await store.saveDietDraft(draft)
        try await store.savePendingWeight(pendingWeight)

        try await store.clearAllLocalData()

        let secondStore = FileLocalStore(directory: directory)
        let session = try await secondStore.guestSession()
        let profile = try await secondStore.localProfile()
        let localDietEntries = try await secondStore.allLocalDietEntries()
        let localWeightEntries = try await secondStore.localWeightEntries()
        let dietDrafts = try await secondStore.dietDrafts()
        let pendingWeights = try await secondStore.pendingWeights()

        XCTAssertNil(session)
        XCTAssertNil(profile)
        XCTAssertTrue(localDietEntries.isEmpty)
        XCTAssertTrue(localWeightEntries.isEmpty)
        XCTAssertTrue(dietDrafts.isEmpty)
        XCTAssertTrue(pendingWeights.isEmpty)
    }
}

private extension FileLocalStoreTests {
    func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LeanMateTests-\(UUID().uuidString)", isDirectory: true)
    }
}
