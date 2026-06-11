import SwiftUI

enum OnboardingLegalDocument: Hashable {
    case userAgreement
    case privacyPolicy
}

struct OnboardingLegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss

    let document: OnboardingLegalDocument

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    metadata
                    intro
                    sections
                    contactCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

            LMButton(title: "我知道了") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(LMColors.background)
        }
        .background(LMColors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension OnboardingLegalDocumentView {
    var content: OnboardingLegalDocumentContent {
        document.content
    }

    var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
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

            Text(content.navTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 42, height: 42)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.pill)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(LMColors.primaryDeep)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LMColors.primarySoft)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(LMColors.primaryBorder, lineWidth: 1)
                }

            Text(content.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(LMColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(content.summary)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(LMColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var metadata: some View {
        VStack(spacing: 8) {
            ForEach(Array(content.metadata.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(row.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LMColors.textSecondary)
                        .frame(width: 76, alignment: .leading)

                    Text(row.value)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LMColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }

    var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(content.intro.enumerated()), id: \.offset) { _, paragraph in
                paragraphText(paragraph)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var sections: some View {
        VStack(spacing: 10) {
            ForEach(Array(content.sections.enumerated()), id: \.offset) { index, section in
                legalSection(index: index + 1, section: section)
            }
        }
    }

    var contactCard: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LMColors.primary)
                .frame(width: 24, height: 24)

            Text(content.contact.prompt)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0x536B5D))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: 0xEFF9F3))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xD9F0E2), lineWidth: 1)
        }
    }

    func legalSection(index: Int, section: OnboardingLegalSection) -> some View {
        HStack(alignment: .top, spacing: 12) {
            sectionNumberBadge(index)

            VStack(alignment: .leading, spacing: 8) {
                Text(section.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LMColors.textPrimary)

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    legalBlock(block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(LMColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMColors.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    func legalBlock(_ block: OnboardingLegalBlock) -> some View {
        switch block {
        case .paragraph(let text):
            paragraphText(text)
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 5) {
                ForEach(items, id: \.self) { item in
                    bulletRow(item, color: LMColors.textSecondary)
                }
            }
        }
    }

    func sectionNumberBadge(_ index: Int) -> some View {
        Text(String(format: "%02d", index))
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(LMColors.primaryDeep)
            .frame(width: 34, height: 34)
            .background(Color(hex: 0xEAF8EF))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(LMColors.primaryBorder, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    func paragraphText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11.2, weight: .medium))
            .foregroundStyle(LMColors.textSecondary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    func bulletRow(_ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .padding(.top, 7)

            Text(text)
                .font(.system(size: 11.2, weight: .medium))
                .foregroundStyle(color)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingLegalDocumentContent {
    let navTitle: String
    let pill: String
    let title: String
    let summary: String
    let metadata: [OnboardingLegalMetadataRow]
    let intro: [String]
    let sections: [OnboardingLegalSection]
    let contact: OnboardingLegalContact
}

private struct OnboardingLegalMetadataRow {
    let label: String
    let value: String
}

private struct OnboardingLegalSection {
    let title: String
    let blocks: [OnboardingLegalBlock]
}

private enum OnboardingLegalBlock {
    case paragraph(String)
    case bullets([String])
}

private struct OnboardingLegalContact {
    let prompt: String
}

private extension OnboardingLegalDocument {
    var content: OnboardingLegalDocumentContent {
        switch self {
        case .userAgreement:
            userAgreementContent
        case .privacyPolicy:
            privacyPolicyContent
        }
    }

    var userAgreementContent: OnboardingLegalDocumentContent {
        OnboardingLegalDocumentContent(
            navTitle: "用户协议",
            pill: "使用前须知",
            title: "瘦搭用户协议",
            summary: "请在使用前仔细阅读并理解本协议，特别是健康提示、责任限制、账号管理和个人信息相关条款。",
            metadata: [
                OnboardingLegalMetadataRow(label: "最后更新", value: "2026 年 6 月 11 日"),
                OnboardingLegalMetadataRow(label: "生效日期", value: "2026 年 6 月 11 日"),
                OnboardingLegalMetadataRow(label: "服务提供者", value: "【待填写公司/个人主体名称】"),
                OnboardingLegalMetadataRow(label: "联系方式", value: "【待填写联系邮箱】")
            ],
            intro: [
                "本《用户协议》适用于你使用“瘦搭 / LeanMate”的 iOS 应用、后续可能提供的其他客户端、网站、接口及相关服务。",
                "如果你点击同意、登录、继续使用或以其他方式使用本服务，即表示你已阅读、理解并同意本协议。若你不同意本协议，请停止使用需要同意本协议后才能使用的功能。"
            ],
            sections: [
                OnboardingLegalSection(
                    title: "服务内容",
                    blocks: [
                        .paragraph("瘦搭是一款专注减脂场景的饮食与体重记录工具，主要提供以下能力："),
                        .bullets([
                            "通过拍照、文字解析或手动输入记录饮食。",
                            "估算食物热量、蛋白质、脂肪、碳水等营养信息。",
                            "根据你填写的基础信息生成 BMI、BMR 和每日推荐热量目标。",
                            "记录体重、展示趋势和日常统计。",
                            "基于饮食、体重和目标信息生成 AI 日报或相关反馈。",
                            "使用 Apple 登录后进行账号同步和跨设备数据恢复。"
                        ]),
                        .paragraph("瘦搭会持续迭代功能。新增、调整或下线部分功能时，我们会以 App 内提示、版本说明或其他合理方式告知你。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "账号与登录",
                    blocks: [
                        .paragraph("你可以选择以下方式使用瘦搭："),
                        .bullets([
                            "使用 Apple 登录创建或进入账号，以便同步饮食记录、体重记录、目标设置和日报等数据。",
                            "选择“随便看看”，体验不依赖账号同步的本地或示例功能。"
                        ]),
                        .paragraph("你应当妥善保管账号访问权限、设备和系统账号安全。因你主动泄露设备、系统账号或登录凭证导致的数据风险，由你自行承担相应后果。"),
                        .paragraph("如果你发现账号存在异常登录、数据异常或其他安全问题，请及时通过本协议列明的联系方式联系我们。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "用户档案与目标",
                    blocks: [
                        .paragraph("为了生成基础热量目标和记录体验，瘦搭可能需要你填写或确认以下信息："),
                        .bullets([
                            "性别、年龄、身高、当前体重、目标体重、活动水平。",
                            "饮食记录、食物图片、文字描述、餐次、记录日期。",
                            "体重记录、目标设置、日报查看和记录行为。"
                        ]),
                        .paragraph("你应尽量提供真实、准确的信息。若信息不准确，相关计算结果、推荐目标、日报分析和趋势展示也可能不准确。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "健康提示与非医疗声明",
                    blocks: [
                        .paragraph("瘦搭不是医疗器械、医疗服务、诊断工具或治疗方案提供者。瘦搭展示的热量、BMI、BMR、体重目标、营养估算、AI 日报和饮食建议仅用于日常记录、习惯管理和一般参考，不构成医疗诊断、治疗建议、处方建议或专业营养处方。"),
                        .paragraph("如果你存在以下情况，请在使用瘦搭建议或调整饮食前咨询医生、注册营养师或其他合格专业人士："),
                        .bullets([
                            "患有糖尿病、肾病、肝病、心血管疾病、进食障碍等基础疾病。",
                            "处于孕期、哺乳期、术后恢复期或未成年阶段。",
                            "正在接受医疗治疗、服用处方药或需要特殊饮食管理。",
                            "计划进行快速减重、极低热量饮食或其他高风险饮食调整。"
                        ]),
                        .paragraph("你应根据自身身体状况合理使用本服务。因忽视专业医疗建议、过度节食、错误记录或不当使用本服务造成的风险，由你自行承担。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "AI 识别与内容准确性",
                    blocks: [
                        .paragraph("瘦搭可能使用 AI 能力识别图片、解析文本、估算营养和生成日报。AI 输出存在不确定性，可能因图片质量、食物遮挡、份量描述不清、模型误差、食物数据库差异等原因产生偏差。"),
                        .paragraph("你应在保存记录前核对识别结果，并可通过编辑、删除或重新记录等方式修正。瘦搭不会承诺 AI 识别、热量估算或日报建议完全准确，也不保证使用本服务一定达成减重、增肌或其他身体目标。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "用户内容与使用规则",
                    blocks: [
                        .paragraph("你在瘦搭中上传、输入、保存或生成的内容包括但不限于食物照片、文字描述、饮食记录、体重记录和备注。你应确保这些内容来源合法，且不会侵犯他人合法权益。"),
                        .paragraph("你不得利用本服务从事以下行为："),
                        .bullets([
                            "上传违法、侵权、色情、暴力、骚扰、歧视、欺诈或与饮食记录无关的内容。",
                            "干扰、破坏、绕过或攻击瘦搭的系统、接口、模型、数据或安全机制。",
                            "以自动化、爬取、逆向工程等方式超出正常使用范围访问本服务。",
                            "冒充他人、盗用账号、恶意提交虚假数据或影响其他用户使用。",
                            "将瘦搭输出用于医疗诊断、治疗决策、商业营养处方或其他高风险场景。"
                        ]),
                        .paragraph("如你违反本协议，我们有权根据影响程度采取删除内容、限制功能、暂停账号、终止服务或依法追究责任等措施。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "知识产权",
                    blocks: [
                        .paragraph("瘦搭及相关软件、界面、视觉设计、文本、图标、商标、算法、数据库、接口和技术实现的知识产权归服务提供者或合法权利人所有。未经书面许可，你不得复制、修改、分发、出售、出租、反向工程或以其他方式使用瘦搭的受保护内容。"),
                        .paragraph("你保留对自己上传或输入内容的合法权益。为了向你提供识别、记录、统计、同步和日报等功能，你授予我们在提供服务所必需范围内处理、存储、分析、展示和传输相关内容的权利。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "费用与后续付费功能",
                    blocks: [
                        .paragraph("当前版本如未展示付费信息，则相关功能按当前页面说明提供。未来如推出订阅、增值服务或其他付费功能，我们会在购买前明确展示价格、服务内容、续费规则、取消方式和退款规则。你可以自行决定是否购买。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "账号注销、数据删除与退出登录",
                    blocks: [
                        .paragraph("你可以在 App 的“我的”或“设置”页面管理账号同步、退出登录、删除记录或申请注销账号。账号注销后，我们会按隐私政策和法律要求删除或匿名化相关个人信息，但法律法规要求保留、为争议处理所必需或备份系统延迟删除的情况除外。"),
                        .paragraph("如相关功能暂未上线，你可以通过本协议列明的联系方式提交注销或删除请求。我们会在合理期限内处理，并在需要核验身份时要求你提供必要信息。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "服务变更、中断与终止",
                    blocks: [
                        .paragraph("我们会尽力保障服务稳定，但不承诺服务永不中断。以下情况可能导致服务不可用、数据延迟或部分功能受限："),
                        .bullets([
                            "系统维护、版本更新、服务器故障、网络异常。",
                            "第三方服务、云服务、AI 服务、Apple 登录服务不可用。",
                            "法律法规、监管要求或安全风险处理。",
                            "你违反本协议或存在异常使用行为。"
                        ]),
                        .paragraph("我们有权根据运营、安全、合规或产品规划调整、暂停或终止部分服务，但会尽量降低对你正常使用的影响。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "责任限制",
                    blocks: [
                        .paragraph("在法律允许的范围内，瘦搭按现状和可用状态提供服务。我们不对以下事项作出保证："),
                        .bullets([
                            "识别结果、营养估算、热量目标、AI 日报或趋势分析完全准确。",
                            "使用本服务一定实现减重、健康改善或行为改变。",
                            "服务始终无错误、无中断、无延迟或完全符合你的预期。"
                        ]),
                        .paragraph("因你自身记录错误、身体状况差异、未咨询专业人士、第三方服务异常、不可抗力或超出我们合理控制范围的原因造成的损失，我们不承担超出法律规定范围的责任。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "未成年人使用",
                    blocks: [
                        .paragraph("瘦搭主要面向 18 周岁及以上用户。未满 18 周岁的用户应在监护人同意和指导下使用本服务。我们不主动面向 14 周岁以下儿童提供服务。若你是儿童监护人，并认为儿童在未经同意的情况下向我们提供了个人信息，请及时联系我们。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "协议更新",
                    blocks: [
                        .paragraph("我们可能根据产品功能、法律法规、运营情况或合规要求更新本协议。更新后，我们会通过 App 内提示、页面公告或其他合理方式通知你。若更新涉及你的重要权益，我们会以更显著方式提示并在必要时重新取得你的同意。"),
                        .paragraph("如你在协议更新后继续使用本服务，即表示你接受更新后的协议；如你不同意更新内容，可以停止使用相关服务或申请注销账号。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "法律适用与争议解决",
                    blocks: [
                        .paragraph("本协议的订立、履行、解释及争议解决适用中华人民共和国大陆地区法律。因本协议或本服务产生的争议，双方应先友好协商；协商不成的，提交服务提供者住所地有管辖权的人民法院处理，法律另有强制规定的除外。")
                    ]
                )
            ],
            contact: OnboardingLegalContact(
                prompt: "如对条款有疑问，可通过 App 内反馈联系我们。"
            )
        )
    }

    var privacyPolicyContent: OnboardingLegalDocumentContent {
        OnboardingLegalDocumentContent(
            navTitle: "隐私政策",
            pill: "数据说明",
            title: "瘦搭隐私政策",
            summary: "本政策说明我们如何收集、使用、存储、共享和保护你的信息，以及你如何管理自己的信息。",
            metadata: [
                OnboardingLegalMetadataRow(label: "最后更新", value: "2026 年 6 月 11 日"),
                OnboardingLegalMetadataRow(label: "生效日期", value: "2026 年 6 月 11 日"),
                OnboardingLegalMetadataRow(label: "处理者", value: "【待填写公司/个人主体名称】"),
                OnboardingLegalMetadataRow(label: "联系方式", value: "【待填写联系邮箱】")
            ],
            intro: [
                "瘦搭 / LeanMate 重视你的个人信息和隐私保护。本《隐私政策》说明我们在提供饮食记录、体重记录、热量目标、AI 日报、账号同步等服务时，如何处理你的信息。",
                "请你在使用瘦搭前仔细阅读本政策。若你不同意本政策，请不要使用需要收集个人信息的功能。你可以选择“随便看看”，体验不依赖账号同步的部分功能。"
            ],
            sections: [
                OnboardingLegalSection(
                    title: "我们收集的信息",
                    blocks: [
                        .paragraph("我们会根据你使用的功能，遵循必要、正当、明确的原则收集以下信息。"),
                        .paragraph("账号与登录信息：当你使用 Apple 登录时，我们可能处理 Apple 提供的用户唯一标识、你授权提供的昵称或邮箱、LeanMate 账号 ID、登录状态、访问令牌、刷新令牌及账号创建时间。我们不会要求或保存你的 Apple ID 密码。"),
                        .paragraph("用户档案与目标信息：为了估算基础热量目标和展示减脂状态，我们可能收集性别、年龄、身高、当前体重、目标体重、活动水平、BMI、BMR、每日推荐热量目标、目标生成时间和档案完成状态。"),
                        .paragraph("饮食记录信息：当你记录饮食时，我们可能收集食物图片、文字描述、手动输入的食物名称、份量、餐次、记录日期、AI 识别或用户确认后的营养估算、识别置信度、编辑记录和确认状态。"),
                        .paragraph("体重与日报信息：当你使用体重记录和 AI 日报时，我们可能收集体重记录日期、体重数值、备注、每日营养统计快照、剩余热量、记录次数、AI 日报摘要、问题分析、建议和查看状态。"),
                        .paragraph("设备、日志与诊断信息：为了保障服务安全、定位问题和改进体验，我们可能收集设备型号、操作系统版本、App 版本、网络类型、请求时间、接口错误、崩溃日志、性能数据、安全日志和异常请求信息。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "我们如何使用信息",
                    blocks: [
                        .paragraph("我们会将信息用于以下目的："),
                        .bullets([
                            "创建和管理账号，完成 Apple 登录和账号同步。",
                            "计算 BMI、BMR、每日推荐热量目标和首页统计。",
                            "完成食物识别、文本解析、手动记录和营养估算。",
                            "保存饮食、体重、目标和日报，支持跨设备恢复。",
                            "生成 AI 日报、记录趋势和生活化反馈。",
                            "排查故障、防止滥用、保障账号和系统安全。",
                            "在不识别个人身份的前提下，统计功能使用情况并改进产品体验。",
                            "履行法律法规、监管要求或争议处理需要。"
                        ]),
                        .paragraph("我们不会将你的个人信息出售给第三方，也不会将饮食、体重、目标等信息用于无关广告追踪。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "设备权限说明",
                    blocks: [
                        .paragraph("瘦搭会在你使用具体功能时申请必要权限。你可以在 iOS 系统设置中管理权限。"),
                        .bullets([
                            "相机：用于拍摄食物照片并进行饮食识别。",
                            "相册：用于选择已有食物图片进行识别。",
                            "网络：用于账号登录、数据同步、AI 识别和接口请求。",
                            "通知：如后续提供记录提醒功能，将仅在你授权后使用。"
                        ]),
                        .paragraph("如果你拒绝某项权限，只会影响对应功能，不会影响与该权限无关的其他功能。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "AI 服务与自动化处理",
                    blocks: [
                        .paragraph("瘦搭可能通过后端调用 AI 服务处理食物图片、文字描述和统计数据，以提供识别结果、营养估算和日报内容。"),
                        .paragraph("AI 处理可能涉及食物图片或图片中的食物特征、你输入的饮食文字、餐次和份量描述、当日饮食、体重、热量目标和营养统计。"),
                        .paragraph("AI 输出仅作为生活记录和一般参考，不构成医疗建议。你可以编辑或删除 AI 识别结果，也可以选择不使用拍照识别、文本解析或 AI 日报功能。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "第三方服务与共享",
                    blocks: [
                        .paragraph("为实现产品功能，我们可能在必要范围内使用第三方服务。实际接入前，我们会尽量确保第三方具备合理的数据保护能力，并在必要时更新本政策或第三方清单。"),
                        .paragraph("可能涉及的第三方类型包括 Apple、云服务商、AI 服务提供方、崩溃和日志分析服务。"),
                        .paragraph("除取得你的单独同意或授权、为实现你主动使用的功能所必需、法律法规或监管要求、保护人身财产和信息安全、合并分立或资产转让等情况外，我们不会向第三方共享你的个人信息。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "信息存储与保存期限",
                    blocks: [
                        .paragraph("我们会在实现本政策所述目的所需的最短期限内保存你的个人信息，除非法律法规要求或允许更长保存。"),
                        .bullets([
                            "账号信息：在账号存续期间保存；账号注销后删除或匿名化。",
                            "饮食、体重、目标和日报：在你保留账号或记录期间保存；你删除记录或注销账号后删除或匿名化。",
                            "临时识别图片和 AI 原始处理信息：原则上不超过 180 天，除非你保存为正式饮食记录或法律另有要求。",
                            "日志和诊断信息：原则上不超过 180 天，安全审计或争议处理需要时可依法延长。",
                            "备份数据：会在备份更新周期内逐步删除或覆盖。"
                        ])
                    ]
                ),
                OnboardingLegalSection(
                    title: "你的权利",
                    blocks: [
                        .paragraph("你可以依法管理自己的个人信息，包括查阅和复制、更正和补充、删除、撤回同意、注销账号、获取解释。"),
                        .paragraph("你可以通过 App 内“我的”或“设置”页面操作，也可以通过本政策列明的联系方式联系我们。我们会在验证你的身份后处理请求。需人工处理的请求，我们通常会在 15 个工作日内完成或说明原因，法律法规另有规定的除外。"),
                        .paragraph("撤回同意或删除信息后，可能导致部分功能不可用。例如，撤回相机权限后无法拍照识别；删除体重记录后趋势和日报可能不完整。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "账号注销",
                    blocks: [
                        .paragraph("你可以在 App 内提交账号注销请求，或通过本政策列明的联系方式联系我们。账号注销后，你将无法继续使用该账号同步数据；与账号相关的饮食、体重、目标、日报等信息将被删除或匿名化；法律法规要求保留、争议处理所需、交易安全和备份延迟删除的信息除外。"),
                        .paragraph("注销前，请确认你已备份需要保留的信息。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "信息安全",
                    blocks: [
                        .paragraph("我们会采取合理的技术和管理措施保护你的个人信息，包括传输加密、访问控制、权限分级、登录令牌和敏感配置的安全存储、数据备份、日志审计和异常监控，以及对工作人员和受托处理方进行必要的数据保护要求。"),
                        .paragraph("但请理解，互联网环境不存在绝对安全。发生个人信息安全事件时，我们会按照法律法规要求及时采取补救措施，并在必要时通知你和相关主管部门。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "未成年人保护",
                    blocks: [
                        .paragraph("瘦搭主要面向 18 周岁及以上用户。未满 18 周岁的用户应在监护人同意和指导下使用。我们不主动面向 14 周岁以下儿童提供服务。"),
                        .paragraph("如果我们发现未经监护人同意收集了儿童个人信息，会尽快删除或采取其他必要措施。监护人如发现相关情况，可通过本政策列明的联系方式联系我们。")
                    ]
                ),
                OnboardingLegalSection(
                    title: "政策更新",
                    blocks: [
                        .paragraph("我们可能根据产品功能、法律法规、第三方服务或数据处理方式变化更新本政策。发生重大变化时，我们会通过 App 内弹窗、页面提示或其他显著方式通知你，并在必要时重新取得你的同意。"),
                        .paragraph("重大变化包括个人信息处理目的、方式或范围发生重要变化，敏感个人信息处理规则变化，第三方共享、转让或公开披露规则变化，个人信息权利和行使方式变化，联系方式、投诉渠道或处理者主体变化等。")
                    ]
                )
            ],
            contact: OnboardingLegalContact(
                prompt: "如对隐私政策有疑问，可通过 App 内反馈联系我们。"
            )
        )
    }
}

#Preview {
    NavigationStack {
        OnboardingLegalDocumentView(document: .userAgreement)
    }
}
