import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-showGame") {
            window.rootViewController = GameViewController()
        } else if arguments.contains("-showTutorial") {
            window.rootViewController = TutorialViewController()
        } else if arguments.contains("-showSettings") {
            window.rootViewController = UINavigationController(rootViewController: SettingsViewController())
        } else if arguments.contains("-showAbout") {
            window.rootViewController = UINavigationController(rootViewController: AboutViewController())
        } else {
            window.rootViewController = StartViewController()
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
