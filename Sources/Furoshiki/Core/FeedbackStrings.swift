// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct FeedbackStrings {
    let sectionTitle: String
    let sectionCaption: String
    let openButton: String
    let commandBug: String
    let commandFeature: String
    let commandSubtitle: String
}

extension FeatureStrings {
    static func feedback(_ language: AppLanguage) -> FeedbackStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        case .uk: return .uk
        }
    }
}

extension FeedbackStrings {
    static let enUS = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Send a bug report or feature idea directly to the person who maintains Furoshiki.",
        openButton: "Send feedback",
        commandBug: "Report a bug",
        commandFeature: "Suggest a feature",
        commandSubtitle: "Send feedback"
    )

    static let ptBR = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Envie um relato de bug ou uma ideia de recurso diretamente para quem mantém o Furoshiki.",
        openButton: "Enviar feedback",
        commandBug: "Relatar um bug",
        commandFeature: "Sugerir um recurso",
        commandSubtitle: "Enviar feedback"
    )

    static let tr = FeedbackStrings(
        sectionTitle: "Geri bildirim",
        sectionCaption: "Bir hata bildirimini veya özellik fikrini doğrudan Furoshiki bakımcısına gönderin.",
        openButton: "Geri bildirim gönder",
        commandBug: "Hata bildir",
        commandFeature: "Özellik öner",
        commandSubtitle: "Geri bildirim gönder"
    )

    static let ru = FeedbackStrings(
        sectionTitle: "Обратная связь",
        sectionCaption: "Отправьте сообщение об ошибке или идею функции напрямую разработчику Furoshiki.",
        openButton: "Отправить отзыв",
        commandBug: "Сообщить об ошибке",
        commandFeature: "Предложить функцию",
        commandSubtitle: "Отправить отзыв"
    )

    static let es = FeedbackStrings(
        sectionTitle: "Comentarios",
        sectionCaption: "Envía un informe de error o una idea directamente a quien mantiene Furoshiki.",
        openButton: "Enviar comentarios",
        commandBug: "Informar de un error",
        commandFeature: "Sugerir una función",
        commandSubtitle: "Enviar comentarios"
    )

    static let sk = FeedbackStrings(
        sectionTitle: "Spätná väzba",
        sectionCaption: "Pošlite hlásenie o chybe alebo nápad na funkciu priamo osobe, ktorá udržiava Furoshiki.",
        openButton: "Poslať spätnú väzbu",
        commandBug: "Nahlásiť chybu",
        commandFeature: "Navrhnúť funkciu",
        commandSubtitle: "Poslať spätnú väzbu"
    )

    static let de = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Sende einen Fehlerbericht oder eine Funktionsidee direkt an den Furoshiki-Entwickler.",
        openButton: "Feedback senden",
        commandBug: "Fehler melden",
        commandFeature: "Funktion vorschlagen",
        commandSubtitle: "Feedback senden"
    )

    static let fr = FeedbackStrings(
        sectionTitle: "Avis",
        sectionCaption: "Envoyez un rapport de bug ou une idée directement à la personne qui maintient Furoshiki.",
        openButton: "Envoyer un avis",
        commandBug: "Signaler un bug",
        commandFeature: "Suggérer une fonction",
        commandSubtitle: "Envoyer un avis"
    )

    static let it = FeedbackStrings(
        sectionTitle: "Feedback",
        sectionCaption: "Invia una segnalazione o un’idea direttamente a chi mantiene Furoshiki.",
        openButton: "Invia feedback",
        commandBug: "Segnala un bug",
        commandFeature: "Suggerisci una funzione",
        commandSubtitle: "Invia feedback"
    )

    static let ja = FeedbackStrings(
        sectionTitle: "フィードバック",
        sectionCaption: "不具合の報告や機能のアイデアを Furoshiki の開発者へ直接送信します。",
        openButton: "フィードバックを送信",
        commandBug: "不具合を報告",
        commandFeature: "機能を提案",
        commandSubtitle: "フィードバックを送信"
    )

    static let ko = FeedbackStrings(
        sectionTitle: "피드백",
        sectionCaption: "버그 신고나 기능 아이디어를 Furoshiki 관리자에게 직접 보냅니다.",
        openButton: "피드백 보내기",
        commandBug: "버그 신고",
        commandFeature: "기능 제안",
        commandSubtitle: "피드백 보내기"
    )

    static let zhHans = FeedbackStrings(
        sectionTitle: "反馈",
        sectionCaption: "将错误报告或功能建议直接发送给 Furoshiki 的维护者。",
        openButton: "发送反馈",
        commandBug: "报告错误",
        commandFeature: "建议功能",
        commandSubtitle: "发送反馈"
    )

    static let zhTW = FeedbackStrings(
        sectionTitle: "意見回饋",
        sectionCaption: "將錯誤回報或功能建議直接傳送給 Furoshiki 的維護者。",
        openButton: "傳送意見",
        commandBug: "回報錯誤",
        commandFeature: "建議功能",
        commandSubtitle: "傳送意見"
    )

    static let zhHK = FeedbackStrings(
        sectionTitle: "意見回饋",
        sectionCaption: "將錯誤報告或功能建議直接傳送給 Furoshiki 的維護者。",
        openButton: "傳送意見",
        commandBug: "報告錯誤",
        commandFeature: "建議功能",
        commandSubtitle: "傳送意見"
    )
    static let uk = FeedbackStrings(
        sectionTitle: "Відгук",
        sectionCaption: "Надішліть звіт про помилку або ідею функції безпосередньо розробнику Furoshiki.",
        openButton: "Надіслати відгук",
        commandBug: "Повідомити про помилку",
        commandFeature: "Запропонувати функцію",
        commandSubtitle: "Надіслати відгук"
    )
}
