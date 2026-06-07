import Foundation

enum MockData {
    static let today = makeDate("2026-06-06")
    static let userId = makeUUID("11111111-1111-1111-1111-111111111111")
    static let entryId = makeUUID("22222222-2222-2222-2222-222222222222")
    static let taskId = makeUUID("33333333-3333-3333-3333-333333333333")
    static let reportId = makeUUID("44444444-4444-4444-4444-444444444444")

    static let currentUser = CurrentUser(
        id: userId,
        nickname: "LeanMate",
        avatarUrl: nil,
        status: .active,
        profileCompleted: true,
        createdAt: today
    )

    static let profileIncompleteUser = CurrentUser(
        id: userId,
        nickname: "LeanMate",
        avatarUrl: nil,
        status: .active,
        profileCompleted: false,
        createdAt: today
    )

    static let profile = UserProfile(
        gender: .unknown,
        age: 30,
        heightCm: 168,
        currentWeightKg: 55.8,
        targetWeightKg: 52,
        activityLevel: .light,
        timezone: "Asia/Shanghai",
        targetDate: nil,
        bmi: 19.8,
        bmrKcal: 1320,
        dailyCalorieTargetKcal: 1800
    )

    static let foodItems = [
        FoodItem(
            id: makeUUID("55555555-5555-5555-5555-555555555555"),
            name: "鸡蛋",
            quantityText: "2 个",
            weightG: 100,
            caloriesKcal: 140,
            proteinG: 12,
            fatG: 10,
            carbsG: 1,
            confidence: 0.92,
            userEdited: false
        ),
        FoodItem(
            id: makeUUID("66666666-6666-6666-6666-666666666666"),
            name: "豆浆",
            quantityText: "1 杯",
            weightG: 250,
            caloriesKcal: 95,
            proteinG: 7,
            fatG: 4,
            carbsG: 9,
            confidence: 0.88,
            userEdited: false
        )
    ]

    static let foodEntry = FoodEntry(
        id: entryId,
        recognitionTaskId: taskId,
        mealDate: today,
        mealType: .breakfast,
        sourceType: .text,
        rawText: "早餐两个鸡蛋一杯豆浆",
        imageUrl: nil,
        status: .confirmed,
        totalCaloriesKcal: 235,
        totalProteinG: 19,
        totalFatG: 14,
        totalCarbsG: 10,
        items: foodItems,
        createdAt: today
    )

    static let todayHome = TodayHome(
        date: today,
        profileCompleted: true,
        calorieTargetKcal: 1800,
        caloriesInKcal: 937,
        remainingCaloriesKcal: 863,
        proteinG: 42,
        fatG: 28,
        carbsG: 116,
        currentWeightKg: 55.8,
        streakDays: 12,
        reportSummary: "蛋白质摄入稳定，晚餐可以继续保持清淡。",
        foodEntries: [
            FoodEntrySummary(
                id: entryId,
                mealType: .breakfast,
                totalCaloriesKcal: 235,
                itemNames: ["鸡蛋", "豆浆"]
            )
        ]
    )

    static let nutritionSnapshot = DailyNutritionSnapshot(
        date: today,
        calorieTargetKcal: 1800,
        caloriesKcal: 937,
        remainingCaloriesKcal: 863,
        proteinG: 42,
        fatG: 28,
        carbsG: 116,
        foodEntryCount: 1,
        weightKg: 55.8
    )

    static let dailyReport = DailyReport(
        id: reportId,
        reportDate: today,
        score: 84,
        summary: "今天整体摄入控制稳定。",
        problem: "晚餐热量仍有偏高风险。",
        suggestion: "明天早餐可以增加优质蛋白，晚餐减少油脂。",
        status: .generated,
        generatedAt: today,
        viewedAt: nil
    )

    static let streak = Streak(
        currentDays: 12,
        longestDays: 18,
        lastActiveDate: today,
        milestones: [
            StreakMilestone(days: 3, achieved: true, achievedAt: today),
            StreakMilestone(days: 7, achieved: true, achievedAt: today),
            StreakMilestone(days: 30, achieved: false, achievedAt: nil),
            StreakMilestone(days: 100, achieved: false, achievedAt: nil)
        ]
    )

    static let emptyStreak = Streak(
        currentDays: 0,
        longestDays: 0,
        lastActiveDate: nil,
        milestones: [
            StreakMilestone(days: 3, achieved: false, achievedAt: nil),
            StreakMilestone(days: 7, achieved: false, achievedAt: nil),
            StreakMilestone(days: 30, achieved: false, achievedAt: nil),
            StreakMilestone(days: 100, achieved: false, achievedAt: nil)
        ]
    )
}

private extension MockData {
    static func makeDate(_ value: String) -> Date {
        APICoding.dateFormatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    static func makeUUID(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }
}
