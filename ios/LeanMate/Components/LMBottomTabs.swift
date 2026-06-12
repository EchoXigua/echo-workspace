import SwiftUI

struct LMBottomTabItem<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
    let systemImage: String
}

struct LMBottomTabs<ID: Hashable>: View {
    let items: [LMBottomTabItem<ID>]
    @Binding var selection: ID

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: LMSpacing.xSmall) {
                ForEach(items) { item in
                    tab(item)
                }
            }
            .padding(5)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(LMColors.border, lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x143B23, alpha: 0.06), radius: 14, x: 0, y: 4)
        }
        .padding(.horizontal, LMSpacing.large)
        .padding(.top, 0)
        .padding(.bottom, LMSpacing.regular)
    }
}

struct LMTabScreen<ID: Hashable, Content: View>: View {
    let items: [LMBottomTabItem<ID>]
    @Binding var selection: ID
    @Environment(\.lmTabScreenHidesBottomTabs) private var hidesBottomTabs
    private let content: Content

    init(
        items: [LMBottomTabItem<ID>],
        selection: Binding<ID>,
        @ViewBuilder content: () -> Content
    ) {
        self.items = items
        _selection = selection
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSpacing.regular) {
                    content
                }
                .padding(.horizontal, LMSpacing.large)
                .padding(.top, LMSpacing.small)
                .padding(.bottom, LMSpacing.large)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            if !hidesBottomTabs {
                LMBottomTabs(items: items, selection: $selection)
            }
        }
        .background(LMColors.background.ignoresSafeArea())
    }
}

private extension LMBottomTabs {
    func tab(_ item: LMBottomTabItem<ID>) -> some View {
        let isSelected = selection == item.id

        return Button {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selection = item.id
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .medium))
                Text(item.title)
                    .font(LMTypography.tab)
            }
            .foregroundStyle(isSelected ? LMColors.primary : LMColors.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? LMColors.primarySoft : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? LMColors.primaryBorder : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }
}

private struct LMBottomTabsPreview: View {
    @State private var selection = AppTab.home

    var body: some View {
        LMBottomTabs(
            items: AppTab.allCases.map {
                LMBottomTabItem(id: $0, title: $0.title, systemImage: $0.systemImage)
            },
            selection: $selection
        )
        .background(LMColors.background)
    }
}

struct LMBottomTabs_Previews: PreviewProvider {
    static var previews: some View {
        LMBottomTabsPreview()
    }
}

private struct LMTabScreenHidesBottomTabsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var lmTabScreenHidesBottomTabs: Bool {
        get { self[LMTabScreenHidesBottomTabsKey.self] }
        set { self[LMTabScreenHidesBottomTabsKey.self] = newValue }
    }
}
