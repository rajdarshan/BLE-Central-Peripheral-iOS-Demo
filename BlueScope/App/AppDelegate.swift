import UIKit

/// Minimal delegate whose only job is the Apple-documented pattern of
/// observing didFinishLaunchingWithOptions to diagnose a CoreBluetooth-
/// triggered cold relaunch. It does not construct or touch any CoreBluetooth
/// type itself — actual restoration is handled entirely by CentralManager's
/// willRestoreState delegate callback, which fires regardless of when the
/// CBCentralManager instance is created relative to this method.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }
}
