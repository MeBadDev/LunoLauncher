package com.lunolauncher.app

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

/** WallpaperPlugin */
class WallpaperPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.lunolauncher.app/wallpaper")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getWallpaper") {
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
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun getWallpaperBytes(): ByteArray? {
    try {
      val wallpaperManager = WallpaperManager.getInstance(context)
      
      // Get the wallpaper as a drawable
      val wallpaperDrawable = wallpaperManager.drawable
      
      // Convert drawable to bitmap
      val bitmap = drawableToBitmap(wallpaperDrawable)
      if (bitmap != null) {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)
        return stream.toByteArray()
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }
    return null
  }
  
  private fun drawableToBitmap(drawable: Drawable): Bitmap? {
    try {
      // Create a bitmap with the same dimensions as the drawable
      val bitmap = Bitmap.createBitmap(
        drawable.intrinsicWidth,
        drawable.intrinsicHeight,
        Bitmap.Config.ARGB_8888
      )
      
      // Draw the drawable on the bitmap
      val canvas = android.graphics.Canvas(bitmap)
      drawable.setBounds(0, 0, canvas.width, canvas.height)
      drawable.draw(canvas)
      
      return bitmap
    } catch (e: Exception) {
      e.printStackTrace()
    }
    return null
  }
}