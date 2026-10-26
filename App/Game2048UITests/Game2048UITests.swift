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

        app.swipeRight()

        XCTAssertTrue(waitUntil { boardValue(board) != before }, "board did not change after swipe")
    }

    func testMergeUpdatesScore() {
        let app = launch(["-showGame", "-seedMerge"])
        _ = waitForBoard(app)
        let score = app.staticTexts["scoreLabel"]
        XCTAssertTrue(score.waitForExistence(timeout: 10))

        app.swipeLeft()

        XCTAssertTrue(waitUntil { score.label == "4" }, "score did not become 4, got \(score.label)")
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
            waitUntil { nonZeroCount(boardValue(board)) == 2 },
            "new board has \(nonZeroCount(boardValue(board))) tiles"
        )
    }

    func testBoardPersistsAcrossRelaunch() {
        let app = launch(["-showGame", "-seedBoard"])
        let board = waitForBoard(app)
        let before = boardValue(board)

        app.swipeRight()
        XCTAssertTrue(waitUntil { boardValue(board) != before })
        let moved = boardValue(board)

        app.terminate()
        app.launchArguments = ["-showGame"]
        app.launch()

        let relaunched = waitForBoard(app)
        XCTAssertTrue(waitUntil { boardValue(relaunched) == moved }, "board state was not restored")
    }
}
