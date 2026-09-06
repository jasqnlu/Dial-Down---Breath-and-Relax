import Testing
import Foundation
import CoreGraphics
@testable import BreathRelaxStretch

// AnimationCallout is the authored "flash an arrow + instruction" overlay for
// exercises whose generated 3D animation is a known approximation (see
// docs/superpowers/specs/2026-09-06-exercise-animation-instruction-callouts-design.md).
// These tests cover the pure, view/player-independent pieces: the time->opacity
// envelope, JSON decode, and Exercise's resolution-order logic — all runnable
// without an AVPlayer or a rendered view.
struct AnimationCalloutTests {

    private func makeCallout(startTime: Double = 1.0, duration: Double = 2.0) -> AnimationCallout {
        AnimationCallout(
            text: "Rotate your wrists in a circle",
            shape: .rotate,
            anchor: CGPoint(x: 0.15, y: 0.32),
            angle: 0,
            startTime: startTime,
            duration: duration
        )
    }

    // MARK: - opacity(atLoopTime:) envelope

    @Test func opacityIsZeroBeforeFadeIn() {
        let c = makeCallout(startTime: 1.0, duration: 2.0)
        #expect(c.opacity(atLoopTime: 0.0) == 0)
        #expect(c.opacity(atLoopTime: 0.99) == 0)
    }

    @Test func opacityRampsDuringFadeIn() {
        let c = makeCallout(startTime: 1.0, duration: 2.0)
        // Halfway through the 0.3s fade-in (starts at startTime == 1.0).
        let opacity = c.opacity(atLoopTime: 1.15)
        #expect(abs(opacity - 0.5) < 0.001)
    }

    @Test func opacityHoldsAtOneBetweenFades() {
        let c = makeCallout(startTime: 1.0, duration: 2.0)
        // Midpoint of the hold: startTime + duration/2 == 2.0.
        #expect(c.opacity(atLoopTime: 2.0) == 1)
    }

    @Test func opacityRampsDuringFadeOut() {
        let c = makeCallout(startTime: 1.0, duration: 2.0)
        // end = startTime + duration = 3.0; halfway through the 0.3s fade-out.
        let opacity = c.opacity(atLoopTime: 2.85)
        #expect(abs(opacity - 0.5) < 0.001)
    }

    @Test func opacityIsZeroAfterFadeOut() {
        let c = makeCallout(startTime: 1.0, duration: 2.0)
        #expect(c.opacity(atLoopTime: 3.0) == 0)
        #expect(c.opacity(atLoopTime: 3.5) == 0)
    }

    @Test func opacityFadesOutCorrectlyEvenPastTheAuthoredClipLength() {
        // opacity(atLoopTime:) is a pure function of (startTime, duration) —
        // it has no notion of the video's 4s clip length. If a callout's
        // window (startTime + duration) is ever authored to run past the
        // clip's end, the player's own loop-restart (seek to .zero) would
        // cut the fade off before this function ever reaches its fade-out
        // branch — a authoring mistake, not a bug in this function. This
        // test pins down that the math itself still behaves correctly for
        // a window like that, so a future change to the fade math can't
        // silently break the "still fades out gracefully if given the
        // chance" guarantee, even though no shipped callout hits this case
        // today (see SeedData.json's authored samples, all ending <= 3.5s).
        let c = makeCallout(startTime: 3.0, duration: 2.0) // end = 5.0, past a 4s clip
        #expect(c.opacity(atLoopTime: 3.0) == 0)
        #expect(c.opacity(atLoopTime: 3.15) > 0 && c.opacity(atLoopTime: 3.15) < 1)
        #expect(c.opacity(atLoopTime: 4.0) == 1) // holding, well past the clip's own 4s length
        #expect(c.opacity(atLoopTime: 4.85) > 0 && c.opacity(atLoopTime: 4.85) < 1)
        #expect(c.opacity(atLoopTime: 5.0) == 0)
    }

