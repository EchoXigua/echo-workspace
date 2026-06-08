import Foundation

struct DietDraft: Identifiable, Codable, Sendable {
    let id: UUID
    var updatedAt: Date
    var request: SaveFoodEntryRequest
}

struct PendingWeightDraft: Identifiable, Codable, Sendable {
    let id: UUID
    var updatedAt: Date
    var request: SaveWeightEntryRequest
}

protocol LocalStore: Sendable {
    func localDietEntries(date: Date) async throws -> [FoodEntry]
    func saveLocalDietEntry(_ entry: FoodEntry) async throws
    func deleteLocalDietEntry(id: UUID) async throws
    func dietDrafts() async throws -> [DietDraft]
    func saveDietDraft(_ draft: DietDraft) async throws
    func deleteDietDraft(id: UUID) async throws
    func pendingWeights() async throws -> [PendingWeightDraft]
    func savePendingWeight(_ draft: PendingWeightDraft) async throws
    func deletePendingWeight(id: UUID) async throws
}

actor InMemoryLocalStore: LocalStore {
    private var localDietEntriesById: [UUID: FoodEntry] = [:]
    private var dietDraftsById: [UUID: DietDraft] = [:]
    private var pendingWeightsById: [UUID: PendingWeightDraft] = [:]

    func localDietEntries(date: Date) async throws -> [FoodEntry] {
        Array(localDietEntriesById.values)
            .filter { Calendar.current.isDate($0.mealDate, inSameDayAs: date) }
            .sorted { ($0.createdAt ?? $0.mealDate) > ($1.createdAt ?? $1.mealDate) }
    }

    func saveLocalDietEntry(_ entry: FoodEntry) async throws {
        localDietEntriesById[entry.id] = entry
    }

    func deleteLocalDietEntry(id: UUID) async throws {
        localDietEntriesById.removeValue(forKey: id)
    }

    func dietDrafts() async throws -> [DietDraft] {
        Array(dietDraftsById.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveDietDraft(_ draft: DietDraft) async throws {
        dietDraftsById[draft.id] = draft
    }

    func deleteDietDraft(id: UUID) async throws {
        dietDraftsById.removeValue(forKey: id)
    }

    func pendingWeights() async throws -> [PendingWeightDraft] {
        Array(pendingWeightsById.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    func savePendingWeight(_ draft: PendingWeightDraft) async throws {
        pendingWeightsById[draft.id] = draft
    }

    func deletePendingWeight(id: UUID) async throws {
        pendingWeightsById.removeValue(forKey: id)
    }
}
