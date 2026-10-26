import Foundation
import Game2048Core

struct GameStore {
    private let defaults = UserDefaults.standard

    var highScore: Int {
        get { defaults.integer(forKey: "high score") }
        nonmutating set { defaults.set(newValue, forKey: "high score") }
    }

    var soundVolume: Double {
        get { defaults.object(forKey: "vol") == nil ? 1 : defaults.double(forKey: "vol") }
        nonmutating set { defaults.set(newValue, forKey: "vol") }
    }

    var sensitivity: Double {
        get { defaults.object(forKey: "pref_sensitivity") == nil ? 0.7 : defaults.double(forKey: "pref_sensitivity") }
    }

    var snapshot: GameSnapshot? {
        get {
            guard let data = defaults.data(forKey: "game snapshot") else { return nil }
            return try? JSONDecoder().decode(GameSnapshot.self, from: data)
        }
        nonmutating set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "game snapshot")
            } else {
                defaults.removeObject(forKey: "game snapshot")
            }
        }
    }
}
