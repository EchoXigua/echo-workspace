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

struct GuestSession: Codable, Sendable {
    var startedAt: Date
    var updatedAt: Date
}

protocol LocalStore: Sendable {
    func guestSession() async throws -> GuestSession?
    func saveGuestSession(_ session: GuestSession) async throws
    func clearGuestSession() async throws
    func localProfile() async throws -> UserProfile?
    func saveLocalProfile(_ profile: UserProfile) async throws
    func clearLocalProfile() async throws
    func allLocalDietEntries() async throws -> [FoodEntry]
    func localDietEntries(date: Date) async throws -> [FoodEntry]
    func saveLocalDietEntry(_ entry: FoodEntry) async throws
    func deleteLocalDietEntry(id: UUID) async throws
    func localWeightEntries() async throws -> [WeightEntry]
    func saveLocalWeightEntry(_ entry: WeightEntry) async throws
    func deleteLocalWeightEntry(id: UUID) async throws
    func dietDrafts() async throws -> [DietDraft]
    func saveDietDraft(_ draft: DietDraft) async throws
    func deleteDietDraft(id: UUID) async throws
    func pendingWeights() async throws -> [PendingWeightDraft]
    func savePendingWeight(_ draft: PendingWeightDraft) async throws
    func deletePendingWeight(id: UUID) async throws
    func clearAllLocalData() async throws
}

actor InMemoryLocalStore: LocalStore {
    private var session: GuestSession?
    private var profile: UserProfile?
    private var localDietEntriesById: [UUID: FoodEntry] = [:]
    private var localWeightEntriesById: [UUID: WeightEntry] = [:]
    private var dietDraftsById: [UUID: DietDraft] = [:]
    private var pendingWeightsById: [UUID: PendingWeightDraft] = [:]

    func guestSession() async throws -> GuestSession? {
        session
    }

    func saveGuestSession(_ session: GuestSession) async throws {
        self.session = session
    }

    func clearGuestSession() async throws {
        session = nil
    }

    func localProfile() async throws -> UserProfile? {
        profile
    }

    func saveLocalProfile(_ profile: UserProfile) async throws {
        self.profile = profile
    }

    func clearLocalProfile() async throws {
        profile = nil
    }

    func allLocalDietEntries() async throws -> [FoodEntry] {
        Array(localDietEntriesById.values)
            .sorted { ($0.createdAt ?? $0.mealDate) > ($1.createdAt ?? $1.mealDate) }
    }

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

    func localWeightEntries() async throws -> [WeightEntry] {
        Array(localWeightEntriesById.values)
            .sorted { $0.recordDate > $1.recordDate }
    }

    func saveLocalWeightEntry(_ entry: WeightEntry) async throws {
        localWeightEntriesById[entry.id] = entry
    }

    func deleteLocalWeightEntry(id: UUID) async throws {
        localWeightEntriesById.removeValue(forKey: id)
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

    func clearAllLocalData() async throws {
        session = nil
        profile = nil
        localDietEntriesById.removeAll()
        localWeightEntriesById.removeAll()
        dietDraftsById.removeAll()
        pendingWeightsById.removeAll()
    }
}
