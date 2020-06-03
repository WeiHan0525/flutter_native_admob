package com.nover.flutternativeadmob

import android.content.Context
import android.content.res.Resources
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.mopub.nativeads.AdapterHelper
import com.mopub.nativeads.NativeAd
import com.mopub.nativeads.ViewBinder
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class FlutterNativeAdmobPlugin(
    private val context: Context,
    private val messenger: BinaryMessenger
) : MethodCallHandler {

  enum class CallMethod {
    initController, disposeController
  }

  companion object {

    const val viewType = "native_admob"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val messenger = registrar.messenger()
      val channel = MethodChannel(messenger, "flutter_native_admob")

      val instance = FlutterNativeAdmobPlugin(registrar.context(), messenger)
      channel.setMethodCallHandler(instance)

      // create platform view
      registrar
          .platformViewRegistry()
          .registerViewFactory(viewType, ViewFactory())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (CallMethod.valueOf(call.method)) {
      CallMethod.initController -> {
        (call.argument<String>("controllerID"))?.let {
//          NativeAdmobControllerManager.createController(it, messenger, context)
          NativeMopubControllerManager.createController(it, messenger, context)
        }
      }

      CallMethod.disposeController -> {
        (call.argument<String>("controllerID"))?.let {
//          NativeAdmobControllerManager.removeController(it)
          NativeMopubControllerManager.removeController(it)
        }
      }
    }
  }
}

class ViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

  override fun create(context: Context, id: Int, params: Any?): PlatformView {
    return NativePlatformView(context, id, params)
  }
}

class NativePlatformView(
    context: Context,
    id: Int,
    params: Any?
) : PlatformView {

//  private var controller: NativeAdmobController? = null
  private var controller: NativeMopubController? = null
  private var view = View(context)
  private var options = NativeAdmobOptions()

  init {
    val map = params as HashMap<*, *>

//    var type = NativeAdmobType.full
//    (map["type"] as? String)?.let {
//      type = NativeAdmobType.valueOf(it)
//    }
//    view = NativeAdView(context, type)

    (map["options"] as? HashMap<*, *>)?.let { optionMap ->
        options = NativeAdmobOptions.parse(optionMap)
    }
    Log.d("MoPub", "update options")

    (map["controllerID"] as? String)?.let { id ->
//      val controller = NativeAdmobControllerManager.getController(id)
//      controller?.nativeAdChanged = { view.setNativeAd(it) }
        val controller = NativeMopubControllerManager.getController(id)
        this.controller = controller
    }

    controller?.nativeAd?.let {
      val v: View = AdapterHelper(context, 0, 2)
              .getAdView(null, null, it, ViewBinder.Builder(0).build())
      // Set the native event listeners (onImpression, and onClick).
      it.setMoPubNativeEventListener(object: NativeAd.MoPubNativeEventListener{
        override fun onClick(view: View?) {
          Log.d("MoPub", "Native ad has clicked.")
        }

        override fun onImpression(view: View?) {
          Log.d("MoPub", "Native ad has impressed.")
        }
      })
      val vg = v as ViewGroup
      for (i in 0 until vg.childCount) {
          val child = vg.getChildAt(i)
          if((child is TextView)){
              if(child.id == R.id.ad_headline){
                  child.setTextColor(options.headlineTextStyle.color)
              }
          }
      }
        // Add the ad view to our view hierarchy
        view = v
    }
  }

  override fun getView(): View = view

  override fun dispose() {}
}

fun Int.toRoundedColor(radius: Float): Drawable {
  val drawable = GradientDrawable()
  drawable.shape = GradientDrawable.RECTANGLE
  drawable.cornerRadius = radius * Resources.getSystem().displayMetrics.density
  drawable.setColor(this)
  return drawable
}

fun Int.dp(): Int {
  val density = Resources.getSystem().displayMetrics.density
  return (this * density).toInt()
}
