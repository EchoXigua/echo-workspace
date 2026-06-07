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

            HStack {
                Text("记录今天体重")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LMColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(LMColors.card)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            weightInput
            dateAndNote
            stateMessage

            LMButton(
                title: viewModel.state == .saved ? "已保存" : "保存并更新趋势",
                systemImage: viewModel.state == .saved ? "checkmark" : "scalemass",
                isLoading: viewModel.isSaving,
                action: save
            )
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LMColors.background.ignoresSafeArea())
    }
}

private extension WeightEntrySheet {
    var weightInput: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                TextField("55.8", text: $viewModel.weightText)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 140)

                Text("kg")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMColors.textSecondary)
            }

            Text("支持 20-300 kg，保存失败会保留输入")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    var dateAndNote: some View {
        LMCard(cornerRadius: 18, padding: 16) {
            DatePicker("业务日期", selection: $viewModel.recordDate, displayedComponents: .date)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textBody)

            TextField("备注，可选", text: $viewModel.noteText, axis: .vertical)
                .font(LMTypography.body)
                .foregroundStyle(LMColors.textBody)
                .lineLimit(2...4)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(LMColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LMColors.inputBorder, lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    var stateMessage: some View {
        switch viewModel.state {
        case .editing, .saving:
            EmptyView()
        case .localValidationFailed(let message):
            LMStateView(kind: .error, title: "请检查体重", message: message)
        case .saved:
            LMStateView(kind: .empty, title: "体重已保存", message: savedMessage)
        case .saveFailed(let message):
            LMStateView(kind: .error, title: "保存失败", message: message)
        }
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
