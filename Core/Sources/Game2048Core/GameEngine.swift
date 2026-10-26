import Foundation

public enum Direction: Int, CaseIterable {
    case up = 0
    case right = 1
    case down = 2
    case left = 3
}

public protocol GameEngineDelegate: AnyObject {
    func gameEngine(_ engine: GameEngine, didMerge value: Int)
    func gameEngine(_ engine: GameEngine, didReach value: Int)
    func gameEngine(_ engine: GameEngine, didUpdateHighScore value: Int)
    func gameEngineDidEnd(_ engine: GameEngine)
}

public struct GameSnapshot: Codable, Equatable {
    public var board: [[Int]]
    public var score: Int
    public var maxMerged: Int
    public var highScore: Int
    public var won: Bool
    public var lose: Bool

    public init(board: [[Int]], score: Int, maxMerged: Int, highScore: Int, won: Bool, lose: Bool) {
        self.board = board
        self.score = score
        self.maxMerged = maxMerged
        self.highScore = highScore
        self.won = won
        self.lose = lose
    }
}

public final class GameEngine {
    public static let sizeX = 4
    public static let sizeY = 4
    public static let startTiles = 2
    public static let moveAnimationTime: TimeInterval = 0.1
    public static let spawnAnimationTime: TimeInterval = 0.1

    public private(set) var grid: Grid
    public private(set) var animationGrid: AnimationGrid
    public private(set) var score = 0
    public private(set) var highScore: Int
    public private(set) var maxMerged = 0
    public private(set) var won = false
    public private(set) var lose = false
    public var shown = false
    public weak var delegate: GameEngineDelegate?

    private var displayedWon = false
    private var random: any RandomSource

    public init(highScore: Int = 0, random: any RandomSource = SystemRandomSource()) {
        self.highScore = highScore
        self.random = random
        self.grid = Grid(sizeX: Self.sizeX, sizeY: Self.sizeY)
        self.animationGrid = AnimationGrid(sizeX: Self.sizeX, sizeY: Self.sizeY)
        newGame()
    }

    public func newGame() {
        grid = Grid(sizeX: Self.sizeX, sizeY: Self.sizeY)
        animationGrid = AnimationGrid(sizeX: Self.sizeX, sizeY: Self.sizeY)
        if score >= highScore {
            highScore = score
            delegate?.gameEngine(self, didUpdateHighScore: highScore)
        }
        score = 0
        won = false
        lose = false
        maxMerged = 0
        addStartTiles()
        shown = false
    }

    public var movesAvailable: Bool {
        grid.isCellsAvailable || tileMatchesAvailable()
    }

    @discardableResult
    public func move(_ direction: Direction) -> Bool {
        animationGrid.cancelAnimations()
        guard !lose else { return false }

        let vector = Self.vector(for: direction)
        let traversalsX = Self.buildTraversalsX(vector: vector)
        let traversalsY = Self.buildTraversalsY(vector: vector)
        var moved = false

        prepareTiles()

        for xx in traversalsX {
            for yy in traversalsY {
                let cell = Cell(xx, yy)
                guard let tile = grid.cellContent(cell) else { continue }

                let positions = findFarthestPosition(from: cell, vector: vector)
                let next = grid.cellContent(positions.next)

                if let next, next.value == tile.value, next.mergedFrom == nil {
                    let merged = Tile(cell: positions.next, value: tile.value * 2)
                    merged.mergedFrom = [tile, next]
                    grid.insertTile(merged)
                    grid.removeTile(tile)
                    tile.updatePosition(positions.next)

                    animationGrid.startAnimation(
                        x: merged.x, y: merged.y, type: .move,
                        duration: Self.moveAnimationTime, delay: 0, extras: [xx, yy]
                    )
                    animationGrid.startAnimation(
                        x: merged.x, y: merged.y, type: .merge,
                        duration: Self.spawnAnimationTime, delay: Self.moveAnimationTime
                    )

                    score += merged.value
                    if score > highScore {
                        highScore = score
                        delegate?.gameEngine(self, didUpdateHighScore: highScore)
                    }
                    delegate?.gameEngine(self, didMerge: merged.value)

                    if merged.value > maxMerged {
                        maxMerged = merged.value
                    }
                    if merged.value == 1024 {
                        delegate?.gameEngine(self, didReach: 1024)
                    }
                    if merged.value == 2048, !displayedWon {
                        delegate?.gameEngine(self, didReach: 2048)
                        displayedWon = true
                    }
                    if merged.value == 4096 {
                        delegate?.gameEngine(self, didReach: 4096)
                    }
                } else {
                    moveTile(tile, to: positions.farthest)
                    animationGrid.startAnimation(
                        x: positions.farthest.x, y: positions.farthest.y, type: .move,
                        duration: Self.moveAnimationTime, delay: 0, extras: [xx, yy, 0]
                    )
                }

                if cell != tile.cell {
                    moved = true
                }
            }
        }

        if moved {
            addRandomTile()
            if !movesAvailable {
                lose = true
                endGame()
            }
        }
        return moved
    }

