import SwiftUI

struct ProfileDataPlanDetailView: View {
    let payload: ProfileRoutePayload

    var body: some View {
        ProfileSubpageScaffold(title: "数据与计划") {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("热量计划")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)

                        Text("由身体档案估算，后续可在档案中微调。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    LMTag(title: "每日目标")
                }

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(payload.dailyTarget.replacingOccurrences(of: " kcal", with: ""))
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(LMColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("kcal")
                        .font(LMTypography.bodyStrong)
                        .foregroundStyle(LMColors.textSecondary)
                }
            }

            LazyVGrid(columns: twoColumns, spacing: LMSpacing.small) {
                ProfilePlanMetricCard(title: "基础代谢", value: payload.bmr, systemImage: "flame")
                ProfilePlanMetricCard(title: "BMI", value: payload.bmi, systemImage: "figure")
                ProfilePlanMetricCard(title: "当前体重", value: payload.currentWeight, systemImage: "scalemass")
                ProfilePlanMetricCard(title: "活动水平", value: payload.activityLevel, systemImage: "figure.walk")
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("身体档案")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                ProfileInfoRow(title: "昵称", value: payload.displayName)
                ProfileInfoRow(title: "基础状态", value: payload.summary)
                ProfileInfoRow(title: "身高", value: payload.height)
                ProfileInfoRow(title: "目标体重", value: payload.targetWeight)
            }
        }
    }

    private var twoColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: LMSpacing.small),
            GridItem(.flexible(), spacing: LMSpacing.small)
        ]
    }
}

struct ProfileWeightTrendView: View {
    let payload: ProfileRoutePayload

    var body: some View {
        ProfileSubpageScaffold(title: "体重趋势") {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("当前体重")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)

                        Text(payload.currentWeight)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(LMColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("目标")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)

                        Text(payload.targetWeight)
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textBody)
                    }
                }

                ProfileTrendPlaceholderChart()
            }

            LMCard(cornerRadius: 16, padding: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                        .frame(width: 38, height: 38)
                        .background(LMColors.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("趋势会随记录更新")
                            .font(LMTypography.bodyStrong)
                            .foregroundStyle(LMColors.textBody)

                        Text("从首页或记录页补充体重后，这里会展示最近变化。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct ProfileDataSyncView: View {
    let isVisitor: Bool
    let onLoginRequired: () -> Void

    var body: some View {
        ProfileSubpageScaffold(title: "数据同步") {
            LMCard(cornerRadius: 16, padding: 14) {
                HStack(spacing: 12) {
                    Image(systemName: isVisitor ? "iphone" : "checkmark.icloud")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LMColors.primary)
                        .frame(width: 44, height: 44)
                        .background(LMColors.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(isVisitor ? "当前保存在本机" : "数据已跟随账号保存")
                            .font(LMTypography.cardTitle)
                            .foregroundStyle(LMColors.textBody)

                        Text(isVisitor ? "登录后可把饮食、体重和身体档案同步到账号。" : "饮食、体重、身体档案会按账号状态同步。")
                            .font(LMTypography.caption)
                            .foregroundStyle(LMColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if isVisitor {
                    LMButton(title: "登录同步", height: 48, action: onLoginRequired)
                }
            }

            LMCard(cornerRadius: 16, padding: 14) {
                Text("同步内容")
                    .font(LMTypography.cardTitle)
                    .foregroundStyle(LMColors.textBody)

                ProfileInfoRow(title: "身体档案", value: "身高、体重、目标")
                ProfileInfoRow(title: "饮食记录", value: "本地记录登录后保留")
                ProfileInfoRow(title: "日报", value: "登录后生成和查看")
            }
        }
    }
}

private struct ProfileSubpageScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LMSpacing.large) {
                content
            }
            .padding(.horizontal, LMSpacing.large)
            .padding(.top, LMSpacing.medium)
            .padding(.bottom, 28)
        }
        .background(LMColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            ProfileSubpageHeader(title: title) {
                dismiss()
            }
        }
    }
}

private struct ProfileSubpageHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LMColors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(LMColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LMColors.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("返回")

            Spacer()

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, LMSpacing.large)
        .padding(.bottom, LMSpacing.small)
        .background(LMColors.background)
    }
}

private struct ProfilePlanMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LMColors.primary)
                .frame(width: 32, height: 32)
                .background(LMColors.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(LMTypography.caption)
                    .foregroundStyle(LMColors.textSecondary)

                Text(value)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(LMColors.textBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }
}

private struct ProfileInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(LMTypography.bodyStrong)
                .foregroundStyle(LMColors.textBody)

            Spacer()

            Text(value)
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.vertical, 2)
    }
}

private struct ProfileTrendPlaceholderChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(0..<7) { index in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(index < 2 ? LMColors.primarySoft : LMColors.warmMuted)
                        .frame(height: CGFloat([42, 52, 46, 58, 50, 64, 56][index]))
                        .overlay(alignment: .top) {
                            if index == 1 {
                                Circle()
                                    .fill(LMColors.primary)
                                    .frame(width: 7, height: 7)
                                    .offset(y: -3)
                            }
                        }
                }
            }
            .frame(height: 84, alignment: .bottom)

            Text("暂无完整趋势，记录几次体重后会形成曲线。")
                .font(LMTypography.caption)
                .foregroundStyle(LMColors.textSecondary)
        }
        .padding(14)
        .background(LMColors.warmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LMColors.inputBorder, lineWidth: 1)
        }
    }
}
