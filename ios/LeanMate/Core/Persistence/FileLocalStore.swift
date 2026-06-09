import Foundation

actor FileLocalStore: LocalStore {
    private let directory: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = directory ?? Self.defaultDirectory(fileManager: fileManager)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func guestSession() async throws -> GuestSession? {
        try loadOptional(GuestSession.self, fileName: FileName.guestSession)
    }

    func saveGuestSession(_ session: GuestSession) async throws {
        try save(session, fileName: FileName.guestSession)
    }

    func clearGuestSession() async throws {
        try delete(fileName: FileName.guestSession)
    }

    func localProfile() async throws -> UserProfile? {
        try loadOptional(UserProfile.self, fileName: FileName.localProfile)
    }

    func saveLocalProfile(_ profile: UserProfile) async throws {
        try save(profile, fileName: FileName.localProfile)
    }

    func clearLocalProfile() async throws {
        try delete(fileName: FileName.localProfile)
    }

    func allLocalDietEntries() async throws -> [FoodEntry] {
        try load([FoodEntry].self, fileName: FileName.localDietEntries)
            .sorted { ($0.createdAt ?? $0.mealDate) > ($1.createdAt ?? $1.mealDate) }
    }

    func localDietEntries(date: Date) async throws -> [FoodEntry] {
        try load([FoodEntry].self, fileName: FileName.localDietEntries)
            .filter { Calendar.current.isDate($0.mealDate, inSameDayAs: date) }
            .sorted { ($0.createdAt ?? $0.mealDate) > ($1.createdAt ?? $1.mealDate) }
    }

    func saveLocalDietEntry(_ entry: FoodEntry) async throws {
        var entries = try load([FoodEntry].self, fileName: FileName.localDietEntries)
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        try save(entries, fileName: FileName.localDietEntries)
    }

    func deleteLocalDietEntry(id: UUID) async throws {
        var entries = try load([FoodEntry].self, fileName: FileName.localDietEntries)
        entries.removeAll { $0.id == id }
        try save(entries, fileName: FileName.localDietEntries)
    }

    func localWeightEntries() async throws -> [WeightEntry] {
        try load([WeightEntry].self, fileName: FileName.localWeightEntries)
            .sorted { $0.recordDate > $1.recordDate }
    }

    func saveLocalWeightEntry(_ entry: WeightEntry) async throws {
        var entries = try load([WeightEntry].self, fileName: FileName.localWeightEntries)
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        try save(entries, fileName: FileName.localWeightEntries)
    }

    func deleteLocalWeightEntry(id: UUID) async throws {
        var entries = try load([WeightEntry].self, fileName: FileName.localWeightEntries)
        entries.removeAll { $0.id == id }
        try save(entries, fileName: FileName.localWeightEntries)
    }

    func dietDrafts() async throws -> [DietDraft] {
        try load([DietDraft].self, fileName: FileName.dietDrafts)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveDietDraft(_ draft: DietDraft) async throws {
        var drafts = try load([DietDraft].self, fileName: FileName.dietDrafts)
        drafts.removeAll { $0.id == draft.id }
        drafts.append(draft)
        try save(drafts, fileName: FileName.dietDrafts)
    }

    func deleteDietDraft(id: UUID) async throws {
        var drafts = try load([DietDraft].self, fileName: FileName.dietDrafts)
        drafts.removeAll { $0.id == id }
        try save(drafts, fileName: FileName.dietDrafts)
    }

    func pendingWeights() async throws -> [PendingWeightDraft] {
        try load([PendingWeightDraft].self, fileName: FileName.pendingWeights)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func savePendingWeight(_ draft: PendingWeightDraft) async throws {
        var drafts = try load([PendingWeightDraft].self, fileName: FileName.pendingWeights)
        drafts.removeAll { $0.id == draft.id }
        drafts.append(draft)
        try save(drafts, fileName: FileName.pendingWeights)
    }

    func deletePendingWeight(id: UUID) async throws {
        var drafts = try load([PendingWeightDraft].self, fileName: FileName.pendingWeights)
        drafts.removeAll { $0.id == id }
        try save(drafts, fileName: FileName.pendingWeights)
    }

    func clearAllLocalData() async throws {
        for fileName in FileName.allLocalDataFiles {
            try delete(fileName: fileName)
        }
    }
}

private extension FileLocalStore {
    enum FileName {
        static let guestSession = "guest-session.json"
        static let localProfile = "local-profile.json"
        static let localDietEntries = "local-diet-entries.json"
        static let localWeightEntries = "local-weight-entries.json"
        static let dietDrafts = "diet-drafts.json"
        static let pendingWeights = "pending-weights.json"

        static let allLocalDataFiles = [
            guestSession,
            localProfile,
            localDietEntries,
            localWeightEntries,
            dietDrafts,
            pendingWeights
        ]
    }

    static func defaultDirectory(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL.appendingPathComponent("LeanMate/Drafts", isDirectory: true)
    }

    func load<Value: Decodable>(_ type: Value.Type, fileName: String) throws -> Value {
        let url = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else {
            return try decoder.decode(Value.self, from: Data("[]".utf8))
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(Value.self, from: data)
    }

    func loadOptional<Value: Decodable>(_ type: Value.Type, fileName: String) throws -> Value? {
        let url = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(Value.self, from: data)
    }

    func save<Value: Encodable>(_ value: Value, fileName: String) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }

    func delete(fileName: String) throws {
        let url = directory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }
}
