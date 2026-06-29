import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edge_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftEdgeDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    private func topmostViewController() -> UIViewController? {
        let keyWindow: UIWindow?
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            NSLog("[EdgeDetect] connectedScenes count: %d", scenes.count)
            keyWindow = scenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            keyWindow = UIApplication.shared.keyWindow
        }
        NSLog("[EdgeDetect] keyWindow: %@", keyWindow == nil ? "nil" : "found")
        var top = keyWindow?.rootViewController
        NSLog("[EdgeDetect] rootViewController: %@", top == nil ? "nil" : String(describing: type(of: top!)))
        while let presented = top?.presentedViewController {
            NSLog("[EdgeDetect] walking presentedViewController: %@", String(describing: type(of: presented)))
            top = presented
        }
        NSLog("[EdgeDetect] topmostViewController: %@", top == nil ? "nil" : String(describing: type(of: top!)))
        return top
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("[EdgeDetect] handle called: %@", call.method)
        let args = call.arguments as! Dictionary<String, Any>
        let saveTo = args["save_to"] as! String
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false

        guard let topVC = topmostViewController() else {
            NSLog("[EdgeDetect] ERROR: topmostViewController returned nil")
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find a view controller to present from", details: nil))
            return
        }

        NSLog("[EdgeDetect] presenting on: %@", String(describing: type(of: topVC)))
        if call.method == "edge_detect" {
            let destinationViewController = HomeViewController()
            destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
            destinationViewController._result = result
            topVC.present(destinationViewController, animated: true, completion: {
                NSLog("[EdgeDetect] HomeViewController presented successfully")
            })
        } else if call.method == "edge_detect_gallery" {
            // Present ScanPhotoViewController directly — it opens the photo library
            // picker in viewDidAppear itself, so HomeViewController is not needed.
            let scanPhotoVC = ScanPhotoViewController()
            scanPhotoVC._result = result
            scanPhotoVC.saveTo = saveTo
            if #available(iOS 13.0, *) {
                scanPhotoVC.isModalInPresentation = true
                scanPhotoVC.overrideUserInterfaceStyle = .dark
            }
            topVC.present(scanPhotoVC, animated: true)
        }
    }
}
