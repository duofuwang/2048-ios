import XCTest
@testable import Game2048Core

final class HapticPolicyTests: XCTestCase {
    private func makePolicy(
        enabled: Bool = true,
        intensity: HapticIntensity = .light,
        trigger: HapticTrigger = .perMove,
        seen: Set<Int> = []
    ) -> HapticPolicy {
        HapticPolicy(isEnabled: enabled, intensity: intensity, trigger: trigger, seenValues: seen)
    }

    func testDisabledRecordsSeenValuesButReturnsNoEvents() {
        let policy = makePolicy(enabled: false)
        policy.beginMove()
        policy.mergeDidOccur(value: 4)

        XCTAssertEqual(policy.endMove(), [])
        XCTAssertEqual(policy.seenValues, [4])
    }

    func testPerMoveEmitsOnlyFirstMergePerMove() {
        let policy = makePolicy(trigger: .perMove)
        policy.beginMove()
        policy.mergeDidOccur(value: 2)
        policy.mergeDidOccur(value: 4)
        policy.mergeDidOccur(value: 8)

        let firstMove = policy.endMove()
        XCTAssertEqual(firstMove.count, 1)
        XCTAssertEqual(firstMove[0].delay, 0, accuracy: 1e-9)
        XCTAssertEqual(policy.seenValues, [2, 4, 8])

        policy.beginMove()
        policy.mergeDidOccur(value: 16)
        let secondMove = policy.endMove()
        XCTAssertEqual(secondMove.count, 1)
        XCTAssertEqual(secondMove[0].delay, 0, accuracy: 1e-9)
    }

    func testPerMergeSpacesEventsAndStopsAtWindow() {
        let policy = makePolicy(intensity: .strong, trigger: .perMerge)
        policy.beginMove()
        for power in 1...8 {
            policy.mergeDidOccur(value: 1 << power)
        }

        let events = policy.endMove()
        XCTAssertEqual(events.count, 4)
        for (index, event) in events.enumerated() {
            XCTAssertEqual(event.delay, Double(index) * 0.06, accuracy: 1e-9)
        }
        XCTAssertTrue(events.allSatisfy { $0.intensity == .strong })
    }

    func testPerMergeWithTwoMergesEmitsTwoEvents() {
        let policy = makePolicy(trigger: .perMerge)
        policy.beginMove()
        policy.mergeDidOccur(value: 2)
        policy.mergeDidOccur(value: 4)

        let events = policy.endMove()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].delay, 0, accuracy: 1e-9)
        XCTAssertEqual(events[1].delay, 0.06, accuracy: 1e-9)
    }

    func testOnNewValueEmitsOnlyFirstOccurrencePerGame() {
        let policy = makePolicy(trigger: .onNewValue)

        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        XCTAssertEqual(policy.endMove().count, 1)

        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        XCTAssertEqual(policy.endMove().count, 0)

        policy.beginMove()
        policy.mergeDidOccur(value: 8)
        XCTAssertEqual(policy.endMove().count, 1)
    }

    func testOnNewValueEmitsOnceForDuplicateValueInSameMove() {
        let policy = makePolicy(trigger: .onNewValue)
        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        policy.mergeDidOccur(value: 4)

        XCTAssertEqual(policy.endMove().count, 1)
    }

    func testSeenValuesRecordedRegardlessOfTrigger() {
        let policy = makePolicy(trigger: .perMove)
        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        _ = policy.endMove()

        policy.trigger = .onNewValue
        policy.beginMove()
        policy.mergeDidOccur(value: 4)

        XCTAssertEqual(policy.endMove().count, 0)
        XCTAssertEqual(policy.seenValues, [4])
    }

    func testMoveWithoutMergesProducesNoEvents() {
        let policy = makePolicy(trigger: .perMerge)
        policy.beginMove()
        XCTAssertEqual(policy.endMove(), [])
    }

    func testResetGameClearsSeenValues() {
        let policy = makePolicy(trigger: .onNewValue)
        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        _ = policy.endMove()

        policy.resetGame()
        policy.beginMove()
        policy.mergeDidOccur(value: 4)

        XCTAssertEqual(policy.endMove().count, 1)
        XCTAssertEqual(policy.seenValues, [4])
    }

    func testRestoreSeenValuesSuppressesOldValues() {
        let policy = makePolicy(trigger: .onNewValue, seen: [4])
        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        XCTAssertEqual(policy.endMove().count, 0)

        policy.beginMove()
        policy.mergeDidOccur(value: 8)
        XCTAssertEqual(policy.endMove().count, 1)
    }

    func testNewMoveDiscardsPreviousCandidates() {
        let policy = makePolicy(trigger: .perMerge)
        policy.beginMove()
        policy.mergeDidOccur(value: 4)
        _ = policy.endMove()

        policy.beginMove()
        XCTAssertEqual(policy.endMove(), [])
    }

    func testIntensityMatchesSetting() {
        let policy = makePolicy(intensity: .medium, trigger: .perMove)
        policy.beginMove()
        policy.mergeDidOccur(value: 2)

        let events = policy.endMove()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].intensity, .medium)
    }
}
