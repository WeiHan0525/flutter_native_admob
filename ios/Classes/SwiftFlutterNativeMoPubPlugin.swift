//
//  SwiftFlutterNativeMoPubPlugin.swift
//  flutter_native_admob
//
//  Created by Weihan on 2020/4/15.
//

import Flutter
import UIKit
import MoPubSDK
import PureLayout

let mopubViewType = "native_admob"
let mopubControllerManager = NativeMoPubControllerManager.shared

public class SwiftFlutterNativeMoPubPlugin: NSObject, FlutterPlugin {
    
    enum CallMethod: String {
        case initController
        case disposeController
    }
    
    let messenger: FlutterBinaryMessenger
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        
        let channel = FlutterMethodChannel(name: "flutter_native_admob", binaryMessenger: messenger)
        
        let instance = SwiftFlutterNativeMoPubPlugin(messenger: messenger)
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let viewFactory = MoPubPlatformViewFactory()
        registrar.register(viewFactory, withId: mopubViewType)
    }
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let callMethod = CallMethod(rawValue: call.method) else { return result(FlutterMethodNotImplemented) }
        let params = call.arguments as? [String: Any]
        
        switch callMethod {
        case .initController:
            if let controllerID = params?["controllerID"] as? String {
                mopubControllerManager.createController(forID: controllerID, binaryMessenger: messenger)
            }
            
        case .disposeController:
            if let controllerID = params?["controllerID"] as? String {
                mopubControllerManager.removeController(forID: controllerID)
            }
        }
        
        result(nil)
    }
}

class MoPubPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return MoPubPlatformView(frame, viewId: viewId, args: args)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class MoPubPlatformView: NSObject, FlutterPlatformView {
    
    private var controller: NativeMoPubController?

    private let nativeAdView: MopubNativeAdView
    private let adContainerView = UIView()
    private let params: [String: Any]
    private var options = NativeAdmobOptions()
    
    init(_ frame: CGRect, viewId: Int64, args: Any?) {
        guard let nibObjects = Bundle.main.loadNibNamed("MoPubNativeView", owner: nil, options: nil),
            let nAdView = nibObjects.first as? MopubNativeAdView else {
                fatalError("Could not load nib file for adView")
        }

        nativeAdView = nAdView
        params = args as? [String: Any] ?? [:]
        
        if let controllerID = params["controllerID"] as? String,
            let controller = mopubControllerManager.getController(forID: controllerID) {
            self.controller = controller
        }
        
        if let data = params["options"] as? [String: Any] {
            options = NativeAdmobOptions(data)
        }
        
        // Set native ad
        if let nativeAd = controller?.nativeAd {
            do {
                let adView = try nativeAd.retrieveAdView()
                adView.frame = nativeAdView.bounds
                if let v = adView.viewWithTag(1), let vLabel = v as? UILabel{
                    vLabel.textColor = options.headlineTextStyle.color
                }
                for v in adContainerView.subviews {
                    v.removeFromSuperview()
                }
                self.adContainerView.addSubview(adView)
                
                adView.translatesAutoresizingMaskIntoConstraints = false
                let constraints: [NSLayoutConstraint] = [
                    adView.topAnchor.constraint(equalTo: adContainerView.topAnchor),
                    adView.bottomAnchor.constraint(equalTo: adContainerView.bottomAnchor),
                    adView.leadingAnchor.constraint(equalTo: adContainerView.leadingAnchor),
                    adView.trailingAnchor.constraint(equalTo: adContainerView.trailingAnchor),
                ]
                NSLayoutConstraint.activate(constraints)
            } catch {
            }
        }
        
        super.init()
    }
    
    func view() -> UIView {
        return adContainerView
    }
}
