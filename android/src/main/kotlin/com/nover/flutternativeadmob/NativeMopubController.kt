package com.nover.flutternativeadmob

import android.content.Context
import android.os.AsyncTask
import android.util.Log
import android.view.View
import com.facebook.ads.AdSettings
import com.google.android.gms.ads.formats.NativeAdOptions
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.mopub.nativeads.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException


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
//        val task: AsyncTask<Void?, Void?, String?> = object : AsyncTask<Void?, Void?, String?>() {
//            override fun onPostExecute(advertId: String?) {
//                Log.e("======================", advertId)
//            }
//
//            override fun doInBackground(vararg p0: Void?): String? {
//                var idInfo: AdvertisingIdClient.Info? = null
//                try {
//                    idInfo = AdvertisingIdClient.getAdvertisingIdInfo(context)
//                } catch (e: GooglePlayServicesNotAvailableException) {
//                    e.printStackTrace()
//                } catch (e: GooglePlayServicesRepairableException) {
//                    e.printStackTrace()
//                } catch (e: IOException) {
//                    e.printStackTrace()
//                }
//                var advertId: String? = null
//                try {
//                    advertId = idInfo!!.id
//                } catch (e: NullPointerException) {
//                    e.printStackTrace()
//                }
//                return advertId
//            }
//        }
//        task.execute()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (CallMethod.valueOf(call.method)) {
            CallMethod.setAdUnitID -> {
                call.argument<String>("adUnitID")?.let {
                    val isChanged = adUnitID != it
                    adUnitID = it

                    if (adLoader == null || isChanged) {
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
                                        .addExtra(GooglePlayServicesAdRenderer.VIEW_BINDER_KEY_AD_CHOICES_ICON_CONTAINER,
                                                R.id.native_ad_choices_icon_container)
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
        AdSettings.addTestDevice("54c5265c-4eb1-4eb0-a74e-c146ebbcc282");

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
                object : NativeAd.MoPubNativeEventListener {
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