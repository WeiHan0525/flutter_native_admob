//
//  MopubNativeAdView.swift
//  FBSDKCoreKit
//
//  Created by Weihan on 2020/4/14.
//

import UIKit
import MoPub

class MopubNativeAdView: UIView, MPNativeAdRendering {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var callToActionLabel: UILabel!
    @IBOutlet weak var attributionLabel: UILabel!
    @IBOutlet weak var privacyInformationIconImageView: UIImageView!
    
    var options = NativeAdmobOptions() {
        didSet { updateOptions() }
    }
    
    static func nibForAd() -> UINib! {
        let adscell:UINib = UINib(nibName: "MoPubNativeView", bundle: nil)
        return adscell
    }
    
    func nativeMainImageView() -> UIImageView! {
        return self.mainImageView
    }
    
    func nativeTitleTextLabel() -> UILabel! {
        titleLabel.textColor = options.headlineTextStyle.color
        return self.titleLabel
    }
    
    func nativeCallToActionTextLabel() -> UILabel! {
        return self.callToActionLabel
    }
    
    func nativePrivacyInformationIconImageView() -> UIImageView! {
        return self.privacyInformationIconImageView
    }

    func updateOptions() {
//        titleLabel.textColor = options.headlineTextStyle.color
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
