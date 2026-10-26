public final class Tile {
    public let value: Int
    public var x: Int
    public var y: Int
    public var mergedFrom: [Tile]?

    public init(x: Int, y: Int, value: Int) {
        self.x = x
        self.y = y
        self.value = value
    }

    public convenience init(cell: Cell, value: Int) {
        self.init(x: cell.x, y: cell.y, value: value)
    }

    public var cell: Cell {
        Cell(x, y)
    }

    public func updatePosition(_ cell: Cell) {
        x = cell.x
        y = cell.y
    }
}
