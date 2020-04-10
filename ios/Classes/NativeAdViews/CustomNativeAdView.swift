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
    @IBOutlet weak var headLineView: UILabel!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func setNativeAd(_ nativeAd: GADUnifiedNativeAd?) {
        guard let nativeAd = nativeAd else { return }
        self.nativeAd = nativeAd
        
        // Set the mediaContent on the GADMediaView to populate it with available
        // video/image asset.
        mediaview.mediaContent = nativeAd.mediaContent
        
        // Populate the native ad view with the native ad assets.
        // The headline is guaranteed to be present in every native ad.
        headLineView.text = nativeAd.headline
        
        layoutIfNeeded()
    }

}
