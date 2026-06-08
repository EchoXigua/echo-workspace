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
}

private extension FileLocalStore {
    enum FileName {
        static let localDietEntries = "local-diet-entries.json"
        static let dietDrafts = "diet-drafts.json"
        static let pendingWeights = "pending-weights.json"
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

    func save<Value: Encodable>(_ value: Value, fileName: String) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        let data = try encoder.encode(value)
        try data.write(to: url, options: [.atomic])
    }
}
