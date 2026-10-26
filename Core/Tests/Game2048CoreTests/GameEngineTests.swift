import XCTest
@testable import Game2048Core

final class GameEngineTests: XCTestCase {
    private struct FixedRandom: RandomSource {
        var value: Double
        var index: Int

        mutating func nextDouble() -> Double { value }
        mutating func nextInt(upperBound: Int) -> Int { index }
    }

    private final class SpyDelegate: GameEngineDelegate {
        var merged: [Int] = []
        var reached: [Int] = []
        var highScores: [Int] = []
        var ended = 0

        func gameEngine(_ engine: GameEngine, didMerge value: Int) {
            merged.append(value)
        }

        func gameEngine(_ engine: GameEngine, didReach value: Int) {
            reached.append(value)
        }

        func gameEngine(_ engine: GameEngine, didUpdateHighScore value: Int) {
            highScores.append(value)
        }

        func gameEngineDidEnd(_ engine: GameEngine) {
            ended += 1
        }
    }

    private func makeField(from rows: [[Int]]) -> [[Int]] {
        let height = rows.count
        let width = rows[0].count
        return (0..<width).map { x in
            (0..<height).map { y in rows[y][x] }
        }
    }

    private func makeEngine(rows: [[Int]], spawnValue: Double = 0, spawnIndex: Int = 0) -> GameEngine {
        let engine = GameEngine(highScore: 0, random: FixedRandom(value: spawnValue, index: spawnIndex))
        engine.restore(
            GameSnapshot(
                board: makeField(from: rows),
                score: 0, maxMerged: 0, highScore: 0, won: false, lose: false
            )
        )
        return engine
    }

    private func rows(of engine: GameEngine) -> [[Int]] {
        (0..<engine.grid.sizeY).map { y in
            (0..<engine.grid.sizeX).map { x in engine.grid.field[x][y]?.value ?? 0 }
        }
    }

    private func values(of engine: GameEngine) -> [Int] {
        engine.grid.field.flatMap { $0 }.compactMap { $0?.value }
    }

    func testNewGameStartsWithTwoTiles() {
        let engine = GameEngine(highScore: 0, random: FixedRandom(value: 0, index: 0))
        XCTAssertEqual(values(of: engine), [2, 2])
    }

