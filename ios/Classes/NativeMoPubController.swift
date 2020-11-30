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

class NativeMoPubController: NSObject, MPNativeAdDelegate {
    
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
    var nativeAd: MPNativeAd?
    
    private var adRequest: MPNativeAdRequest?
    private var adUnitID: String?
    
    private var isLoading = false
    
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
//            print("[MoPub] ========= set ad and load ad =========")
            
            guard let adUnitID = params?["adUnitID"] as? String else {
                return result(nil)
            }
            
            var postCode: Float?
            var postCity: Int?
            if let postcode = params?["postCode"] as? Float {
                postCode = postcode
            }
            
            if let postcity = params?["postCity"] as? Int {
                postCity = postcity
            }
            
            let isChanged = adUnitID != self.adUnitID
            self.adUnitID = adUnitID
            
            if nativeAd == nil || isChanged {
                guard !isLoading else {
//                    print("[MoPub] isLoading \(self.adUnitID)")
                    channel.invokeMethod(LoadState.loading.rawValue, arguments: nil)
                    return
                }
                isLoading = true
                let settings = MPStaticNativeAdRendererSettings.init()
                settings.renderingViewClass = MopubNativeAdView.self
                let config = MPStaticNativeAdRenderer.rendererConfiguration(with: settings)
                let googleConfig = MPGoogleAdMobNativeRenderer.rendererConfiguration(with: settings)
                let facebookConfig = FacebookNativeAdRenderer.rendererConfiguration(with: settings)
                adRequest = MPNativeAdRequest.init(adUnitIdentifier: adUnitID, rendererConfigurations: [config, googleConfig, facebookConfig])
                
//                print("[MoPub] loadAd: \(self.adUnitID), \(self.nativeAd)")
                loadAd(postCode, postCity)
            } else {
//                print("[MoPub] has ad \(self.adUnitID)")
                invokeLoadCompleted()
            }
            
        case .reloadAd:
            var postCode: Float?
            var postCity: Int?
            if let postcode = params?["postCode"] as? Float {
                postCode = postcode
            }
            if let postcity = params?["postCity"] as? Int {
                postCity = postcity
            }
            
//            print("[MoPub] ========= reload ad =========")
            
            guard !isLoading else {
//                print("[MoPub] isLoading \(self.adUnitID)")
                channel.invokeMethod(LoadState.loading.rawValue, arguments: nil)
                return
            }
            
            nativeAd = nil
            isLoading = true
//            print("[MoPub] ad reload \(self.adUnitID)")
            if adRequest == nil {
                let settings = MPStaticNativeAdRendererSettings.init()
                settings.renderingViewClass = MopubNativeAdView.self
                let config = MPStaticNativeAdRenderer.rendererConfiguration(with: settings)
                let googleConfig = MPGoogleAdMobNativeRenderer.rendererConfiguration(with: settings)
                let facebookConfig = FacebookNativeAdRenderer.rendererConfiguration(with: settings)
                adRequest = MPNativeAdRequest.init(adUnitIdentifier: adUnitID, rendererConfigurations: [config, googleConfig, facebookConfig])
//                print("[MoPub]MPNativeAdRequest: \(self.adUnitID), \(self.adRequest)")
            }
            loadAd(postCode, postCity)
        }
        
        result(nil)
    }
    
    private func loadAd(_ postCode: Float?, _ postCity: Int?) {
//        print("[MoPub] ad loading \(self.adUnitID)")
        channel.invokeMethod(LoadState.loading.rawValue, arguments: nil)
        
        var data = ""
        
        if let postCode = postCode {
            data = "w_postCode:\(String(describing: postCode).replacingOccurrences(of: ".0", with: ""))"
        }
        
        if let postCity = postCity {
            if data == "" {
                data = "w_postCity:\(postCity)"
            } else {
                data = "\(data),w_postCity:\(postCity)"
            }
        }
        
        if data != "" {
            let targeting = MPNativeAdRequestTargeting.init()
            targeting?.userDataKeywords = data
            
            if let targeting = targeting {
                adRequest?.targeting = targeting
            }
        }
        
        adRequest?.start(completionHandler: { request, response, error in
            self.isLoading = false
            
            guard error == nil else {
//                print("[MoPub] NativeMoPub: \(self.adUnitID) failed to load with error: \(error)")
                self.channel.invokeMethod(LoadState.loadError.rawValue, arguments: nil)
                return
            }
            
            self.nativeAd = response
            self.nativeAd?.delegate = self
            self.invokeLoadCompleted()
            
            print("[MoPub] load ad complete \(self.adUnitID)")
        })
    }
    
    private func invokeLoadCompleted() {
        nativeAdChanged?(nativeAd)
        channel.invokeMethod(LoadState.loadCompleted.rawValue, arguments: nil)
    }
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        let app = UIApplication.shared.delegate as! FlutterAppDelegate
        if let rootViewController = app.window.rootViewController{
            return rootViewController
        }else {
            return UIViewController()
        }
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
