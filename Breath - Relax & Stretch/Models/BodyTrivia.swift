import Foundation

/// Curated, launch-splash trivia about the body, stretching, and breathing —
/// shown one at a time on `AppLoadingView` while the anatomy mesh preloads.
enum BodyTrivia {
    static let facts: [String] = [
        "Your body has over 600 muscles — about 40% of your total body weight.",
        "The hamstrings cross two joints, which is why they're tight for almost everyone.",
        "The masseter, in your jaw, is the strongest muscle for its size.",
        "Fascia, the connective tissue wrapping your muscles, carries almost as many nerve endings as your skin.",
        "A slow exhale switches on your parasympathetic nervous system — the body's built-in calm-down response.",
        "You take roughly 20,000 breaths a day without ever thinking about one.",
        "You're born with 33 vertebrae — nine fuse together by adulthood, leaving 26.",
        "Muscles only pull. Every joint needs an opposing pair just to move both ways.",
        "Fascia takes about 4-6 weeks of consistent stretching to actually lengthen, not just relax.",
        "The soleus, a deep calf muscle, is nicknamed the 'second heart' for how it helps pump blood back up from your legs.",
        "A yawn stretches your jaw and lungs at once — it's thought to help cool and reoxygenate the brain.",
        "Sitting for long stretches is one of the most common causes of tight hip flexors.",
        "Box breathing — inhale, hold, exhale, hold, each for 4 counts — is used by Navy SEALs to stay calm under pressure.",
        "Your diaphragm does about 70% of the work in a normal breath.",
        "Cats and dogs stretch right after waking for the same reason you do — it resets muscle tone after stillness.",
        "The IT band isn't a muscle at all — it's a thick strip of fascia running from hip to shin.",
        "Holding a stretch for about 30 seconds gives the stretch reflex time to relax into a real release.",
    ]

    /// A random fact, guaranteed different from `current` when more than one
    /// fact exists (falls back to the only fact when there's just one).
    static func randomFact(excluding current: String? = nil) -> String {
        guard facts.count > 1 else { return facts[0] }
        var next = facts.randomElement()!
        while next == current {
            next = facts.randomElement()!
        }
        return next
    }
}
