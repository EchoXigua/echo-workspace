import SwiftUI

struct WeightEntrySheet: View {
    @StateObject private var viewModel: WeightViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WeightViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            LMSheetHandle()
                .frame(maxWidth: .infinity, alignment: .center)

            header
            weightInput
            quickWeights
            noteInput
            stateMessage

            LMButton(
                title: viewModel.state == .saved ? "已保存" : "保存并更新趋势",
                systemImage: viewModel.state == .saved ? "checkmark" : nil,
                height: 50,
                isLoading: viewModel.isSaving,
                action: save
            )
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LMColors.card.ignoresSafeArea())
    }
}

private extension WeightEntrySheet {
    var header: some View {
        HStack(alignment: .center) {
            Text("记录今天体重")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color(hex: 0xF6FBF7))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭")
        }
    }

    var weightInput: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                TextField("55.8", text: $viewModel.weightText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 104)
                    .textFieldStyle(.plain)

                Text("kg")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
    }

    var quickWeights: some View {
        HStack(spacing: 8) {
            ForEach(quickWeightOptions, id: \.self) { value in
                Button {
                    viewModel.weightText = display(value)
                } label: {
                    Text(display(value))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelectedQuickWeight(value) ? LMColors.primaryDeep : LMColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSelectedQuickWeight(value) ? LMColors.primarySoft : LMColors.warmSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(isSelectedQuickWeight(value) ? LMColors.primary : LMColors.inputBorder, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("选择体重 \(display(value)) kg")
            }
        }
    }

    var noteInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("备注（选填）")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LMColors.primaryDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LMColors.primarySoft)
                .clipShape(Capsule())

            TextField("下降波动正常，记录当时状态方便回看。", text: $viewModel.noteText, axis: .vertical)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LMColors.textBody)
                .lineLimit(2...3)
                .textFieldStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF6FBF7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    var stateMessage: some View {
        switch viewModel.state {
        case .editing, .saving:
            EmptyView()
        case .localValidationFailed(let message):
            compactStateMessage(title: "请检查体重", message: message, color: LMColors.danger, isError: true)
        case .saved:
            compactStateMessage(title: "体重已保存", message: savedMessage, color: LMColors.primaryDeep, isError: false)
        case .saveFailed(let message):
            compactStateMessage(title: "保存失败", message: message, color: LMColors.danger, isError: true)
        }
    }

    func compactStateMessage(title: String, message: String, color: Color, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isError ? "exclamationmark.circle" : "checkmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)

                Text(message)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isError ? LMColors.dangerSoft : LMColors.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var savedMessage: String {
        guard let entry = viewModel.savedEntry else {
            return "趋势由服务端统计，本页不自行计算。"
        }
        return "\(display(entry.weightKg)) kg 已记录，趋势由服务端统计。"
    }

    func save() {
        Task {
            _ = await viewModel.save()
        }
    }

    var quickWeightOptions: [Double] {
        let center = currentWeightValue ?? 55.8
        return [-0.2, -0.1, 0, 0.1, 0.2].map { center + $0 }
    }

    var currentWeightValue: Double? {
        guard let value = Double(viewModel.weightText.trimmingCharacters(in: .whitespacesAndNewlines)),
              (20...300).contains(value) else {
            return nil
        }
        return value
    }

    func isSelectedQuickWeight(_ value: Double) -> Bool {
        guard let currentWeightValue else {
            return false
        }
        return abs(currentWeightValue - value) < 0.001
    }

    func display(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

private struct WeightEntrySheetPreviewContainer: View {
    var body: some View {
        WeightEntrySheet(
            viewModel: WeightViewModel(
                apiClient: MockAPIClient(delayNanoseconds: 0),
                weightText: "55.8"
            )
        )
    }
}

struct WeightEntrySheet_Previews: PreviewProvider {
    static var previews: some View {
        WeightEntrySheetPreviewContainer()
    }
}
