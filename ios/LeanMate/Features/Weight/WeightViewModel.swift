import Foundation

@MainActor
final class WeightViewModel: ObservableObject {
    enum State: Equatable {
        case editing
        case localValidationFailed(String)
        case saving
        case saved
        case saveFailed(String)
    }

    @Published var state: State = .editing
    @Published var recordDate: Date
    @Published var weightText: String
    @Published var noteText: String
    @Published private(set) var savedEntry: WeightEntry?

    private let apiClient: APIClient
    private let localStore: (any LocalStore)?
    private let savesLocally: Bool

    init(
        apiClient: APIClient,
        localStore: (any LocalStore)? = nil,
        savesLocally: Bool = false,
        recordDate: Date = Date(),
        weightText: String = "",
        noteText: String = ""
    ) {
        self.apiClient = apiClient
        self.localStore = localStore
        self.savesLocally = savesLocally
        self.recordDate = recordDate
        self.weightText = weightText
        self.noteText = noteText
    }

    var isSaving: Bool {
        state == .saving
    }

    func save() async -> Bool {
        guard !isSaving else {
            return false
        }
        guard let weight = validatedWeight() else {
            return false
        }

        state = .saving
        do {
            let request = SaveWeightEntryRequest(
                recordDate: recordDate,
                weightKg: weight,
                note: noteText.trimmed.nilIfEmpty
            )
            if savesLocally, let localStore {
                let entry = WeightEntry(
                    recordDate: request.recordDate,
                    weightKg: request.weightKg,
                    note: request.note,
                    id: UUID(),
                    createdAt: Date()
                )
                try await localStore.saveLocalWeightEntry(entry)
                savedEntry = entry
            } else {
                let result = try await apiClient.saveWeight(request)
                savedEntry = result.entry
            }
            state = .saved
            return true
        } catch {
            state = .saveFailed(AppError(error).localizedDescription)
            return false
        }
    }
}

private extension WeightViewModel {
    func validatedWeight() -> Double? {
        let text = weightText.trimmed
        guard let value = Double(text) else {
            state = .localValidationFailed("请输入有效体重")
            return nil
        }
        guard (20...300).contains(value) else {
            state = .localValidationFailed("体重需在 20-300 kg 之间")
            return nil
        }
        return value
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
