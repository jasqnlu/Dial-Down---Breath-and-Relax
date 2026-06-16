import HealthKit

// MARK: - HealthKitService
// Writes completed sessions to Apple Health.
// Google Health on iOS reads from Apple Health, so no extra code is needed for
// Google Health, Samsung Health, or any other app that syncs with Apple Health.

final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()
    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy  = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession)        { types.insert(mindful) }
        return types
    }

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            return true
        } catch {
            return false
        }
    }

    // MARK: - Logging

    /// Logs a stretch/exercise session as a Flexibility workout.
    /// Estimates ~3.5 kcal/min (light flexibility work).
    func logStretchSession(startedAt: Date, completedAt: Date) async {
        guard isAvailable else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .flexibility
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        do {
            try await builder.beginCollection(at: startedAt)

            if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let duration = completedAt.timeIntervalSince(startedAt)
                let kcal = max(1.0, (duration / 60.0) * 3.5)
                let energySample = HKQuantitySample(
                    type: energyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                    start: startedAt,
                    end: completedAt
                )
                try await builder.addSamples([energySample])
            }

            try await builder.endCollection(at: completedAt)
            try await builder.finishWorkout()
        } catch {
            #if DEBUG
            print("⚠️ HealthKit stretch log failed: \(error)")
            #endif
        }
    }

    /// Logs a breathing session as a Mindful Session (visible in Health → Mindfulness).
    func logBreathingSession(startedAt: Date, completedAt: Date) async {
        guard isAvailable,
              let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)
        else { return }
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startedAt,
            end: completedAt
        )
        do {
            try await store.save(sample)
        } catch {
            #if DEBUG
            print("⚠️ HealthKit breathing log failed: \(error)")
            #endif
        }
    }
}
