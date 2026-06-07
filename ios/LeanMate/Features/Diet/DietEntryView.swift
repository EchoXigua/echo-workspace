import SwiftUI

struct DietEntryView: View {
    @StateObject private var viewModel: DietEntryViewModel
    @StateObject private var weightViewModel: WeightViewModel
    @Binding private var selectedTab: AppTab
    @State private var showsWeightSheet = false

    let isVisitor: Bool
    let onLoginRequired: () -> Void

    init(
        viewModel: DietEntryViewModel,
        weightViewModel: WeightViewModel,
        selectedTab: Binding<AppTab>,
        isVisitor: Bool = false,
        onLoginRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _weightViewModel = StateObject(wrappedValue: weightViewModel)
        _selectedTab = selectedTab
        self.isVisitor = isVisitor
        self.onLoginRequired = onLoginRequired
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    header

                    if isVisitor {
                        visitorContent
                    } else {
                        entryContent
                    }
                }
                .padding(.horizontal, LMSpacing.large)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            LMBottomTabs(
                items: AppTab.allCases.map {
                    LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                },
                selection: $selectedTab
            )
        }
        .background(LMColors.background.ignoresSafeArea())
        .sheet(isPresented: $showsWeightSheet) {
            WeightEntrySheet(viewModel: weightViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
    }
}

private extension DietEntryView {
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("记录饮食")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("先确认，再保存为正式记录")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            Spacer()

            Button(action: openWeightSheet) {
                HStack(spacing: 5) {
                    Image(systemName: "scalemass")
                    Text("体重")
                }
                .font(LMTypography.badge)
                .foregroundStyle(LMColors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LMColors.primarySoft)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(LMColors.primaryBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 52)
    }

    var visitorContent: some View {
        LMStateView(
            kind: .empty,
            title: "登录后再保存记录",
            message: "游客可以查看入口，但饮食和体重记录需要登录后保存。",
            actionTitle: "去登录",
            action: onLoginRequired
        )
    }

    @ViewBuilder
    var entryContent: some View {
        mealControls
        textSearch
        methodCards
        stateMessage

        switch viewModel.mode {
        case .text:
            textInputSection
        case .manual:
            manualSection
        case .photoPlaceholder:
            photoPlaceholderSection
        case .confirmation:
            confirmationSection
        }
    }

    var mealControls: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Picker("餐次", selection: $viewModel.mealType) {
                ForEach(MealType.allCases) { mealType in
                    Text(mealType.title).tag(mealType)
                }
            }
            .pickerStyle(.segmented)

