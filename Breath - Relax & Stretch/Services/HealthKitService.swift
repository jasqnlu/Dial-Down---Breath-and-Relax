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

    /// True once the user has granted write access to workouts.
    var isWriteAuthorized: Bool {
        guard isAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// True once the user has granted write access to mindful sessions.
    var isMindfulWriteAuthorized: Bool {
        guard isAvailable,
              let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)
        else { return false }
        return store.authorizationStatus(for: mindfulType) == .sharingAuthorized
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy  = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession)        { types.insert(mindful) }
        return types
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Logging

    /// Logs a stretch/exercise session as a Flexibility workout.
    /// Estimates ~3.5 kcal/min (light flexibility work).
    /// No-op until the user has connected Apple Health in Settings; never
    /// triggers a permission prompt itself.
    func logStretchSession(startedAt: Date, completedAt: Date) async {
        guard isWriteAuthorized else { return }
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
    /// No-op until the user has connected Apple Health in Settings; never
    /// triggers a permission prompt itself.
    func logBreathingSession(startedAt: Date, completedAt: Date) async {
        guard isMindfulWriteAuthorized,
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

    // MARK: - Reading

    /// Total asleep time over the last 24h, summed across all sleep stages.
    /// Returns nil if HealthKit is unavailable or no sleep data exists.
    func lastNightSleepHours() async -> Double? {
        guard isAvailable,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else { return nil }

        let cal = Calendar.current
        let now = Date()
        guard let windowStart = cal.date(byAdding: .hour, value: -24, to: now) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: now, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType, predicate: predicate,
                limit: HKObjectQueryNoLimit, sortDescriptors: nil
            ) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]
                let totalSeconds = categorySamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            store.execute(query)
        }
    }
}
