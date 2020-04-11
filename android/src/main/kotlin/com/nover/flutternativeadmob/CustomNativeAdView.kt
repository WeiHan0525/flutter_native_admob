package com.nover.flutternativeadmob

import android.content.Context
import android.graphics.Color
import android.graphics.PorterDuff
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.formats.MediaView
import com.google.android.gms.ads.formats.UnifiedNativeAd
import com.google.android.gms.ads.formats.UnifiedNativeAdView


class CustomNativeAdView @JvmOverloads constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    var options = NativeAdmobOptions()
        set(value) {
            field = value
            updateOptions()
        }

    private var adView: UnifiedNativeAdView

    private val adMedia: MediaView?

    private val adHeadline: TextView
    private val adAttribution: TextView
    private val callToAction: TextView

    init {
        val inflater = LayoutInflater.from(context)
        val layout = R.layout.native_ad_layout
        inflater.inflate(layout, this, true)

        adView = findViewById(R.id.ad_view)

        setBackgroundColor(Color.TRANSPARENT)

        adMedia = adView.findViewById(R.id.ad_media)

        adHeadline = adView.findViewById(R.id.ad_headline)
        adAttribution = adView.findViewById(R.id.ad_attribution)
        callToAction = adView.findViewById(R.id.ad_call_to_action)

        initialize()
    }

    private fun initialize() {
        // The MediaView will display a video asset if one is present in the ad, and the
        // first image asset otherwise.
        adView.mediaView = adMedia

        // Register the view used for each individual asset.
        adView.headlineView = adHeadline
        adView.callToActionView = callToAction
    }

    fun setNativeAd(nativeAd: UnifiedNativeAd?) {
        if (nativeAd == null) return

        // Some assets are guaranteed to be in every UnifiedNativeAd.
        adMedia?.setMediaContent(nativeAd.mediaContent)
        adMedia?.setImageScaleType(ImageView.ScaleType.FIT_CENTER)

        adHeadline.text = nativeAd.headline

        // Assign native ad object to the native view.
        adView.setNativeAd(nativeAd)
    }

    private fun updateOptions() {
        adAttribution.setTextColor(options.adLabelTextStyle.color)

        adHeadline.setTextColor(options.headlineTextStyle.color)

        callToAction.setTextColor(options.callToActionStyle.color)
    }
}