package net.mebaddev.lunolauncher

import android.Manifest
import android.app.Activity
import android.app.WallpaperManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

/** WallpaperPlugin */
class WallpaperPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  
  private val READ_EXTERNAL_STORAGE_REQUEST_CODE = 2345
  
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "net.mebaddev.lunolauncher/wallpaper")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getWallpaper" -> {
        pendingResult = result
        if (hasPermission()) {
          getWallpaperImpl(result)
        } else {
          requestPermission()
        }
      }
      "getAndroidSdkVersion" -> {
        result.success(Build.VERSION.SDK_INT)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun hasPermission(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      // For API 33+ (Android 13+), we need READ_MEDIA_IMAGES
      ContextCompat.checkSelfPermission(context, Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
    } else {
      // For API 32 and below, we need READ_EXTERNAL_STORAGE
      ContextCompat.checkSelfPermission(context, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun requestPermission() {
    activity?.let { act ->
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        // For API 33+ (Android 13+)
        ActivityCompat.requestPermissions(
          act,
          arrayOf(Manifest.permission.READ_MEDIA_IMAGES),
          READ_EXTERNAL_STORAGE_REQUEST_CODE
        )
      } else {
        // For API 32 and below
        ActivityCompat.requestPermissions(
          act,
          arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
          READ_EXTERNAL_STORAGE_REQUEST_CODE
        )
      }
    } ?: run {
      pendingResult?.error("NO_ACTIVITY", "No activity available to request permissions", null)
      pendingResult = null
    }
  }

  private fun getWallpaperImpl(result: Result) {
    try {
      val wallpaperBytes = getWallpaperBytes()
      if (wallpaperBytes != null) {
        result.success(wallpaperBytes)
      } else {
        result.error("WALLPAPER_ERROR", "Failed to get wallpaper data", null)
      }
    } catch (e: Exception) {
      result.error("EXCEPTION", "Exception while getting wallpaper: ${e.message}", e.stackTraceToString())
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
  
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }
  
  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }
  
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }
  
  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == READ_EXTERNAL_STORAGE_REQUEST_CODE) {
      if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        pendingResult?.let {
          getWallpaperImpl(it)
          pendingResult = null
          return true
        }
      } else {
        pendingResult?.error("PERMISSION_DENIED", "The user denied the permission", null)
        pendingResult = null
        return true
      }
    }
    return false
  }

  private fun getWallpaperBytes(): ByteArray? {
    try {
      val wallpaperManager = WallpaperManager.getInstance(context)
      
      // Get the wallpaper as a drawable
      val wallpaperDrawable = wallpaperManager.drawable
      
      // Convert drawable to bitmap if not null
      if (wallpaperDrawable != null) {
        val wallpaperBitmap = drawableToBitmap(wallpaperDrawable)
        
        // Convert bitmap to byte array
        val byteArrayOutputStream = ByteArrayOutputStream()
        wallpaperBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
        return byteArrayOutputStream.toByteArray()
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }
    return null
  }
  
  private fun drawableToBitmap(drawable: Drawable): Bitmap {
    val width = drawable.intrinsicWidth
    val height = drawable.intrinsicHeight
    
    // If drawable has no intrinsic dimensions, use default size
    val finalWidth = if (width <= 0) 1000 else width
    val finalHeight = if (height <= 0) 1000 else height
    
    val bitmap = Bitmap.createBitmap(finalWidth, finalHeight, Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(bitmap)
    drawable.setBounds(0, 0, canvas.width, canvas.height)
    drawable.draw(canvas)
    return bitmap
  }
}