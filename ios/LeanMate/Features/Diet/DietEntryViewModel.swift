import Foundation

@MainActor
final class DietEntryViewModel: ObservableObject {
    enum Mode: Equatable {
        case selection
        case text
        case manual
        case photo
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
        case deleting
        case deleteSucceeded
        case deleteFailed(String)
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

    @Published var mode: Mode = .selection
    @Published var state: State = .idle
    @Published var mealDate: Date
    @Published var mealType: MealType
    @Published var textInput = ""
    @Published var manualItem = EditableFoodItem()
    @Published var confirmationItems: [EditableFoodItem] = []
    @Published var validationMessage: String?
    @Published private(set) var selectedImageName: String?
    @Published private(set) var savedEntry: FoodEntry?

    private let apiClient: APIClient
    private let localStore: (any LocalStore)?
    private let savesLocally: Bool
    private var currentRecognitionTaskId: UUID?
    private var currentDraftSource: FoodSourceType = .text

    init(
        apiClient: APIClient,
        localStore: (any LocalStore)? = nil,
        savesLocally: Bool = false,
        mealDate: Date = Date()
    ) {
        self.apiClient = apiClient
        self.localStore = localStore
        self.savesLocally = savesLocally
        self.mealDate = mealDate
        mealType = MealType.defaultMealType(for: mealDate)
    }

    var isBusy: Bool {
        isRecognizing || isSaving || isDeleting
    }

    var isRecognizing: Bool {
        state == .recognizing
    }

    var isSaving: Bool {
        state == .saving
    }

    var isDeleting: Bool {
        state == .deleting
    }

    var isPhotoConfirmation: Bool {
        currentDraftSource == .photo && mode == .confirmation
    }

    var canDeleteSavedEntry: Bool {
        savedEntry != nil && !isBusy
    }

    var canRefreshRecognition: Bool {
        currentRecognitionTaskId != nil && state == .recognitionRunning
    }

    var confirmationTitle: String {
        switch currentDraftSource {
        case .photo:
            "确认记录"
        case .text:
            "确认记录"
        case .manual:
            "手动记录"
        }
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

    func selectSelectionMode() {
        mode = .selection
        state = .idle
        validationMessage = nil
    }

    func discardDraftAndSelectSelectionMode() {
        resetDraft()
        selectSelectionMode()
    }

    func selectManualMode() {
        mode = .manual
        state = .idle
        validationMessage = nil
    }

    func selectPhotoMode() {
        mode = .photo
        state = .idle
        validationMessage = nil
    }

    func closeConfirmation() {
        switch currentDraftSource {
        case .photo:
            mode = .photo
        case .text:
            mode = .text
        case .manual:
            mode = .manual
        }
        state = .idle
        validationMessage = nil
    }

    func clearLocalValidation() {
        if state == .localValidationFailed {
            state = .idle
        }
        validationMessage = nil
    }

    func showLocalValidation(_ message: String) {
        validationMessage = message
        state = .localValidationFailed
    }

    func appendTextExpression(_ expression: String) {
        let trimmedExpression = expression.trimmed
        guard !trimmedExpression.isEmpty else {
            return
        }

        let existing = textInput.trimmed
        textInput = existing.isEmpty ? trimmedExpression : "\(existing)，\(trimmedExpression)"
        clearLocalValidation()
    }

    func applyCommonUnit(foodName: String, quantityText: String, weightGText: String) {
        if manualItem.name.trimmed.isEmpty {
            manualItem.name = foodName
        }
        if manualItem.quantityText.trimmed.isEmpty {
            manualItem.quantityText = quantityText
        }
        if manualItem.weightGText.trimmed.isEmpty {
            manualItem.weightGText = weightGText
        }
        clearLocalValidation()
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
        currentDraftSource = .text
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

    func startPhotoRecognition(imageData: Data, fileName: String = "meal-photo.jpg", mimeType: String = "image/jpeg") async {
        guard !isRecognizing else {
            return
        }
        guard !imageData.isEmpty else {
            validationMessage = "先选择一张餐食照片"
            state = .localValidationFailed
            return
        }

        validationMessage = nil
        selectedImageName = fileName
        currentDraftSource = .photo
        state = .recognizing

        do {
            let task = try await apiClient.createPhotoRecognition(
                imageData: imageData,
                fileName: fileName,
                mimeType: mimeType,
                mealType: mealType,
                mealDate: mealDate,
                note: textInput.trimmed.nilIfEmpty
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

    func deleteSavedEntry() async -> Bool {
        guard !isDeleting else {
            return false
        }
        guard let savedEntry else {
            validationMessage = "没有可删除的饮食记录"
            state = .localValidationFailed
            return false
        }

        validationMessage = nil
        state = .deleting

        do {
            try await apiClient.deleteDietEntry(id: savedEntry.id)
            self.savedEntry = nil
            state = .deleteSucceeded
            return true
        } catch {
            state = .deleteFailed(AppError(error).localizedDescription)
            return false
        }
    }
}

private extension DietEntryViewModel {
    func resetDraft() {
        textInput = ""
        manualItem = EditableFoodItem()
        confirmationItems = []
        validationMessage = nil
        selectedImageName = nil
        savedEntry = nil
        currentRecognitionTaskId = nil
        currentDraftSource = .text
    }

    func applyRecognitionTask(_ task: RecognitionTask) {
        currentRecognitionTaskId = task.id
        let taskSource = task.draftEntry?.sourceType ?? task.sourceType
        if !(currentDraftSource == .photo && taskSource == .text) {
            currentDraftSource = taskSource
        }

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
            confirmationItems = draft.items.map(EditableFoodItem.init(foodItem:))
            mode = .confirmation
            state = .confirmation
        }
    }

    func save(_ request: SaveFoodEntryRequest) async -> Bool {
        validationMessage = nil
        state = .saving

        do {
            if savesLocally, let localStore {
                let entry = makeLocalFoodEntry(from: request)
                try await localStore.saveLocalDietEntry(entry)
                savedEntry = entry
            } else {
                let result = try await apiClient.saveDietEntry(request)
                savedEntry = result.entry
            }
            state = .saveSucceeded
            return true
        } catch {
            state = .saveFailed(AppError(error).localizedDescription)
            return false
        }
    }

    func makeLocalFoodEntry(from request: SaveFoodEntryRequest) -> FoodEntry {
        let items = request.items.map { item in
            FoodItem(
                id: item.id ?? UUID(),
                name: item.name,
                quantityText: item.quantityText,
                weightG: item.weightG,
                caloriesKcal: item.caloriesKcal,
                proteinG: item.proteinG,
                fatG: item.fatG,
                carbsG: item.carbsG,
                confidence: item.confidence,
                userEdited: item.userEdited ?? true
            )
        }

        return FoodEntry(
            id: UUID(),
            recognitionTaskId: request.recognitionTaskId,
            mealDate: request.mealDate,
            mealType: request.mealType,
            sourceType: request.sourceType,
            rawText: request.rawText,
            imageUrl: request.imageUrl,
            status: .confirmed,
            totalCaloriesKcal: items.compactMap(\.caloriesKcal).reduce(0, +),
            totalProteinG: items.compactMap(\.proteinG).reduce(0, +),
            totalFatG: items.compactMap(\.fatG).reduce(0, +),
            totalCarbsG: items.compactMap(\.carbsG).reduce(0, +),
            items: items,
            createdAt: Date()
        )
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

private extension MealType {
    static func defaultMealType(for date: Date, calendar: Calendar = .current) -> MealType {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .breakfast
        case 11..<16:
            return .lunch
        case 16..<21:
            return .dinner
        default:
            return .snack
        }
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
