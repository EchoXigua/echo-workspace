import Foundation

enum ProfileGoalCalculator {
    static func profile(from request: SaveUserProfileRequest) -> UserProfile {
        let bmi = request.currentWeightKg / pow(request.heightCm / 100, 2)
        let bmr = bmrKcal(
            gender: request.gender,
            age: request.age,
            heightCm: request.heightCm,
            currentWeightKg: request.currentWeightKg
        )
        let maintenance = Double(bmr) * request.activityLevel.multiplier
        let targetCalories = max(Int((maintenance - 400).rounded()), minimumCalories(for: request.gender))

        return UserProfile(
            gender: request.gender,
            age: request.age,
            heightCm: request.heightCm,
            currentWeightKg: request.currentWeightKg,
            targetWeightKg: request.targetWeightKg,
            activityLevel: request.activityLevel,
            timezone: request.timezone,
            targetDate: request.targetDate,
            bmi: rounded(bmi),
            bmrKcal: bmr,
            dailyCalorieTargetKcal: targetCalories
        )
    }

    private static func bmrKcal(
        gender: Gender,
        age: Int,
        heightCm: Double,
        currentWeightKg: Double
    ) -> Int {
        let base = 10 * currentWeightKg + 6.25 * heightCm - 5 * Double(age)
        let value: Double
        switch gender {
        case .male:
            value = base + 5
        case .female:
            value = base - 161
        case .unknown:
            value = base - 78
        }
        return Int(value.rounded())
    }

    private static func minimumCalories(for gender: Gender) -> Int {
        switch gender {
        case .male:
            1500
        case .female, .unknown:
            1200
        }
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}

private extension ActivityLevel {
    var multiplier: Double {
        switch self {
        case .sedentary:
            1.2
        case .light:
            1.375
        case .moderate:
            1.55
        case .active:
            1.725
        case .veryActive:
            1.9
        }
    }
}
