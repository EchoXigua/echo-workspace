import Foundation

enum ProfileGoalCalculator {
    private static let kcalPerKg = 7_700.0
    private static let defaultDeficitRate = 0.15
    private static let defaultSurplusRate = 0.10
    private static let minDailyDeficitKcal = 300.0
    private static let maxDailyDeficitKcal = 750.0
    private static let minDailySurplusKcal = 150.0
    private static let maxDailySurplusKcal = 500.0

    static func profile(from request: SaveUserProfileRequest, today: Date = Date()) -> UserProfile {
        let bmi = request.currentWeightKg / pow(request.heightCm / 100, 2)
        let bmr = bmrKcal(
            gender: request.gender,
            age: request.age,
            heightCm: request.heightCm,
            currentWeightKg: request.currentWeightKg
        )
        let targetCalories = dailyCalorieTargetKcal(
            gender: request.gender,
            bmrKcal: bmr,
            currentWeightKg: request.currentWeightKg,
            targetWeightKg: request.targetWeightKg,
            activityLevel: request.activityLevel,
            targetDate: request.targetDate,
            today: today
        )

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

    private static func dailyCalorieTargetKcal(
        gender: Gender,
        bmrKcal: Int,
        currentWeightKg: Double,
        targetWeightKg: Double,
        activityLevel: ActivityLevel,
        targetDate: Date?,
        today: Date
    ) -> Int {
        let tdee = Double(bmrKcal) * activityLevel.multiplier
        let adjustment: Double
        switch goalType(currentWeightKg: currentWeightKg, targetWeightKg: targetWeightKg) {
        case .loseWeight:
            adjustment = -dailyDeficit(
                tdee: tdee,
                currentWeightKg: currentWeightKg,
                targetWeightKg: targetWeightKg,
                targetDate: targetDate,
                today: today
            )
        case .gainWeight:
            adjustment = dailySurplus(
                tdee: tdee,
                currentWeightKg: currentWeightKg,
                targetWeightKg: targetWeightKg,
                targetDate: targetDate,
                today: today
            )
        case .maintain:
            adjustment = 0
        }

        let roundedTarget = Int(((tdee + adjustment) / 10).rounded() * 10)
        return max(roundedTarget, minimumCalories(for: gender))
    }

    private static func dailyDeficit(
        tdee: Double,
        currentWeightKg: Double,
        targetWeightKg: Double,
        targetDate: Date?,
        today: Date
    ) -> Double {
        let weightLossKg = currentWeightKg - targetWeightKg
        guard weightLossKg > 0 else {
            return 0
        }

        var deficit = tdee * defaultDeficitRate
        if let targetDate, let days = daysBetween(today, targetDate), days > 0 {
            deficit = weightLossKg * kcalPerKg / Double(days)
        }
        return min(max(deficit, minDailyDeficitKcal), maxDailyDeficitKcal)
    }

    private static func dailySurplus(
        tdee: Double,
        currentWeightKg: Double,
        targetWeightKg: Double,
        targetDate: Date?,
        today: Date
    ) -> Double {
        let weightGainKg = targetWeightKg - currentWeightKg
        guard weightGainKg > 0 else {
            return 0
        }

        var surplus = tdee * defaultSurplusRate
        if let targetDate, let days = daysBetween(today, targetDate), days > 0 {
            surplus = weightGainKg * kcalPerKg / Double(days)
        }
        return min(max(surplus, minDailySurplusKcal), maxDailySurplusKcal)
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

    private static func goalType(currentWeightKg: Double, targetWeightKg: Double) -> GoalType {
        if targetWeightKg < currentWeightKg {
            return .loseWeight
        }
        if targetWeightKg > currentWeightKg {
            return .gainWeight
        }
        return .maintain
    }

    private static func daysBetween(_ today: Date, _ targetDate: Date) -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }
}

private enum GoalType {
    case loseWeight
    case gainWeight
    case maintain
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
