public protocol RandomSource {
    mutating func nextDouble() -> Double
    mutating func nextInt(upperBound: Int) -> Int
}

public struct SystemRandomSource: RandomSource {
    public init() {}

    public mutating func nextDouble() -> Double {
        Double.random(in: 0..<1)
    }

    public mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        return Int.random(in: 0..<upperBound)
    }
}