    @Test func opacityHandlesShortDurationWithoutOvershoot() {
        // A callout shorter than 2x the fade duration should never exceed 1
        // or go negative — fade-in/out portions get clamped to duration/2.
        let c = makeCallout(startTime: 0.0, duration: 0.2)
        for t in stride(from: 0.0, through: 0.2, by: 0.02) {
            let opacity = c.opacity(atLoopTime: t)
            #expect(opacity >= 0 && opacity <= 1)
        }
    }

    // MARK: - JSON decode

    @Test func decodesFullPayload() throws {
        // CGPoint's native Codable conformance encodes/decodes as a
        // two-element array [x, y], not a keyed {"x":...,"y":...} object —
        // SeedData.json authors `anchor` the same way.
        let json = """
        {
            "text": "Rotate your wrists in a circle",
            "shape": "rotate",
            "anchor": [0.15, 0.32],
            "angle": 0,
            "startTime": 1.0,
            "duration": 2.0
        }
        """.data(using: .utf8)!
        let callout = try JSONDecoder().decode(AnimationCallout.self, from: json)
        #expect(callout.text == "Rotate your wrists in a circle")
        #expect(callout.shape == .rotate)
        #expect(callout.anchor == CGPoint(x: 0.15, y: 0.32))
        #expect(callout.startTime == 1.0)
        #expect(callout.duration == 2.0)
    }

    @Test func decodeDefaultsDurationWhenMissing() throws {
        let json = """
        {
            "text": "Press your hips up and back",
            "shape": "pushPull",
            "anchor": [0.52, 0.40],
            "angle": 60,
            "startTime": 1.5
        }
        """.data(using: .utf8)!
        let callout = try JSONDecoder().decode(AnimationCallout.self, from: json)
        #expect(callout.duration == 2.0)
    }

    @Test func allFourShapesDecodeFromRawValue() throws {
        for raw in ["rotate", "swingArc", "pushPull", "pulse"] {
            let shape = AnimationCallout.Shape(rawValue: raw)
            #expect(shape != nil)
        }
    }

    // MARK: - Parsing from a raw SeedData.json exercise dictionary

    @Test func parseFromRawExerciseReturnsCalloutWhenPresent() {
        let raw: [String: Any] = [
            "animationIsApproximate": true,
            "animationCallout": [
                "text": "Rotate your ankle in a circle",
                "shape": "rotate",
                "anchor": [0.3, 0.9],
                "angle": 0,
                "startTime": 1.0,
                "duration": 2.0,
            ],
        ]
        let callout = AnimationCallout.parse(fromRawExercise: raw)
        #expect(callout?.text == "Rotate your ankle in a circle")
        #expect(callout?.shape == .rotate)
    }

    @Test func parseFromRawExerciseReturnsNilWhenBoolOnly() {
        let raw: [String: Any] = ["animationIsApproximate": true]
        #expect(AnimationCallout.parse(fromRawExercise: raw) == nil)
    }

    @Test func parseFromRawExerciseReturnsNilWhenNeither() {
        let raw: [String: Any] = ["name": "Some Exercise"]
        #expect(AnimationCallout.parse(fromRawExercise: raw) == nil)
    }

    // MARK: - Exercise storage round-trip (mirrors posesData/breathPatternData)

    @Test func exerciseRoundTripsAnimationCallout() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(e.animationCallout == nil)
        let callout = makeCallout()
        e.animationCallout = callout
        #expect(e.animationCallout == callout)
        e.animationCallout = nil
        #expect(e.animationCallout == nil)
    }

    // MARK: - Resolution order (callout > bool disclaimer > nothing)

    @Test func showsApproximateNoteWhenNoCalloutButFlagged() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationIsApproximate = true
        #expect(e.showsApproximateAnimationNote)
    }

    @Test func hidesApproximateNoteWhenCalloutPresent() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        e.animationIsApproximate = true
        e.animationCallout = makeCallout()
        // The overlay replaces the generic disclaimer — no double messaging.
        #expect(!e.showsApproximateAnimationNote)
    }

    @Test func showsNeitherWhenNotApproximateAndNoCallout() {
        let e = Exercise(name: "X", type: .stretch, targetBodyParts: [],
                         durationSeconds: 30, difficulty: 1, instructions: [])
        #expect(!e.showsApproximateAnimationNote)
        #expect(e.animationCallout == nil)
    }
}