    public func snapshot() -> GameSnapshot {
        var board = Array(repeating: Array(repeating: 0, count: grid.sizeY), count: grid.sizeX)
        for x in 0..<grid.sizeX {
            for y in 0..<grid.sizeY {
                board[x][y] = grid.field[x][y]?.value ?? 0
            }
        }
        return GameSnapshot(
            board: board, score: score, maxMerged: maxMerged,
            highScore: highScore, won: won, lose: lose
        )
    }

    public func restore(_ snapshot: GameSnapshot) {
        let sizeX = snapshot.board.count
        let sizeY = snapshot.board.first?.count ?? Self.sizeY
        grid = Grid(sizeX: sizeX, sizeY: sizeY)
        for x in 0..<sizeX {
            for y in 0..<sizeY {
                let value = snapshot.board[x][y]
                if value != 0 {
                    grid.insertTile(Tile(x: x, y: y, value: value))
                }
            }
        }
        animationGrid = AnimationGrid(sizeX: sizeX, sizeY: sizeY)
        score = snapshot.score
        maxMerged = snapshot.maxMerged
        highScore = snapshot.highScore
        won = snapshot.won
        lose = snapshot.lose
        shown = false
    }

    func addStartTiles() {
        for _ in 0..<Self.startTiles {
            addRandomTile()
        }
    }

    func addRandomTile() {
        guard grid.isCellsAvailable else { return }
        let value = random.nextDouble() < 0.9 ? 2 : 4
        guard let cell = grid.randomAvailableCell(using: &random) else { return }
        let tile = Tile(cell: cell, value: value)
        grid.insertTile(tile)
        animationGrid.startAnimation(
            x: tile.x, y: tile.y, type: .spawn,
            duration: Self.spawnAnimationTime, delay: Self.moveAnimationTime
        )
    }

    private func prepareTiles() {
        for x in 0..<grid.sizeX {
            for y in 0..<grid.sizeY {
                grid.field[x][y]?.mergedFrom = nil
            }
        }
    }

    private func endGame() {
        if score >= highScore {
            highScore = score
            delegate?.gameEngine(self, didUpdateHighScore: highScore)
        }
        delegate?.gameEngineDidEnd(self)
    }

    private func moveTile(_ tile: Tile, to cell: Cell) {
        grid.field[tile.x][tile.y] = nil
        grid.field[cell.x][cell.y] = tile
        tile.updatePosition(cell)
    }

    private func findFarthestPosition(from cell: Cell, vector: Cell) -> (farthest: Cell, next: Cell) {
        var previous = cell
        var next = Cell(previous.x + vector.x, previous.y + vector.y)
        while grid.isCellWithinBounds(next), grid.isCellAvailable(next) {
            previous = next
            next = Cell(previous.x + vector.x, previous.y + vector.y)
        }
        return (previous, next)
    }

    private func tileMatchesAvailable() -> Bool {
        for x in 0..<grid.sizeX {
            for y in 0..<grid.sizeY {
                guard let tile = grid.cellContent(Cell(x, y)) else { continue }
                for direction in Direction.allCases {
                    let vector = Self.vector(for: direction)
                    let other = grid.cellContent(Cell(x + vector.x, y + vector.y))
                    if let other, other.value == tile.value {
                        return true
                    }
                }
            }
        }
        return false
    }

    private static func vector(for direction: Direction) -> Cell {
        switch direction {
        case .up: return Cell(0, -1)
        case .right: return Cell(1, 0)
        case .down: return Cell(0, 1)
        case .left: return Cell(-1, 0)
        }
    }

    private static func buildTraversalsX(vector: Cell) -> [Int] {
        let traversals = Array(0..<sizeX)
        return vector.x == 1 ? Array(traversals.reversed()) : traversals
    }

    private static func buildTraversalsY(vector: Cell) -> [Int] {
        let traversals = Array(0..<sizeY)
        return vector.y == 1 ? Array(traversals.reversed()) : traversals
    }
}
