import XCTest

final class Game2048UITests: XCTestCase {
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func waitForBoard(_ app: XCUIApplication) -> XCUIElement {
        let board = app.otherElements["board"]
        XCTAssertTrue(board.waitForExistence(timeout: 15))
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        return board
    }

    private func boardValue(_ board: XCUIElement) -> String {
        board.value as? String ?? ""
    }

    private func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return condition()
    }

    private func drag(_ board: XCUIElement, from: CGVector, to: CGVector) {
        let start = board.coordinate(withNormalizedOffset: from)
        let end = board.coordinate(withNormalizedOffset: to)
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
    }

    private func dragUntil(_ board: XCUIElement, from: CGVector, to: CGVector, condition: () -> Bool) -> Bool {
        for _ in 0..<3 {
            drag(board, from: from, to: to)
            if waitUntil(timeout: 4, condition) {
                return true
            }
        }
        return condition()
    }

    private func nonZeroCount(_ value: String) -> Int {
        value
            .split(separator: ";")
            .flatMap { $0.split(separator: ",") }
            .filter { (Int($0) ?? 0) != 0 }
            .count
    }

    func testSwipeMovesTiles() {
        let app = launch(["-showGame", "-seedBoard"])
        let board = waitForBoard(app)
        let before = boardValue(board)

        let changed = dragUntil(
            board,
            from: CGVector(dx: 0.2, dy: 0.5),
            to: CGVector(dx: 0.8, dy: 0.5)
        ) { self.boardValue(board) != before }

        XCTAssertTrue(changed, "board did not change after swipe")
    }

    func testMergeUpdatesScore() {
        let app = launch(["-showGame", "-seedMerge"])
        let board = waitForBoard(app)
        let score = app.staticTexts["scoreLabel"]
        XCTAssertTrue(score.waitForExistence(timeout: 10))

        let merged = dragUntil(
            board,
            from: CGVector(dx: 0.8, dy: 0.5),
            to: CGVector(dx: 0.2, dy: 0.5)
        ) { score.label == "4" }

        XCTAssertTrue(merged, "score did not become 4, got \(score.label)")
    }

    func testNewGameResetsBoard() {
        let app = launch(["-showGame", "-seedBoard"])
        _ = waitForBoard(app)

        app.buttons["newGameButton"].tap()
        let confirm = app.buttons["confirmNewGame"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()

        let board = waitForBoard(app)
        XCTAssertTrue(
            waitUntil { self.nonZeroCount(self.boardValue(board)) == 2 },
            "new board has \(nonZeroCount(boardValue(board))) tiles"
        )
    }

    func testBoardPersistsAcrossRelaunch() {
        let app = launch(["-showGame", "-seedBoard"])
        let board = waitForBoard(app)
        let before = boardValue(board)

        let changed = dragUntil(
            board,
            from: CGVector(dx: 0.2, dy: 0.5),
            to: CGVector(dx: 0.8, dy: 0.5)
        ) { self.boardValue(board) != before }
        XCTAssertTrue(changed)
        let moved = boardValue(board)

        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        app.terminate()
        app.launchArguments = ["-showGame"]
        app.launch()

        let relaunched = waitForBoard(app)
        XCTAssertTrue(waitUntil { self.boardValue(relaunched) == moved }, "board state was not restored")
    }
}
