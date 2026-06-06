import XCTest
@testable import LeanMate

final class FileLocalStoreTests: XCTestCase {
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
}

private extension FileLocalStoreTests {
    func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LeanMateTests-\(UUID().uuidString)", isDirectory: true)
    }
}
