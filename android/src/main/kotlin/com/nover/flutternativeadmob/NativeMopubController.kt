package com.nover.flutternativeadmob

import android.content.Context
import android.util.Log
import android.view.View
import com.facebook.ads.AdSettings
import com.google.android.gms.ads.formats.NativeAdOptions
import com.mopub.common.MoPub
import com.mopub.common.SdkConfiguration
import com.mopub.common.logging.MoPubLog
import com.mopub.mobileads.FacebookAdapterConfiguration
import com.mopub.nativeads.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class NativeMopubController(
        val id: String,
        private val channel: MethodChannel,
        private val context: Context
) : MethodChannel.MethodCallHandler, MoPubNative.MoPubNativeNetworkListener {

    enum class CallMethod {
        setAdUnitID, reloadAd
    }

    enum class LoadState {
        loading, loadError, loadCompleted
    }

    var nativeAdChanged: ((MoPubNative?) -> Unit)? = null
    var nativeAd: NativeAd? = null
        set(value) {
            field = value
            invokeLoadCompleted()
        }
    var adLoader: MoPubNative? = null

    private var adUnitID: String? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (CallMethod.valueOf(call.method)) {
            CallMethod.setAdUnitID -> {
                call.argument<String>("adUnitID")?.let {
                    val isChanged = adUnitID != it
                    adUnitID = it

                    if (adLoader == null || isChanged){
                        adLoader = MoPubNative(this.context, it, this)
                        val viewBinder: ViewBinder = ViewBinder.Builder(R.layout.mopub_native_ad_layout)
                                .mainImageId(R.id.ad_media)
                                .titleId(R.id.ad_headline)
                                .privacyInformationIconImageId(R.id.privacy_information_icon)
                                .callToActionId(R.id.ad_call_to_action)
                                .build()
                        val moPubStaticNativeAdRenderer = MoPubStaticNativeAdRenderer(viewBinder)

                        val googleViewBinder =
                                GooglePlayServicesViewBinder.Builder(R.layout.mopub_native_ad_layout_google)
                                .mediaLayoutId(R.id.ad_media_google)
                                .titleId(R.id.ad_headline)
                                .privacyInformationIconImageId(R.id.privacy_information_icon)
                                .callToActionId(R.id.ad_call_to_action)
                                .build()
                        val googlePlayServicesAdRenderer = GooglePlayServicesAdRenderer(googleViewBinder)

                        val facebookViewBinder =
                                FacebookAdRenderer.FacebookViewBinder.Builder(R.layout.mopub_native_ad_layout_facebook)
                                .titleId(R.id.ad_headline)
                                .mediaViewId(R.id.ad_media_facebook)
                                .adChoicesRelativeLayoutId(R.id.privacy_information_icon)
                                .advertiserNameId(R.id.ad_headline)
                                .callToActionId(R.id.ad_call_to_action)
                                .build()
                        val facebookAdRenderer = FacebookAdRenderer(facebookViewBinder)

                        adLoader?.registerAdRenderer(googlePlayServicesAdRenderer)
                        adLoader?.registerAdRenderer(facebookAdRenderer)
                        adLoader?.registerAdRenderer(moPubStaticNativeAdRenderer)
                    }

                    val postCode: Number? = call.argument<Number>("postCode")
                    val postCity: Int? = call.argument<Int>("postCity")

                    if (nativeAd == null || isChanged) loadAd(postCode, postCity) else invokeLoadCompleted()
                } ?: result.success(null)
            }

            CallMethod.reloadAd -> {
                call.argument<Boolean>("forceRefresh")?.let {
                    val postCode: Number? = call.argument<Number>("postCode")
                    val postCity: Int? = call.argument<Int>("postCity")
                    if (it || adLoader == null) loadAd(postCode, postCity) else invokeLoadCompleted()
                }
            }
        }
    }

    private fun loadAd(postCode: Number?, postCity: Int?) {
        channel.invokeMethod(LoadState.loading.toString(), null)
        // Facebook test device id
        AdSettings.addTestDevice("1634742e-256c-40a3-b3b7-203ffc801b42");

        // admob ad choice position
        val extras: HashMap<String, Any> = HashMap()
        extras[GooglePlayServicesNative.KEY_EXTRA_AD_CHOICES_PLACEMENT] = NativeAdOptions.ADCHOICES_TOP_RIGHT
        adLoader?.setLocalExtras(extras)

        var data = ""
        postCode?.let {
            data = "w_postCode:${it.toString().replace(".0", "")}"
        }
        postCity?.let {
            if(data == "") data = "w_postCity:${it}"
            else data = "${data},w_postCity:${it}"
        }

        if(data != "") {
            val parameters: RequestParameters =
                    RequestParameters.Builder()
                            .userDataKeywords(data)
                            .build()

            adLoader?.makeRequest(parameters)
        }
        else {
            adLoader?.makeRequest()
        }
    }

    private fun invokeLoadCompleted() {
        nativeAdChanged?.let { it(adLoader) }
        channel.invokeMethod(LoadState.loadCompleted.toString(), null)
    }

    override fun onNativeLoad(ad: NativeAd?) {
        Log.d("MoPub", "Native ad has loaded.")
        nativeAd = ad
        nativeAd?.setMoPubNativeEventListener(
            object: NativeAd.MoPubNativeEventListener{
                override fun onClick(view: View?) {
                    Log.d("MoPub", "Native ad has clicked.")
                }

                override fun onImpression(view: View?) {
                    Log.d("MoPub", "Native ad has impressed.")
                }

            })
    }

    override fun onNativeFail(errorCode: NativeErrorCode?) {
        Log.d("MoPub", "Native ad failed to load with error: " + errorCode.toString())
        channel.invokeMethod(LoadState.loadError.toString(), null)
    }
}

object NativeMopubControllerManager {
    private val controllers: ArrayList<NativeMopubController> = arrayListOf()

    fun createController(id: String, binaryMessenger: BinaryMessenger, context: Context) {
        if (getController(id) == null) {
            val methodChannel = MethodChannel(binaryMessenger, id)
            val controller = NativeMopubController(id, methodChannel, context)
            controllers.add(controller)
        }
    }

    fun getController(id: String): NativeMopubController? {
        return controllers.firstOrNull { it.id == id }
    }

    fun removeController(id: String) {
        val index = controllers.indexOfFirst { it.id == id }
        if (index >= 0) controllers.removeAt(index)
    }
}