            DatePicker("业务日期", selection: $viewModel.mealDate, displayedComponents: .date)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textBody)
        }
    }

    var textSearch: some View {
        LMSearchField(
            text: $viewModel.textInput,
            placeholder: "输入一句话，如：早餐两个鸡蛋一杯豆浆"
        )
    }

    var methodCards: some View {
        VStack(spacing: 8) {
            methodButton(
                title: "拍照识别",
                subtitle: "本批先作为入口占位",
                systemImage: "camera",
                isSelected: viewModel.mode == .photoPlaceholder,
                action: viewModel.selectPhotoPlaceholder
            )
            methodButton(
                title: "文本识别",
                subtitle: "输入一句话后生成确认清单",
                systemImage: "text.bubble",
                isSelected: viewModel.mode == .text || viewModel.mode == .confirmation,
                action: viewModel.selectTextMode
            )
            methodButton(
                title: "手动记录",
                subtitle: "直接填写食物名称和营养估算",
                systemImage: "pencil",
                isSelected: viewModel.mode == .manual,
                action: viewModel.selectManualMode
            )
        }
    }

    func methodButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? LMColors.primarySoft : LMColors.warmMuted)
                        .frame(width: 42, height: 42)

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)
                    Text(subtitle)
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? LMColors.primary : LMColors.textMuted)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? LMColors.primaryBorder : LMColors.inputBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isBusy)
    }

    @ViewBuilder
    var stateMessage: some View {
        switch viewModel.state {
        case .recognitionRunning:
            LMStateView(
                kind: .loading,
                title: "识别还在进行",
                message: "可以稍后刷新，也可以改为手动记录。",
                actionTitle: "刷新结果",
                action: refreshRecognition
            )
            LMButton(
                title: "改为手动记录",
                systemImage: "pencil",
                role: .secondary,
                height: 48,
                action: viewModel.switchFailedRecognitionToManual
            )
        case .recognitionFailed(let message):
            LMStateView(
                kind: .error,
                title: "识别失败",
                message: message,
                actionTitle: "转手动记录",
                action: viewModel.switchFailedRecognitionToManual
            )
        case .localValidationFailed:
            if let validationMessage = viewModel.validationMessage {
                LMStateView(kind: .error, title: "请检查输入", message: validationMessage)
            }
        case .saveFailed(let message):
            LMStateView(kind: .error, title: "保存失败", message: message)
        case .saveSucceeded:
            LMStateView(
                kind: .empty,
                title: "记录已保存",
                message: "首页统计由后端刷新后返回，本页不自行计算。"
            )
        case .error(let message):
            LMStateView(kind: .error, title: "操作失败", message: message)
        case .idle, .recognizing, .confirmation, .saving:
            EmptyView()
        }
    }

    var textInputSection: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text("文字记录")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            TextEditor(text: $viewModel.textInput)
                .font(LMTypography.body)
                .foregroundStyle(LMColors.textBody)
                .frame(minHeight: 96)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(LMColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LMColors.inputBorder, lineWidth: 1)
                }

            LMButton(
                title: "开始文本识别",
                systemImage: "sparkles",
                isLoading: viewModel.isRecognizing,
                action: startRecognition
            )
        }
    }

    var manualSection: some View {
        VStack(spacing: LMSpacing.regular) {
            EditableFoodItemCard(title: "手动记录", item: $viewModel.manualItem)

            LMButton(
                title: "保存手动记录",
                systemImage: "checkmark",
                isLoading: viewModel.isSaving,
                action: saveManual
            )
        }
    }

    var photoPlaceholderSection: some View {
        LMStateView(
            kind: .empty,
            title: "拍照识别后续接入",
            message: "本批只保留拍照入口，不进入拍照确认流程。"
        )
    }

    var confirmationSection: some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                Text("识别结果")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                Text("AI 识别为估算值，请确认后再保存。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            ForEach($viewModel.confirmationItems) { item in
                EditableFoodItemCard(title: "食物", item: item)
            }

            HStack {
                Text("总计")
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)
                Spacer()
                Text(viewModel.totalCaloriesText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(LMColors.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(LMColors.primaryBorder, lineWidth: 1)
            }

            LMButton(
                title: "保存记录",
                systemImage: "checkmark",
                isLoading: viewModel.isSaving,
                action: saveRecognition
            )
        }
    }

    func startRecognition() {
        Task {
            await viewModel.startTextRecognition()
        }
    }

    func refreshRecognition() {
        Task {
            await viewModel.refreshRecognition()
        }
    }

    func saveManual() {
        Task {
            _ = await viewModel.saveManualEntry()
        }
    }

    func saveRecognition() {
        Task {
            _ = await viewModel.saveRecognitionEntry()
        }
    }

    func openWeightSheet() {
        if isVisitor {
            onLoginRequired()
        } else {
            showsWeightSheet = true
        }
    }
}

private struct EditableFoodItemCard: View {
    let title: String
    @Binding var item: DietEntryViewModel.EditableFoodItem

    var body: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text(title)
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            formField(title: "食物名称", text: $item.name, placeholder: "如：鸡蛋")
            formField(title: "数量", text: $item.quantityText, placeholder: "如：2 个")

            HStack(spacing: LMSpacing.small) {
                formField(title: "重量 g", text: $item.weightGText, placeholder: "100", keyboard: .decimalPad)
                formField(title: "热量 kcal", text: $item.caloriesText, placeholder: "140", keyboard: .numberPad)
            }

            HStack(spacing: LMSpacing.small) {
                formField(title: "蛋白质 g", text: $item.proteinText, placeholder: "12", keyboard: .decimalPad)
                formField(title: "脂肪 g", text: $item.fatText, placeholder: "10", keyboard: .decimalPad)
                formField(title: "碳水 g", text: $item.carbsText, placeholder: "1", keyboard: .decimalPad)
            }
        }
    }

    func formField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(LMTypography.badge)
                .foregroundStyle(LMColors.textSecondary)

            TextField(placeholder, text: text)
                .font(LMTypography.body)
                .foregroundStyle(LMColors.textBody)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 10)
                .frame(height: 42)
                .background(LMColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LMColors.inputBorder, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MealType {
    var title: String {
        switch self {
        case .breakfast:
            "早餐"
        case .lunch:
            "午餐"
        case .dinner:
            "晚餐"
        case .snack:
            "加餐"
        }
    }
}

private struct DietEntryPreviewContainer: View {
    @State private var selectedTab = AppTab.record

    var body: some View {
        DietEntryView(
            viewModel: DietEntryViewModel(apiClient: MockAPIClient(delayNanoseconds: 0)),
            weightViewModel: WeightViewModel(apiClient: MockAPIClient(delayNanoseconds: 0), weightText: "55.8"),
            selectedTab: $selectedTab,
            onLoginRequired: {}
        )
    }
}

struct DietEntryView_Previews: PreviewProvider {
    static var previews: some View {
        DietEntryPreviewContainer()
    }
}
