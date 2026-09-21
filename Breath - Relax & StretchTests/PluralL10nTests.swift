import Testing
import Foundation
@testable import BreathRelaxStretch

/// Counts must pluralize by the chosen language's rules. The old
/// `"exercise\(n == 1 ? "" : "s")"` ternaries could only ever be English.
struct PluralL10nTests {
    private func format(_ key: String, _ language: AppLanguage, _ n: Int) -> String {
        String(format: L10n.string(key, language: language),
               locale: language.effectiveLocale, n)
    }

    @Test func exerciseCountPluralizesInEnglish() {
        #expect(format("%lld exercises", .en, 1) == "1 exercise")
        #expect(format("%lld exercises", .en, 2) == "2 exercises")
    }

    @Test func exerciseCountPluralizesInSpanishAndFrench() {
        #expect(format("%lld exercises", .es, 1) == "1 ejercicio")
        #expect(format("%lld exercises", .es, 3) == "3 ejercicios")
        #expect(format("%lld exercises", .fr, 1) == "1 exercice")
        #expect(format("%lld exercises", .fr, 3) == "3 exercices")
    }

    @Test func frenchTreatsZeroAsSingular() {
        #expect(format("%lld exercises", .fr, 0) == "0 exercice")
    }

    @Test func chineseHasNoPluralForms() {
        #expect(format("%lld exercises", .zhHans, 1) == "1 个练习")
        #expect(format("%lld exercises", .zhHans, 5) == "5 个练习")
    }

    @Test func roundCountPluralizes() {
        #expect(format("%lld rounds", .en, 1) == "1 round")
        #expect(format("%lld rounds", .es, 2) == "2 rondas")
    }

    @Test func skippedExercisesMessagePluralizes() {
        #expect(format("%lld exercises couldn't be matched and will be skipped.", .en, 1)
                == "1 exercise couldn't be matched and will be skipped.")
        #expect(format("%lld exercises couldn't be matched and will be skipped.", .es, 2)
                == "2 ejercicios no se pudieron encontrar y se omitirán.")
    }
}
