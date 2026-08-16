import Testing
@testable import BreathRelaxStretch

struct ExercisePickingSessionTests {
    private func makeExercise(name: String, duration: Int) -> Exercise {
        Exercise(
            name: name, type: .stretch, targetBodyParts: ["Lower Back"], durationSeconds: duration,
            difficulty: 1, instructions: [], cueStyle: .hold
        )
    }

    private func makeContext(base: [Exercise] = []) -> ExercisePickingSession.Context {
        .init(title: "Wake Up", isPinned: false, baseExercises: base)
    }

    @Test func startsInactiveWithNoPicks() {
        let session = ExercisePickingSession()
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
    }

    @Test func beginActivatesAndClearsAnyPriorPicks() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.begin(context: makeContext())
        #expect(session.isActive == true)
        #expect(session.picked.isEmpty)
    }

    @Test func toggleAddsThenRemoves() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        let exercise = makeExercise(name: "Shoulder Roll", duration: 30)
        session.toggle(exercise)
        #expect(session.isPicked(exercise) == true)
        #expect(session.picked.count == 1)
        session.toggle(exercise)
        #expect(session.isPicked(exercise) == false)
        #expect(session.picked.isEmpty)
    }

    @Test func pickedTotalSecondsSumsOnlyPickedExercises() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.toggle(makeExercise(name: "B", duration: 45))
        #expect(session.pickedTotalSeconds == 75)
    }

    @Test func finishMergesPicksIntoBaseAndDeactivates() {
        let session = ExercisePickingSession()
        let base = [makeExercise(name: "Base", duration: 60)]
        session.begin(context: makeContext(base: base))
        let pickedExercise = makeExercise(name: "New", duration: 30)
        session.toggle(pickedExercise)

        let result = session.finish()

        #expect(result != nil)
        #expect(result?.merged.count == 2)
        #expect(result?.merged.last?.name == "New")
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
    }

    @Test func finishSkipsDuplicatesAlreadyInBase() {
        let session = ExercisePickingSession()
        let shared = makeExercise(name: "Shared", duration: 30)
        session.begin(context: makeContext(base: [shared]))
        session.toggle(shared)

        let result = session.finish()

        #expect(result?.merged.count == 1)
    }

    @Test func finishWithNoActiveContextReturnsNil() {
        let session = ExercisePickingSession()
        #expect(session.finish() == nil)
    }

    @Test func consumeFinishedReturnsResultOnceThenNil() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        _ = session.finish()

        #expect(session.consumeFinished() != nil)
        #expect(session.consumeFinished() == nil)
    }

    @Test func cancelDeactivatesAndClearsPicksWithoutMerging() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        session.toggle(makeExercise(name: "A", duration: 30))
        session.cancel()
        #expect(session.isActive == false)
        #expect(session.picked.isEmpty)
        #expect(session.finish() == nil)
    }

    // MARK: - Standalone (no-context) picking, entered from the Exercises
    // tab's own "Select" button rather than Customize's "Add Exercises".

    @Test func standaloneBeginActivatesWithoutContext() {
        let session = ExercisePickingSession()
        session.begin()
        #expect(session.isActive == true)
        #expect(session.picked.isEmpty)
        #expect(session.hasContext == false)
    }

    @Test func contextualBeginReportsHasContext() {
        let session = ExercisePickingSession()
        session.begin(context: makeContext())
        #expect(session.hasContext == true)
    }

    @Test func standaloneBeginClearsAnyPriorPicks() {
        let session = ExercisePickingSession()
        session.begin()
        session.toggle(makeExercise(name: "A", duration: 30))
        session.begin()
        #expect(session.picked.isEmpty)
    }

    @Test func finishOnStandaloneSessionReturnsNil() {
        let session = ExercisePickingSession()
        session.begin()
        session.toggle(makeExercise(name: "A", duration: 30))
        #expect(session.finish() == nil)
        // finish() must not have a merge side effect on a contextless
        // session — picking mode stays active for the review screen to
        // read `picked` from.
        #expect(session.isActive == true)
        #expect(session.picked.count == 1)
    }
}