    func testMoveRightMergesPair() {
        let engine = makeEngine(rows: [
            [2, 2, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        XCTAssertTrue(engine.move(.right))
        XCTAssertEqual(rows(of: engine)[0], [2, 0, 0, 4])
        XCTAssertEqual(engine.score, 4)
        XCTAssertEqual(engine.highScore, 4)
    }

    func testFourTwosMergeIntoTwoFours() {
        let engine = makeEngine(rows: [
            [2, 2, 2, 2],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        engine.move(.right)
        XCTAssertEqual(rows(of: engine)[0], [2, 0, 4, 4])
        XCTAssertEqual(engine.score, 8)
    }

    func testMergedTileDoesNotMergeAgainInSameMove() {
        let engine = makeEngine(rows: [
            [2, 2, 4, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        engine.move(.right)
        XCTAssertEqual(rows(of: engine)[0], [2, 0, 4, 4])
        XCTAssertEqual(engine.score, 4)
    }

    func testMoveLeft() {
        let engine = makeEngine(rows: [
            [0, 0, 2, 2],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        engine.move(.left)
        XCTAssertEqual(rows(of: engine)[0], [4, 2, 0, 0])
        XCTAssertEqual(engine.score, 4)
    }

    func testMoveUp() {
        let engine = makeEngine(rows: [
            [0, 0, 0, 0],
            [2, 0, 0, 0],
            [2, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        engine.move(.up)
        let board = rows(of: engine)
        XCTAssertEqual(board[0][0], 4)
        XCTAssertEqual(board[1][0], 2)
        XCTAssertEqual(engine.score, 4)
    }

    func testMoveDown() {
        let engine = makeEngine(rows: [
            [2, 0, 0, 0],
            [2, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        engine.move(.down)
        let board = rows(of: engine)
        XCTAssertEqual(board[0][0], 2)
        XCTAssertEqual(board[3][0], 4)
        XCTAssertEqual(engine.score, 4)
    }

    func testSpawnValueUsesNinetyPercentThreshold() {
        let empty = Array(repeating: Array(repeating: 0, count: 4), count: 4)

        let twos = makeEngine(rows: empty, spawnValue: 0.899)
        twos.addRandomTile()
        XCTAssertEqual(values(of: twos), [2])

        let fours = makeEngine(rows: empty, spawnValue: 0.9)
        fours.addRandomTile()
        XCTAssertEqual(values(of: fours), [4])
    }

    func testNoMovesOnFullBoardWithoutMatches() {
        let engine = makeEngine(rows: [
            [2, 4, 2, 4],
            [4, 2, 4, 2],
            [2, 4, 2, 4],
            [4, 2, 4, 2],
        ])
        XCTAssertFalse(engine.movesAvailable)
    }

    func testMovesAvailableWithAdjacentMatch() {
        let engine = makeEngine(rows: [
            [2, 4, 2, 4],
            [4, 2, 4, 2],
            [2, 4, 2, 4],
            [4, 4, 2, 4],
        ])
        XCTAssertTrue(engine.movesAvailable)
    }

    func testGameOverWhenMoveFillsBoard() {
        let engine = makeEngine(rows: [
            [2, 4, 2, 4],
            [4, 2, 4, 2],
            [2, 4, 2, 4],
            [4, 2, 0, 4],
        ])
        let spy = SpyDelegate()
        engine.delegate = spy

        XCTAssertTrue(engine.move(.left))
        XCTAssertTrue(engine.lose)
        XCTAssertEqual(spy.ended, 1)
    }

    func testAnimationTimingAndOneExtraFrame() {
        let grid = AnimationGrid(sizeX: 4, sizeY: 4)
        grid.startAnimation(x: 0, y: 0, type: .spawn, duration: 0.1, delay: 0.1)
        let animation = grid.animations(at: 0, 0)[0]

        XCTAssertFalse(animation.isActive)
        XCTAssertEqual(animation.percentageDone, 0, accuracy: 1e-9)

        grid.tickAll(0.05)
        XCTAssertFalse(animation.isActive)

        grid.tickAll(0.05)
        XCTAssertTrue(animation.isActive)
        XCTAssertEqual(animation.percentageDone, 0, accuracy: 1e-9)

        grid.tickAll(0.05)
        XCTAssertEqual(animation.percentageDone, 0.5, accuracy: 1e-9)
        XCTAssertTrue(grid.isAnimationActive)

        grid.tickAll(0.051)
        XCTAssertTrue(grid.animations(at: 0, 0).isEmpty)
        XCTAssertTrue(grid.isAnimationActive)
        XCTAssertFalse(grid.isAnimationActive)
    }

    func testMilestoneCallbacks() {
        let engine = makeEngine(rows: [
            [512, 512, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        let spy = SpyDelegate()
        engine.delegate = spy
        engine.move(.left)
        XCTAssertEqual(spy.reached, [1024])

        engine.restore(
            GameSnapshot(
                board: makeField(from: [
                    [2048, 2048, 0, 0],
                    [0, 0, 0, 0],
                    [0, 0, 0, 0],
                    [0, 0, 0, 0],
                ]),
                score: 0, maxMerged: 0, highScore: 0, won: false, lose: false
            )
        )
        engine.move(.left)
        XCTAssertEqual(spy.reached, [1024, 4096])
    }

    func testWinNotificationOnlyOncePerSession() {
        let board = [
            [1024, 1024, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ]
        let engine = makeEngine(rows: board)
        let spy = SpyDelegate()
        engine.delegate = spy

        engine.move(.left)
        XCTAssertEqual(spy.reached, [2048])

        engine.newGame()
        engine.restore(
            GameSnapshot(
                board: makeField(from: board),
                score: 0, maxMerged: 0, highScore: 0, won: false, lose: false
            )
        )
        engine.move(.left)
        XCTAssertEqual(spy.reached, [2048])
    }

    func testHighScoreNotification() {
        let engine = makeEngine(rows: [
            [2, 2, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        let spy = SpyDelegate()
        engine.delegate = spy

        engine.move(.left)
        XCTAssertEqual(engine.highScore, 4)
        XCTAssertEqual(spy.highScores.last, 4)
    }

    func testSnapshotRoundTrip() {
        let original = GameSnapshot(
            board: makeField(from: [
                [2, 4, 0, 0],
                [0, 8, 0, 0],
                [0, 0, 16, 0],
                [0, 0, 0, 32],
            ]),
            score: 100, maxMerged: 16, highScore: 200, won: false, lose: false
        )
        let engine = GameEngine(highScore: 0, random: FixedRandom(value: 0, index: 0))
        engine.restore(original)
        XCTAssertEqual(engine.snapshot(), original)
    }
}
