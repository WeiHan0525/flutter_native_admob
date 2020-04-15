//
//  NativeAdmobController.swift
//  flutter_native_admob
//
//  Created by Dao Duy Duong on 3/14/20.
//

import UIKit
import MoPub
import MoPub_AdMob_Adapters
import MoPub_FacebookAudienceNetwork_Adapters

class NativeMoPubController: NSObject {
    
    enum CallMethod: String {
        case setAdUnitID
        case reloadAd
    }
    
    enum LoadState: String {
        case loading, loadError, loadCompleted
    }
    
    let id: String
    let channel: FlutterMethodChannel
    
    var nativeAdChanged: ((MPNativeAd?) -> Void)?
    var nativeAd: MPNativeAd? {
        didSet { invokeLoadCompleted() }
    }
    
    private var adLoader: MPNativeAdRequest?
    private var adUnitID: String?
    
    init(id: String, channel: FlutterMethodChannel) {
        self.id = id
        self.channel = channel
        super.init()
        
        channel.setMethodCallHandler(handle)
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let callMethod = CallMethod(rawValue: call.method) else { return result(FlutterMethodNotImplemented) }
        let params = call.arguments as? [String: Any]
        
        switch callMethod {
        case .setAdUnitID:
            guard let adUnitID = params?["adUnitID"] as? String else {
                return result(nil)
            }
            
            let isChanged = adUnitID != self.adUnitID
            self.adUnitID = adUnitID
            
            if adLoader == nil || isChanged {
//                let mopubNativeAdView = MopubNativeAdView()
//                if let data = params?["options"] as? [String: Any] {
//                    mopubNativeAdView.options = NativeAdmobOptions(data)
//                    print("retrieve \(mopubNativeAdView.options.headlineTextStyle.color)")
//                }
                let settings = MPStaticNativeAdRendererSettings.init()
                settings.renderingViewClass = MopubNativeAdView.self
                let config = MPStaticNativeAdRenderer.rendererConfiguration(with: settings)
                let googleConfig = MPGoogleAdMobNativeRenderer.rendererConfiguration(with: settings)
                let facebookConfig = FacebookNativeAdRenderer.rendererConfiguration(with: settings)
                adLoader = MPNativeAdRequest.init(adUnitIdentifier: adUnitID, rendererConfigurations: [config, googleConfig, facebookConfig])
            }
            
            if nativeAd == nil || isChanged {
                loadAd()
            } else {
                invokeLoadCompleted()
            }
            
        case .reloadAd:
            let forceRefresh = params?["forceRefresh"] as? Bool ?? false
            if forceRefresh || nativeAd == nil {
                loadAd()
            } else {
                invokeLoadCompleted()
            }
        }
        
        result(nil)
    }
    
    private func loadAd() {
        channel.invokeMethod(LoadState.loading.rawValue, arguments: nil)
        adLoader?.start(completionHandler: { request, response, error in
            if error != nil {
                print("NativeMoPub: failed to load with error: \(error?.localizedDescription)")
                self.channel.invokeMethod(LoadState.loadError.rawValue, arguments: nil)
            } else {
                self.nativeAd = response
//                self.nativeAd?.delegate = self
                print("retrieve get native ad")
            }
        })
    }
    
    private func invokeLoadCompleted() {
        nativeAdChanged?(nativeAd)
        channel.invokeMethod(LoadState.loadCompleted.rawValue, arguments: nil)
    }
}

class NativeMoPubControllerManager {
    
    static let shared = NativeMoPubControllerManager()
    
    private var controllers: [NativeMoPubController] = []
    
    private init() {}
    
    func createController(forID id: String, binaryMessenger: FlutterBinaryMessenger) {
        if getController(forID: id) == nil {
            let methodChannel = FlutterMethodChannel(name: id, binaryMessenger: binaryMessenger)
            let controller = NativeMoPubController(id: id, channel: methodChannel)
            controllers.append(controller)
        }
    }
    
    func getController(forID id: String) -> NativeMoPubController? {
        return controllers.first(where: { $0.id == id })
    }
    
    func removeController(forID id: String) {
        if let index = controllers.firstIndex(where: { $0.id == id }) {
            controllers.remove(at: index)
        }
    }
}
