package net.mebaddev.lunolauncher

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.Toast
import io.flutter.plugin.common.MethodChannel

class SetWallpaperActivity : Activity() {
    private val TAG = "SetWallpaperActivity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "SetWallpaperActivity created")
        
        // Process the intent
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        try {
            // Check if this is a valid intent with image data
            if (intent.action == Intent.ACTION_SEND || intent.action == Intent.ACTION_ATTACH_DATA) {
                Log.d(TAG, "Received action: ${intent.action}")
                
                // Handle image URI from intent
                val imageUri = when {
                    intent.action == Intent.ACTION_SEND && intent.type?.startsWith("image/") == true -> {
                        intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    }
                    intent.action == Intent.ACTION_ATTACH_DATA && intent.data != null -> {
                        intent.data
                    }
                    else -> null
                }
                
                if (imageUri != null) {
                    Log.d(TAG, "Received image URI: $imageUri")
                    setWallpaperFromUri(imageUri)
                } else {
                    Log.e(TAG, "No image URI found in intent")
                    showToast("No image data received")
                    finish()
                }
            } else {
                Log.e(TAG, "Unsupported intent action: ${intent.action}")
                showToast("Unsupported action")
                finish()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling intent", e)
            showToast("Error processing image")
            finish()
        }
    }
    
    private fun setWallpaperFromUri(uri: Uri) {
        try {
            // Get content resolver to read image data
            val contentResolver: ContentResolver = applicationContext.contentResolver
            
            // Create WallpaperManager instance
            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            
            // Option 1: Use WallpaperManager's setStream directly with ContentResolver
            contentResolver.openInputStream(uri)?.use { inputStream ->
                try {
                    // Set the wallpaper
                    wallpaperManager.setStream(inputStream)
                    
                    // Show success message
                    showToast("Wallpaper set successfully")
                    Log.d(TAG, "Wallpaper set successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error setting wallpaper", e)
                    showToast("Failed to set wallpaper")
                }
            } ?: run {
                Log.e(TAG, "Failed to open input stream for URI: $uri")
                showToast("Failed to process image")
            }
        } catch (e: FileNotFoundException) {
            Log.e(TAG, "File not found for URI: $uri", e)
            showToast("Image file not found")
        } catch (e: Exception) {
            Log.e(TAG, "Error setting wallpaper from URI", e)
            showToast("Error setting wallpaper")
        } finally {
            // Always finish the activity when done
            finish()
        }
    }
    
    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
    }
}