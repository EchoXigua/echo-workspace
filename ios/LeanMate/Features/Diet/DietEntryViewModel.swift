import Foundation

@MainActor
final class DietEntryViewModel: ObservableObject {
    enum Mode: Equatable {
        case text
        case manual
        case photoPlaceholder
        case confirmation
    }

    enum State: Equatable {
        case idle
        case recognizing
        case recognitionRunning
        case recognitionFailed(String)
        case confirmation
        case localValidationFailed
        case saving
        case saveSucceeded
        case saveFailed(String)
        case error(String)
    }

    struct EditableFoodItem: Identifiable, Equatable {
        let id: UUID
        var name: String
        var quantityText: String
        var weightGText: String
        var caloriesText: String
        var proteinText: String
        var fatText: String
        var carbsText: String
        var confidence: Double?
        var userEdited: Bool

        init(foodItem: FoodItem) {
            id = foodItem.id
            name = foodItem.name
            quantityText = foodItem.quantityText ?? ""
            weightGText = displayFoodNumber(foodItem.weightG)
            caloriesText = foodItem.caloriesKcal.map(String.init) ?? ""
            proteinText = displayFoodNumber(foodItem.proteinG)
            fatText = displayFoodNumber(foodItem.fatG)
            carbsText = displayFoodNumber(foodItem.carbsG)
            confidence = foodItem.confidence
            userEdited = foodItem.userEdited
        }

        init(id: UUID = UUID()) {
            self.id = id
            name = ""
            quantityText = ""
            weightGText = ""
            caloriesText = ""
            proteinText = ""
            fatText = ""
            carbsText = ""
            confidence = nil
            userEdited = true
        }
    }

    @Published var mode: Mode = .text
    @Published var state: State = .idle
    @Published var mealDate: Date
    @Published var mealType: MealType = .breakfast
    @Published var textInput = ""
    @Published var manualItem = EditableFoodItem()
    @Published var confirmationItems: [EditableFoodItem] = []
    @Published var validationMessage: String?
    @Published private(set) var savedEntry: FoodEntry?

    private let apiClient: APIClient
    private var currentRecognitionTaskId: UUID?
    private var currentDraftSource: FoodSourceType = .text

    init(apiClient: APIClient, mealDate: Date = Date()) {
        self.apiClient = apiClient
        self.mealDate = mealDate
    }

    var isBusy: Bool {
        isRecognizing || isSaving
    }

    var isRecognizing: Bool {
        state == .recognizing
    }

    var isSaving: Bool {
        state == .saving
    }

    var canRefreshRecognition: Bool {
        currentRecognitionTaskId != nil && state == .recognitionRunning
    }

    var totalCaloriesText: String {
        let total = confirmationItems.compactMap { Int($0.caloriesText.trimmed) }.reduce(0, +)
        return total > 0 ? "\(total) 千卡" : "待确认"
    }

    func selectTextMode() {
        mode = .text
        state = .idle
        validationMessage = nil
    }

    func selectManualMode() {
        mode = .manual
        state = .idle
        validationMessage = nil
    }

    func selectPhotoPlaceholder() {
        mode = .photoPlaceholder
        state = .idle
        validationMessage = nil
    }

    func startTextRecognition() async {
        guard !isRecognizing else {
            return
        }
        let text = textInput.trimmed
        guard !text.isEmpty else {
            validationMessage = "先输入一句饮食描述"
            state = .localValidationFailed
            return
        }

        validationMessage = nil
        state = .recognizing

        do {
            let task = try await apiClient.createTextRecognition(
                TextRecognitionRequest(text: text, mealType: mealType, mealDate: mealDate)
            )
            currentRecognitionTaskId = task.id
            let latestTask = try await apiClient.recognitionTask(id: task.id)
            applyRecognitionTask(latestTask)
        } catch {
            state = .error(AppError(error).localizedDescription)
        }
    }

    func refreshRecognition() async {
        guard !isRecognizing, let taskId = currentRecognitionTaskId else {
            return
        }

        state = .recognizing
        do {
            let latestTask = try await apiClient.recognitionTask(id: taskId)
            applyRecognitionTask(latestTask)
        } catch {
            state = .error(AppError(error).localizedDescription)
        }
    }

    func switchFailedRecognitionToManual() {
        mode = .manual
        if manualItem.name.trimmed.isEmpty {
            manualItem.name = String(textInput.trimmed.prefix(128))
        }
        validationMessage = nil
        state = .idle
    }

    func updateConfirmationItem(_ item: EditableFoodItem) {
        guard let index = confirmationItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        var edited = item
        edited.userEdited = true
        confirmationItems[index] = edited
    }

