import SwiftUI

enum LMStateKind {
    case loading
    case empty
    case error
}

struct LMStateView: View {
    let kind: LMStateKind
    let title: String
    let message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        LMCard {
            LMTag(title: tagTitle, style: tagStyle)

            Text(title)
                .font(LMTypography.title)
                .foregroundStyle(LMColors.textBody)
                .fixedSize(horizontal: false, vertical: true)

            if let message {
                Text(message)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                LMButton(title: actionTitle, height: 48, action: action)
            }
        }
    }
}

private extension LMStateView {
    var tagTitle: String {
        switch kind {
        case .loading:
            "正在生成"
        case .empty:
            "暂无内容"
        case .error:
            "需要重试"
        }
    }

    var tagStyle: LMTagStyle {
        switch kind {
        case .loading, .empty:
            .primary
        case .error:
            .danger
        }
    }
}

struct LMStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LMStateView(kind: .empty, title: "今天还没有记录", message: "第一条记录从早餐开始。")
            LMStateView(kind: .error, title: "加载失败", message: "请稍后重试。", actionTitle: "重试") {}
        }
        .padding()
        .background(LMColors.background)
    }
}
