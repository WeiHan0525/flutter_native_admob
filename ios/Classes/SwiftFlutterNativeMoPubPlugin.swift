//
//  SwiftFlutterNativeMoPubPlugin.swift
//  flutter_native_admob
//
//  Created by Weihan on 2020/4/15.
//

import Flutter
import UIKit
import MoPub
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
    private var adView: UIView!
    private let params: [String: Any]
    
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
        
        // Set native ad
        if let nativeAd = controller?.nativeAd {
            do {
                adView = try nativeAd.retrieveAdView()
                adView.frame = nativeAdView.bounds
            } catch {
            }
        }
        
        super.init()
    }
    
    func view() -> UIView {
        return adView
    }
}