    func saveManualEntry() async -> Bool {
        guard !isSaving else {
            return false
        }
        validationMessage = nil
        guard let item = validate(item: manualItem) else {
            state = .localValidationFailed
            return false
        }

        let request = SaveFoodEntryRequest(
            recognitionTaskId: nil,
            mealDate: mealDate,
            mealType: mealType,
            sourceType: .manual,
            rawText: textInput.trimmed.nilIfEmpty,
            imageUrl: nil,
            items: [item]
        )

        return await save(request)
    }

    func saveRecognitionEntry() async -> Bool {
        guard !isSaving else {
            return false
        }
        validationMessage = nil
        let items = confirmationItems.compactMap(validate(item:))
        guard !items.isEmpty, items.count == confirmationItems.count else {
            state = .localValidationFailed
            return false
        }

        let request = SaveFoodEntryRequest(
            recognitionTaskId: currentRecognitionTaskId,
            mealDate: mealDate,
            mealType: mealType,
            sourceType: currentDraftSource,
            rawText: textInput.trimmed.nilIfEmpty,
            imageUrl: nil,
            items: items
        )

        return await save(request)
    }
}

private extension DietEntryViewModel {
    func applyRecognitionTask(_ task: RecognitionTask) {
        currentRecognitionTaskId = task.id

        switch task.status {
        case .pending, .running:
            state = .recognitionRunning
        case .failed:
            state = .recognitionFailed(task.errorMessage ?? "识别失败，可以改为手动记录")
        case .succeeded:
            guard let draft = task.draftEntry, !draft.items.isEmpty else {
                state = .recognitionFailed("识别结果为空，可以改为手动记录")
                return
            }
            mealDate = draft.mealDate
            mealType = draft.mealType
            currentDraftSource = draft.sourceType
            confirmationItems = draft.items.map(EditableFoodItem.init(foodItem:))
            mode = .confirmation
            state = .confirmation
        }
    }

    func save(_ request: SaveFoodEntryRequest) async -> Bool {
        validationMessage = nil
        state = .saving

        do {
            let result = try await apiClient.saveDietEntry(request)
            savedEntry = result.entry
            state = .saveSucceeded
            return true
        } catch {
            state = .saveFailed(AppError(error).localizedDescription)
            return false
        }
    }

    func validate(item: EditableFoodItem) -> SaveFoodItemRequest? {
        let name = item.name.trimmed
        guard !name.isEmpty else {
            validationMessage = "食物名称不能为空"
            return nil
        }
        guard name.count <= 128 else {
            validationMessage = "食物名称不能超过 128 字"
            return nil
        }
        guard item.quantityText.trimmed.count <= 128 else {
            validationMessage = "数量描述不能超过 128 字"
            return nil
        }
        let weightG = optionalDouble(item.weightGText, fieldName: "重量")
        guard validationMessage == nil else {
            return nil
        }
        let caloriesKcal = optionalInt(item.caloriesText, fieldName: "热量")
        guard validationMessage == nil else {
            return nil
        }
        let proteinG = optionalDouble(item.proteinText, fieldName: "蛋白质")
        guard validationMessage == nil else {
            return nil
        }
        let fatG = optionalDouble(item.fatText, fieldName: "脂肪")
        guard validationMessage == nil else {
            return nil
        }
        let carbsG = optionalDouble(item.carbsText, fieldName: "碳水")
        guard validationMessage == nil else {
            return nil
        }

        return SaveFoodItemRequest(
            id: item.id,
            name: name,
            quantityText: item.quantityText.trimmed.nilIfEmpty,
            weightG: weightG,
            caloriesKcal: caloriesKcal,
            proteinG: proteinG,
            fatG: fatG,
            carbsG: carbsG,
            confidence: item.confidence,
            userEdited: item.userEdited
        )
    }

    func optionalDouble(_ value: String, fieldName: String) -> Double? {
        let trimmed = value.trimmed
        guard !trimmed.isEmpty else {
            return .none
        }
        guard let number = Double(trimmed), number >= 0 else {
            validationMessage = "\(fieldName)需要填写有效数字"
            return nil
        }
        return number
    }

    func optionalInt(_ value: String, fieldName: String) -> Int? {
        let trimmed = value.trimmed
        guard !trimmed.isEmpty else {
            return .none
        }
        guard let number = Int(trimmed), number >= 0 else {
            validationMessage = "\(fieldName)需要填写有效整数"
            return nil
        }
        return number
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

private func displayFoodNumber(_ value: Double?) -> String {
    guard let value else {
        return ""
    }
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}
