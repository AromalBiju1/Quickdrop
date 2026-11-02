package com.elyssia.quickdrop.quickdrop

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "quickdrop/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "openHotspotSettings" -> {
                    val intents = listOf(
                        Intent("android.settings.TETHER_SETTINGS"),
                        Intent(Settings.ACTION_WIRELESS_SETTINGS),
                        Intent(Settings.ACTION_WIFI_SETTINGS)
                    )
                    result.success(launchFirstAvailable(intents))
                }
                "openWifiSettings" -> {
                    result.success(launchFirstAvailable(listOf(Intent(Settings.ACTION_WIFI_SETTINGS))))
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                }
                "saveToDownloads" -> {
                    val path = call.argument<String>("path")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")
                        ?: "application/octet-stream"
                    if (path.isNullOrBlank() || fileName.isNullOrBlank()) {
                        result.success(null)
                    } else {
                        result.success(saveToDownloads(path, fileName, mimeType))
                    }
                }
                "openDownloads" -> {
                    result.success(
                        launchFirstAvailable(
                            listOf(
                                Intent("android.intent.action.VIEW_DOWNLOADS"),
                                Intent(Intent.ACTION_VIEW).setDataAndType(
                                    Uri.parse("content://com.android.externalstorage.documents/root/primary"),
                                    "vnd.android.document/root"
                                )
                            )
                        )
                    )
                }
                "openFile" -> {
                    val target = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    result.success(openFile(target, mimeType))
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Copies a staged file into public Downloads/QuickDrop through MediaStore.
     * Returns the content URI used to open it later and the human-readable
     * public path shown in the app.
     */
    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String
    ): Map<String, String>? {
        val source = File(sourcePath)
        if (!source.exists()) return null

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(source, fileName, mimeType)
            } else {
                saveToPublicFolder(source, fileName)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun saveWithMediaStore(
        source: File,
        fileName: String,
        mimeType: String
    ): Map<String, String>? {
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/QuickDrop"
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.getContentUri(
            MediaStore.VOLUME_EXTERNAL_PRIMARY
        )
        val uri = resolver.insert(collection, values) ?: return null

        return try {
            resolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("Cannot open $uri")

            val pending = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, pending, null, null)

            val displayName = queryDisplayName(uri) ?: fileName
            val publicPath = File(
                Environment.getExternalStorageDirectory(),
                "${Environment.DIRECTORY_DOWNLOADS}/QuickDrop/$displayName"
            ).absolutePath
            mapOf(
                "uri" to uri.toString(),
                "path" to publicPath,
                "name" to displayName
            )
        } catch (e: Exception) {
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
            }
            null
        }
    }

    private fun saveToPublicFolder(
        source: File,
        fileName: String
    ): Map<String, String>? {
        @Suppress("DEPRECATION")
        val folder = File(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            ),
            "QuickDrop"
        )
        if (!folder.exists() && !folder.mkdirs()) return null

        val target = uniqueFile(folder, fileName)
        target.outputStream().use { output ->
            source.inputStream().use { input -> input.copyTo(output) }
        }
        return mapOf(
            "uri" to "",
            "path" to target.absolutePath,
            "name" to target.name
        )
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(
            uri,
            arrayOf(MediaStore.MediaColumns.DISPLAY_NAME),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(0)
        }
        return null
    }

    private fun uniqueFile(folder: File, fileName: String): File {
        var target = File(folder, fileName)
        if (!target.exists()) return target
        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val ext = if (dot > 0) fileName.substring(dot) else ""
        var index = 1
        while (target.exists()) {
            target = File(folder, "$base ($index)$ext")
            index++
        }
        return target
    }

    private fun openFile(target: String?, mimeType: String): Boolean {
        if (target.isNullOrBlank()) return false
        return try {
            val uri = if (target.startsWith("content://")) {
                Uri.parse(target)
            } else {
                val file = File(target)
                if (!file.exists()) return false
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
            }
            startActivity(
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mimeType)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun launchFirstAvailable(intents: List<Intent>): Boolean {
        for (intent in intents) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // Try the next settings screen.
            }
        }
        return false
    }
}
