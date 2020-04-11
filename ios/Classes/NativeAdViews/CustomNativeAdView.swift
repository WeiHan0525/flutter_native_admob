//
//  CustomNativeAdView.swift
//  Runner
//
//  Created by Weihan on 2020/4/10.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import UIKit
import GoogleMobileAds

class CustomNativeAdView: GADUnifiedNativeAdView {
    @IBOutlet weak var mediaview: GADMediaView!
    @IBOutlet weak var headLineLabel: UILabel!
    @IBOutlet weak var attribution: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    
    var options = NativeAdmobOptions() {
        didSet { updateOptions() }
    }
    
    func setNativeAd(_ nativeAd: GADUnifiedNativeAd?) {
        guard let nativeAd = nativeAd else { return }
        self.nativeAd = nativeAd
        
        // Set the mediaContent on the GADMediaView to populate it with available
        // video/image asset.
        mediaview.mediaContent = nativeAd.mediaContent
        
        // Populate the native ad view with the native ad assets.
        // The headline is guaranteed to be present in every native ad.
        headLineLabel.text = nativeAd.headline
        
        layoutIfNeeded()
    }

    func updateOptions() {
        headLineLabel.textColor = options.headlineTextStyle.color
    }
}
