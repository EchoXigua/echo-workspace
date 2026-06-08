import SwiftUI
import PhotosUI

struct DietEntryView: View {
    @StateObject private var viewModel: DietEntryViewModel
    @StateObject private var weightViewModel: WeightViewModel
    @Binding private var selectedTab: AppTab
    @State private var showsWeightSheet = false
    @State private var showsDeleteConfirmation = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

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
        ZStack {
            if viewModel.mode == .confirmation && viewModel.isPhotoConfirmation {
                photoConfirmationScreen
            } else {
                LMTabScreen(
                    items: AppTab.allCases.map {
                        LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
                    },
                    selection: $selectedTab
                ) {
                    header
                    entryContent
                }
            }

            if showsDeleteConfirmation {
                deleteConfirmationOverlay
            }
        }
        .sheet(isPresented: $showsWeightSheet) {
            WeightEntrySheet(viewModel: weightViewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LMColors.background)
                .presentationCornerRadius(26)
        }
        .onChange(of: photoPickerItem) { _, newItem in
            loadSelectedPhoto(newItem)
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

    var photoConfirmationScreen: some View {
        VStack(spacing: 0) {
            photoPreviewHero

            VStack(alignment: .leading, spacing: 16) {
                LMSheetHandle()
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("确认识别结果")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                stateMessage

                ForEach($viewModel.confirmationItems) { item in
                    CompactFoodItemCard(item: item)
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
                    title: "保存识别结果",
                    systemImage: "checkmark",
                    isLoading: viewModel.isSaving,
                    action: saveRecognition
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(LMColors.background)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
        }
        .background(LMColors.cameraSurface.ignoresSafeArea())
    }

    var photoPreviewHero: some View {
        ZStack {
            LMColors.cameraSurface

            if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .overlay {
                        Color.black.opacity(0.28)
                    }
            }

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LMColors.primary, lineWidth: 2)
                .frame(width: 222, height: 222)

            Text(viewModel.selectedImageName ?? "晚餐照片")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            VStack {
                HStack {
                    Button(action: viewModel.selectPhotoMode) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .font(LMTypography.badge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Color.black.opacity(0.24))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(viewModel.mealType.title)
                        .font(LMTypography.badge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Color.black.opacity(0.24))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.top, 38)

                Spacer()
            }
        }
        .frame(height: 398)
    }

    var deleteConfirmationOverlay: some View {
        ZStack {
            Color(hex: 0x133322, alpha: 0.34)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LMColors.dangerSoft)
                        .frame(width: 42, height: 42)

                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.danger)
                }

                Text("删除这条饮食记录？")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text("删除后今日热量和营养比例会重新计算。")
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    LMButton(
                        title: "取消",
                        role: .secondary,
                        height: 46
                    ) {
                        showsDeleteConfirmation = false
                    }

