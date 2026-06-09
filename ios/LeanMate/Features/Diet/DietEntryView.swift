import SwiftUI
import PhotosUI

struct DietEntryView: View {
    @StateObject private var viewModel: DietEntryViewModel
    @StateObject private var weightViewModel: WeightViewModel
    @Binding private var selectedTab: AppTab
    @Binding private var pendingLaunchMode: DietEntryLaunchMode?
    @State private var showsWeightSheet = false
    @State private var showsDeleteConfirmation = false
    @State private var showsCameraPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    let isVisitor: Bool
    let onLoginRequired: () -> Void

    init(
        viewModel: DietEntryViewModel,
        weightViewModel: WeightViewModel,
        selectedTab: Binding<AppTab>,
        pendingLaunchMode: Binding<DietEntryLaunchMode?> = .constant(nil),
        isVisitor: Bool = false,
        onLoginRequired: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _weightViewModel = StateObject(wrappedValue: weightViewModel)
        _selectedTab = selectedTab
        _pendingLaunchMode = pendingLaunchMode
        self.isVisitor = isVisitor
        self.onLoginRequired = onLoginRequired
    }

    var body: some View {
        ZStack {
            if viewModel.mode == .confirmation && viewModel.isPhotoConfirmation {
                photoConfirmationScreen
            } else if viewModel.mode == .confirmation {
                confirmationRecordScreen
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
        .fullScreenCover(isPresented: $showsCameraPicker) {
            CameraImagePicker { imageData in
                selectedPhotoData = imageData
                viewModel.clearLocalValidation()
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoPickerItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onAppear(perform: applyPendingLaunchMode)
        .onChange(of: pendingLaunchMode) { _, _ in
            applyPendingLaunchMode()
        }
    }
}

private extension DietEntryView {
    var showsResultOnly: Bool {
        switch viewModel.state {
        case .saveSucceeded, .deleting, .deleteSucceeded, .deleteFailed:
            true
        default:
            false
        }
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("记录饮食")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
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

    var confirmationRecordScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LMSpacing.regular) {
                stateMessage
                if !showsResultOnly {
                    confirmationSection(showsHeader: false)
                }
            }
            .padding(.horizontal, LMSpacing.large)
            .padding(.top, LMSpacing.regular)
            .padding(.bottom, LMSpacing.large)
        }
        .scrollIndicators(.hidden)
        .background(LMColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            confirmationTopBar
        }
    }

    var confirmationTopBar: some View {
        let title = showsResultOnly ? "记录结果" : "确认记录"
        let subtitle = showsResultOnly ? "这次记录已经处理完成" : "识别结果可编辑，确认后保存"

        return HStack(spacing: 12) {
            Button(action: closeConfirmationTopBar) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
                    .frame(width: 34, height: 34)
                    .background(LMColors.card)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(LMColors.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy)
            .accessibilityLabel(showsResultOnly ? "关闭结果" : "关闭确认")

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Text(subtitle)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            Spacer()

            if !showsResultOnly {
                Button(action: viewModel.closeConfirmation) {
                    Text("重填")
                        .font(LMTypography.badge)
                        .foregroundStyle(LMColors.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(LMColors.primarySoft)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(LMColors.primaryBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isBusy)
            }
        }
        .padding(.horizontal, LMSpacing.large)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(LMColors.background)
    }

    var photoConfirmationScreen: some View {
        VStack(spacing: 0) {
            photoPreviewHero

            VStack(alignment: .leading, spacing: 16) {
                LMSheetHandle()
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("确认记录")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                stateMessage

                if !showsResultOnly {
                    mealControls

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
                        title: "保存并更新首页",
                        systemImage: "checkmark",
                        isLoading: viewModel.isSaving,
                        action: saveRecognition
                    )
                }
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
                    Button(action: closePhotoConfirmationTopBar) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(showsResultOnly ? "完成" : "返回")
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
        switch viewModel.mode {
        case .selection:
            methodIntro
            methodCards
            commonUnitsSection
        case .text:
            stateMessage
            if !showsResultOnly {
                methodIntro
                textModeSection
            }
        case .manual:
            stateMessage
            if !showsResultOnly {
                methodIntro
                manualModeSection
            }
        case .photo:
            stateMessage
            if !showsResultOnly {
                methodIntro
                photoModeSection
            }
        case .confirmation:
            stateMessage
            if !showsResultOnly {
                confirmationSection()
            }
        }
    }

    var methodIntro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("选择记录方式")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LMColors.textBody)

            Text("先把这一餐记下来。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var mealControls: some View {
        MealTypeSelector(selection: $viewModel.mealType, isDisabled: viewModel.isBusy)
    }

    var methodCards: some View {
        VStack(spacing: 8) {
            methodButton(
                title: "拍照识别",
                subtitle: "上传餐食照片，识别后再确认。",
                systemImage: "camera",
                isSelected: viewModel.mode == .photo || viewModel.isPhotoConfirmation,
                action: viewModel.selectPhotoMode
            )
            methodButton(
                title: "文本识别",
                subtitle: "用一句话描述这一餐。",
                systemImage: "text.bubble",
                isSelected: viewModel.mode == .text || (viewModel.mode == .confirmation && !viewModel.isPhotoConfirmation),
                action: viewModel.selectTextMode
            )
            methodButton(
                title: "手动记录",
                subtitle: "直接填写食物和营养估算。",
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
        let isManual = title == "手动记录"

        return Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isManual ? LMColors.warmMuted : LMColors.primarySoft)
                        .frame(width: 42, height: 42)

                    if isManual {
                        LMManualEntryIcon(size: 18)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                    }
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

    func methodSummary(for mode: DietEntryViewModel.Mode) -> DietMethodSummary {
        switch mode {
        case .photo:
            DietMethodSummary(
                title: "拍照识别",
                subtitle: "上传餐食照片，识别后再确认。",
                systemImage: "camera",
                isManual: false
            )
        case .text, .confirmation:
            DietMethodSummary(
                title: "文本识别",
                subtitle: "用一句话描述这一餐。",
                systemImage: "message",
                isManual: false
            )
        case .manual, .selection:
            DietMethodSummary(
                title: "手动记录",
                subtitle: "直接填写食物和营养估算。",
                systemImage: "pencil",
                isManual: true
            )
        }
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
                message: "已更新到首页。",
                actionTitle: "回到首页",
                action: goHomeAfterResult
            )
        case .deleteSucceeded:
            LMStateView(
                kind: .empty,
                title: "记录已删除",
                message: "服务端会刷新对应业务日期的热量和营养统计。"
            )
        case .deleteFailed(let message):
            LMStateView(kind: .error, title: "删除失败", message: message)
            if viewModel.canDeleteSavedEntry {
                LMButton(
                    title: "重新删除",
                    systemImage: "trash",
                    role: .destructive,
                    height: 48,
                    isLoading: viewModel.isDeleting,
                    action: { showsDeleteConfirmation = true }
                )
            }
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

    var commonUnitsSection: some View {
        commonUnitsSection(title: "常用单位", badge: "参考", interaction: .reference)
    }

    var photoModeSection: some View {
        VStack(spacing: LMSpacing.regular) {
            mealControls

            LMCard(cornerRadius: 18, padding: 14) {
                selectedMethodCard(for: .photo)
                photoUploadArea

                HStack(spacing: 10) {
                    Button(action: startCameraCapture) {
                        secondaryActionLabel(title: "拍照", systemImage: "camera")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isBusy)

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        secondaryActionLabel(title: "从相册选", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isBusy)
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LMColors.primary)

                    Text("识别后先进入确认页")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 38)
                .background(LMColors.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                LMButton(
                    title: "开始识别",
                    systemImage: "sparkles",
                    isLoading: viewModel.isRecognizing,
                    action: startPhotoRecognition
                )
            }
        }
    }

    var textModeSection: some View {
        VStack(spacing: LMSpacing.regular) {
            mealControls

            LMCard(cornerRadius: 18, padding: 14) {
                selectedMethodCard(for: .text)
                textInputArea
                commonUnitsInlineSection(title: "常用表达", badge: "点选追加", interaction: .appendText)

                LMButton(
                    title: "识别并确认",
                    systemImage: "sparkles",
                    isLoading: viewModel.isRecognizing,
                    action: startRecognition
                )
            }
        }
    }

    var manualModeSection: some View {
        VStack(spacing: LMSpacing.regular) {
            mealControls

            LMCard(cornerRadius: 18, padding: 14) {
                selectedMethodCard(for: .manual)
                manualInputFields

                LMButton(
                    title: "保存记录",
                    systemImage: "checkmark",
                    isLoading: viewModel.isSaving,
                    action: saveManual
                )
            }

            commonUnitsSection(title: "常用单位", badge: "点选填入", interaction: .fillManual)
        }
    }

    func selectedMethodCard(for mode: DietEntryViewModel.Mode) -> some View {
        let summary = methodSummary(for: mode)

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(summary.isManual ? LMColors.warmMuted : LMColors.primarySoft)
                    .frame(width: 42, height: 42)

                if summary.isManual {
                    LMManualEntryIcon(size: 21)
                } else {
                    Image(systemName: summary.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.title)
                    .font(LMTypography.bodyStrong)
                    .foregroundStyle(LMColors.textBody)

                Text(summary.subtitle)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            Button(action: changeMethod) {
                Text("换方式")
                    .font(LMTypography.badge)
                    .foregroundStyle(LMColors.primary)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(LMColors.primarySoft)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(LMColors.primaryBorder, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(summary.isManual ? LMColors.inputBorder : LMColors.primaryBorder, lineWidth: 1)
        }
    }

    var photoUploadArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LMColors.primarySoft.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LMColors.primaryBorder, lineWidth: 1)
                }

            if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text("已选择餐食照片")
                            .font(LMTypography.badge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Color.black.opacity(0.28))
                            .clipShape(Capsule())
                            .padding(12)
                    }
            } else {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LMColors.card)
                            .frame(width: 48, height: 48)

                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(LMColors.primary)
                    }

                    Text("添加餐食照片")
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textBody)

                    Text("拍清楚食物主体，识别后再确认")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(height: 210)
        .clipped()
    }

    var textInputArea: some View {
        TextEditor(text: $viewModel.textInput)
            .font(LMTypography.body)
            .foregroundStyle(LMColors.textBody)
            .frame(height: 164)
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(LMColors.warmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LMColors.inputBorder, lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                if viewModel.textInput.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例如：早餐两个鸡蛋、一杯豆浆")
                            .font(LMTypography.body)
                            .foregroundStyle(LMColors.textMuted)
                        Text("可以写食物、数量和大概份量")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
                }
            }
    }

