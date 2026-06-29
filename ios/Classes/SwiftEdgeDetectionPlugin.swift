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
            keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            keyWindow = UIApplication.shared.keyWindow
        }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        let saveTo = args["save_to"] as! String
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false

        guard let topVC = topmostViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find a view controller to present from", details: nil))
            return
        }

        if call.method == "edge_detect" {
            let destinationViewController = HomeViewController()
            destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
            destinationViewController._result = result
            topVC.present(destinationViewController, animated: true, completion: nil)
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