                    LMButton(
                        title: "删除",
                        role: .destructive,
                        height: 46,
                        isLoading: viewModel.isDeleting
                    ) {
                        showsDeleteConfirmation = false
                        deleteSavedEntry()
                    }
                }
            }
            .padding(.top, 22)
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
            .frame(maxWidth: 342, alignment: .leading)
            .background(LMColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    var entryContent: some View {
        textSearch
        methodCards
        stateMessage

        switch viewModel.mode {
        case .text:
            textInputSection
        case .manual:
            manualSection
        case .photo:
            photoSection
        case .confirmation:
            confirmationSection
        }
    }

    var mealControls: some View {
        VStack(alignment: .leading, spacing: LMSpacing.medium) {
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
                subtitle: "选择照片后生成确认清单",
                systemImage: "camera",
                isSelected: viewModel.mode == .photo || viewModel.isPhotoConfirmation,
                action: viewModel.selectPhotoMode
            )
            methodButton(
                title: "文本识别",
                subtitle: "输入一句话后生成确认清单",
                systemImage: "text.bubble",
                isSelected: viewModel.mode == .text || (viewModel.mode == .confirmation && !viewModel.isPhotoConfirmation),
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
                message: "首页统计由后端刷新后返回，本页不自行计算。",
                actionTitle: "回到首页",
                action: { selectedTab = .home }
            )
            if viewModel.canDeleteSavedEntry {
                LMButton(
                    title: "删除本条记录",
                    systemImage: "trash",
                    role: .destructive,
                    height: 48,
                    isLoading: viewModel.isDeleting,
                    action: { showsDeleteConfirmation = true }
                )
            }
        case .deleteSucceeded:
            LMStateView(
                kind: .empty,
                title: "记录已删除",
                message: "服务端会刷新对应业务日期的热量和营养统计。"
            )
        case .deleteFailed(let message):
            LMStateView(kind: .error, title: "删除失败", message: message)
        case .error(let message):
            LMStateView(kind: .error, title: "操作失败", message: message)
        case .recognizing:
            LMStateView(
                kind: .loading,
                title: "正在识别",
                message: "识别结果只是估算值，请在确认页检查后保存。"
            )
        case .deleting:
            LMStateView(kind: .loading, title: "正在删除", message: "正在删除这条饮食记录。")
        case .idle, .confirmation, .saving:
            EmptyView()
        }
    }

    var textInputSection: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text("文字记录")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            mealControls

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
            LMCard(cornerRadius: 16, padding: 14) {
                mealControls
            }
            EditableFoodItemCard(title: "手动记录", item: $viewModel.manualItem)

            LMButton(
                title: "保存手动记录",
                systemImage: "checkmark",
                isLoading: viewModel.isSaving,
                action: saveManual
            )
        }
    }

    var photoSection: some View {
        LMCard(cornerRadius: 16, padding: 14) {
            Text("拍照识别")
                .font(LMTypography.cardTitle)
                .foregroundStyle(LMColors.textBody)

            mealControls

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LMColors.warmMuted)
                    .frame(height: 220)

                if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(LMColors.primaryBorder, lineWidth: 1)
                        }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                        Text("选择一张餐食照片")
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textBody)
                        Text("权限只在选择照片时触发，确认前不会保存记录。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                    }
                }
            }
            .clipped()

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                    Text(selectedPhotoData == nil ? "选择照片" : "重新选择照片")
                }
                .font(LMTypography.bodyStrong)
                .foregroundStyle(LMColors.textBody)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LMColors.warmMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LMColors.inputBorder, lineWidth: 1)
                }
            }
            .disabled(viewModel.isBusy)

            LMButton(
                title: "开始拍照识别",
                systemImage: "sparkles",
                isLoading: viewModel.isRecognizing,
                action: startPhotoRecognition
            )
        }
    }

    var confirmationSection: some View {
        VStack(spacing: LMSpacing.regular) {
            LMCard(cornerRadius: 16, padding: 14) {
                Text(viewModel.confirmationTitle)
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

    func startPhotoRecognition() {
        Task {
            await viewModel.startPhotoRecognition(imageData: selectedPhotoData ?? Data())
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

    func deleteSavedEntry() {
        Task {
            _ = await viewModel.deleteSavedEntry()
        }
    }

    func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            selectedPhotoData = nil
            return
        }

        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            await MainActor.run {
                selectedPhotoData = data
            }
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

private struct CompactFoodItemCard: View {
    @Binding var item: DietEntryViewModel.EditableFoodItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LMColors.primarySoft)
                        .frame(width: 42, height: 42)

                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                }

                TextField("食物名称", text: $item.name)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)
                    .textInputAutocapitalization(.never)

                TextField("热量", text: $item.caloriesText)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.primaryDeep)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 58)
            }

            HStack(spacing: 8) {
                compactField("重量", text: $item.weightGText)
                compactField("蛋白", text: $item.proteinText)
                compactField("脂肪", text: $item.fatText)
                compactField("碳水", text: $item.carbsText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }

    func compactField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)

            TextField("--", text: text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .keyboardType(.decimalPad)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(LMColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
