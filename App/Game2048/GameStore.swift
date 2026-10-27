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
        nonmutating set { defaults.set(newValue, forKey: "pref_sensitivity") }
    }

    var theme: Theme {
        get { Theme.current }
        nonmutating set { defaults.set(newValue.rawValue, forKey: "pref_theme") }
    }

    var themeQuickSwitch: Bool {
        get { defaults.bool(forKey: "pref_themebutton") }
        nonmutating set { defaults.set(newValue, forKey: "pref_themebutton") }
    }

    var respectSilentMode: Bool {
        get {
            defaults.object(forKey: "pref_respect_silent") == nil
                ? true
                : defaults.bool(forKey: "pref_respect_silent")
        }
        nonmutating set { defaults.set(newValue, forKey: "pref_respect_silent") }
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
