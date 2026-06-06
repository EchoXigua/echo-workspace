import Foundation
import Combine

enum ProfileSetupState: Equatable {
    case idle
    case loadingProfile
    case editing
    case localValidationFailed
    case saving
    case saveSucceeded
    case saveFailed(String)
    case authExpired
}

enum ProfileField: Hashable {
    case age
    case height
    case currentWeight
    case targetWeight
    case timezone
}

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    private let apiClient: any APIClient
    private let tokenStore: (any TokenStore)?

    @Published private(set) var state: ProfileSetupState = .idle
    @Published private(set) var fieldErrors: [ProfileField: String] = [:]
    @Published private(set) var savedProfile: UserProfile?

    @Published var gender: Gender = .unknown
    @Published var ageText = ""
    @Published var heightText = ""
    @Published var currentWeightText = ""
    @Published var targetWeightText = ""
    @Published var activityLevel: ActivityLevel = .light
    @Published var timezoneIdentifier: String

    var isLoadingProfile: Bool {
        if case .loadingProfile = state {
            return true
        }
        return false
    }

    var isSaving: Bool {
        if case .saving = state {
            return true
        }
        return false
    }

    init(
        apiClient: any APIClient,
        tokenStore: (any TokenStore)? = nil,
        timezoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.timezoneIdentifier = timezoneIdentifier
    }

    func loadProfile() async {
        guard state == .idle else {
            return
        }

        state = .loadingProfile

        do {
            let payload = try await apiClient.profile()
            if let profile = payload.profile {
                apply(profile)
            }
            state = .editing
        } catch {
            await handle(error)
        }
    }

    @discardableResult
    func save() async -> Bool {
        guard !isSaving else {
            return false
        }

        guard let request = makeSaveRequest() else {
            state = .localValidationFailed
            return false
        }

        state = .saving

        do {
            let payload = try await apiClient.saveProfile(request)
            guard let profile = payload.profile else {
                state = .saveFailed("目标生成失败，请稍后重试")
                return false
            }
            savedProfile = profile
            state = .saveSucceeded
            return true
        } catch {
            await handle(error)
            return false
        }
    }
}

private extension ProfileSetupViewModel {
    func apply(_ profile: UserProfile) {
        gender = profile.gender
        ageText = String(profile.age)
        heightText = displayNumber(profile.heightCm)
        currentWeightText = displayNumber(profile.currentWeightKg)
        targetWeightText = displayNumber(profile.targetWeightKg)
        activityLevel = profile.activityLevel
        timezoneIdentifier = profile.timezone
        savedProfile = profile
    }

    func makeSaveRequest() -> SaveUserProfileRequest? {
        fieldErrors.removeAll()

        let trimmedTimezone = timezoneIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTimezone.isEmpty {
            fieldErrors[.timezone] = "需要读取设备时区"
        }

        let age = validatedInt(
            text: ageText,
            field: .age,
            range: 1...120,
            message: "年龄需在 1-120 岁之间"
        )
        let height = validatedDouble(
            text: heightText,
            field: .height,
            range: 50...250,
            message: "身高需在 50-250 cm 之间"
        )
        let currentWeight = validatedDouble(
            text: currentWeightText,
            field: .currentWeight,
            range: 20...300,
            message: "当前体重需在 20-300 kg 之间"
        )
        let targetWeight = validatedDouble(
            text: targetWeightText,
            field: .targetWeight,
            range: 20...300,
            message: "目标体重需在 20-300 kg 之间"
        )

        guard let age, let height, let currentWeight, let targetWeight, fieldErrors.isEmpty else {
            return nil
        }

        return SaveUserProfileRequest(
            gender: gender,
            age: age,
            heightCm: height,
            currentWeightKg: currentWeight,
            targetWeightKg: targetWeight,
            activityLevel: activityLevel,
            timezone: trimmedTimezone,
            targetDate: nil
        )
    }

    func validatedInt(text: String, field: ProfileField, range: ClosedRange<Int>, message: String) -> Int? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Int(value), range.contains(number) else {
            fieldErrors[field] = message
            return nil
        }
        return number
    }

    func validatedDouble(text: String, field: ProfileField, range: ClosedRange<Double>, message: String) -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(value), range.contains(number) else {
            fieldErrors[field] = message
            return nil
        }
        return number
    }

    func handle(_ error: Error) async {
        let appError = AppError(error)
        if case .unauthorized = appError {
            try? await tokenStore?.clearTokens()
            state = .authExpired
        } else {
            state = .saveFailed(appError.errorDescription ?? "保存失败，请稍后重试")
        }
    }

    func displayNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
