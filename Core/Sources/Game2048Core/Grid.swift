public final class Grid {
    public internal(set) var field: [[Tile?]]
    public let sizeX: Int
    public let sizeY: Int

    public init(sizeX: Int = 4, sizeY: Int = 4) {
        self.sizeX = sizeX
        self.sizeY = sizeY
        field = Array(repeating: Array(repeating: Tile?.none, count: sizeY), count: sizeX)
    }

    func availableCells() -> [Cell] {
        var cells: [Cell] = []
        for x in 0..<sizeX {
            for y in 0..<sizeY where field[x][y] == nil {
                cells.append(Cell(x, y))
            }
        }
        return cells
    }

    var isCellsAvailable: Bool {
        !availableCells().isEmpty
    }

    func randomAvailableCell(using random: inout any RandomSource) -> Cell? {
        let available = availableCells()
        guard !available.isEmpty else { return nil }
        return available[random.nextInt(upperBound: available.count)]
    }

    func isCellAvailable(_ cell: Cell) -> Bool {
        !isCellOccupied(cell)
    }

    func isCellOccupied(_ cell: Cell) -> Bool {
        cellContent(cell) != nil
    }

    public func cellContent(_ cell: Cell) -> Tile? {
        guard isCellWithinBounds(cell) else { return nil }
        return field[cell.x][cell.y]
    }

    func isCellWithinBounds(_ cell: Cell) -> Bool {
        cell.x >= 0 && cell.x < sizeX && cell.y >= 0 && cell.y < sizeY
    }

    func insertTile(_ tile: Tile) {
        field[tile.x][tile.y] = tile
    }

    func removeTile(_ tile: Tile) {
        field[tile.x][tile.y] = nil
    }
}