    var manualInputFields: some View {
        VStack(spacing: 10) {
            manualField("食物名称", text: $viewModel.manualItem.name, placeholder: "如：鸡蛋")

            HStack(spacing: 10) {
                manualField("数量", text: $viewModel.manualItem.quantityText, placeholder: "2 个")
                manualField("重量", text: $viewModel.manualItem.weightGText, placeholder: "约 110g", keyboard: .decimalPad)
            }

            HStack(spacing: 10) {
                manualField("热量", text: $viewModel.manualItem.caloriesText, placeholder: "140 kcal", keyboard: .numberPad)
                manualField("蛋白", text: $viewModel.manualItem.proteinText, placeholder: "12 g", keyboard: .decimalPad)
            }

            HStack(spacing: 8) {
                manualField("脂肪", text: $viewModel.manualItem.fatText, placeholder: "10 g", keyboard: .decimalPad)
                manualField("碳水", text: $viewModel.manualItem.carbsText, placeholder: "1 g", keyboard: .decimalPad)
            }
        }
    }

    func commonUnitsSection(
        title: String,
        badge: String,
        interaction: CommonUnitInteraction
    ) -> some View {
        LMCard(cornerRadius: 16, padding: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Spacer()

                Text(badge)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(CommonFoodUnit.rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 8) {
                        ForEach(CommonFoodUnit.rows[rowIndex]) { unit in
                            commonUnitChip(unit, interaction: interaction)
                        }
                    }
                }
            }
        }
    }

    func commonUnitsInlineSection(
        title: String,
        badge: String,
        interaction: CommonUnitInteraction
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Spacer()

                Text(badge)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(CommonFoodUnit.rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 8) {
                        ForEach(CommonFoodUnit.rows[rowIndex]) { unit in
                            commonUnitChip(unit, interaction: interaction)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func commonUnitChip(
        _ unit: CommonFoodUnit,
        interaction: CommonUnitInteraction
    ) -> some View {
        switch interaction {
        case .reference:
            commonUnitLabel(unit)
        case .appendText:
            Button {
                viewModel.appendTextExpression(unit.expression)
            } label: {
                commonUnitLabel(unit)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy)
        case .fillManual:
            Button {
                viewModel.applyCommonUnit(
                    foodName: unit.foodName,
                    quantityText: unit.quantityText,
                    weightGText: unit.weightGText
                )
            } label: {
                commonUnitLabel(unit)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBusy)
        }
    }

    func commonUnitLabel(_ unit: CommonFoodUnit) -> some View {
        HStack {
            Text(unit.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LMColors.textBody)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            Text(unit.value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LMColors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func manualField(
        _ title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMTypography.badge)
                .foregroundStyle(LMColors.textSecondary)
                .frame(height: 16, alignment: .leading)

            TextField(placeholder, text: text)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(LMColors.textBody)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .lineLimit(1)
                .frame(height: 22, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 58, alignment: .topLeading)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }

    func secondaryActionLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(LMTypography.bodyStrong)
        }
        .foregroundStyle(LMColors.textBody)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }

    func confirmationSection(showsHeader: Bool = true) -> some View {
        VStack(spacing: LMSpacing.regular) {
            if showsHeader {
                LMCard(cornerRadius: 16, padding: 14) {
                    Text(viewModel.confirmationTitle)
                        .font(LMTypography.cardTitle)
                        .foregroundStyle(LMColors.textBody)

                    Text("AI 识别为估算值，请确认后再保存。")
                        .font(LMTypography.caption)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }

            mealControls

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
                title: "保存并更新首页",
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

    func closeConfirmationTopBar() {
        if showsResultOnly {
            goHomeAfterResult()
        } else {
            viewModel.closeConfirmation()
        }
    }

    func closePhotoConfirmationTopBar() {
        if showsResultOnly {
            goHomeAfterResult()
        } else {
            viewModel.selectPhotoMode()
        }
    }

    func goHomeAfterResult() {
        viewModel.selectSelectionMode()
        pendingLaunchMode = nil
        selectedTab = .home
    }

    func changeMethod() {
        selectedPhotoData = nil
        photoPickerItem = nil
        viewModel.discardDraftAndSelectSelectionMode()
    }

    func startPhotoRecognition() {
        Task {
            await viewModel.startPhotoRecognition(imageData: selectedPhotoData ?? Data())
        }
    }

    func startCameraCapture() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            viewModel.showLocalValidation("当前设备不支持拍照，请从相册选择照片")
            return
        }

        showsCameraPicker = true
    }

    func refreshRecognition() {
        Task {
            await viewModel.refreshRecognition()
        }
    }

    func saveManual() {
        Task {
            if await viewModel.saveManualEntry() {
                goHomeAfterResult()
            }
        }
    }

    func saveRecognition() {
        Task {
            if await viewModel.saveRecognitionEntry() {
                goHomeAfterResult()
            }
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
                if data != nil {
                    viewModel.clearLocalValidation()
                }
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

    func applyPendingLaunchMode() {
        guard let pendingLaunchMode else {
            return
        }

        switch pendingLaunchMode {
        case .photo:
            viewModel.selectPhotoMode()
        case .text:
            viewModel.selectTextMode()
        case .manual:
            viewModel.selectManualMode()
        }

        self.pendingLaunchMode = nil
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

private struct MealTypeSelector: View {
    @Binding var selection: MealType
    let isDisabled: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("餐次")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)

                Text("当前：\(selection.title)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LMColors.primary)
                    .lineLimit(1)
            }
            .frame(width: 74, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(MealType.allCases) { mealType in
                    mealTypeButton(mealType)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.primaryBorder.opacity(0.72), lineWidth: 1)
        }
    }

    func mealTypeButton(_ mealType: MealType) -> some View {
        let isSelected = selection == mealType

        return Button {
            selection = mealType
        } label: {
            Text(mealType.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? LMColors.primaryDeep : LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? LMColors.primarySoft : LMColors.warmSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? LMColors.primaryBorder : LMColors.inputBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel("选择\(mealType.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

private struct DietMethodSummary {
    let title: String
    let subtitle: String
    let systemImage: String
    let isManual: Bool
}

private enum CommonUnitInteraction {
    case reference
    case appendText
    case fillManual
}

private struct CommonFoodUnit: Identifiable {
    let id: String
    let title: String
    let value: String
    let expression: String
    let foodName: String
    let quantityText: String
    let weightGText: String

    static let rows: [[CommonFoodUnit]] = [
        [
            CommonFoodUnit(
                id: "rice-bowl",
                title: "一碗米饭",
                value: "约180g",
                expression: "一碗米饭（约180g）",
                foodName: "米饭",
                quantityText: "一碗",
                weightGText: "180"
            ),
            CommonFoodUnit(
                id: "soy-milk",
                title: "一杯豆浆",
                value: "约250ml",
                expression: "一杯豆浆（约250ml）",
                foodName: "豆浆",
                quantityText: "一杯",
                weightGText: "250"
            )
        ],
        [
            CommonFoodUnit(
                id: "egg",
                title: "一个鸡蛋",
                value: "约55g",
                expression: "一个鸡蛋（约55g）",
                foodName: "鸡蛋",
                quantityText: "一个",
                weightGText: "55"
            ),
            CommonFoodUnit(
                id: "nuts",
                title: "一勺坚果",
                value: "约15g",
                expression: "一勺坚果（约15g）",
                foodName: "坚果",
                quantityText: "一勺",
                weightGText: "15"
            )
        ]
    ]
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onImagePicked: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.88) {
                parent.onImagePicked(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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
