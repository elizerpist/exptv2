package com.exptv2.app.expense

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class ExpenseTextFileExporter(
    private val activity: FragmentActivity,
    private val context: Context,
) {
    fun saveTextFile(args: Map<*, *>): String {
        val payload = payload(args)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(payload)
        } else {
            saveLegacyDownload(payload)
        }
    }

    suspend fun shareTextFile(args: Map<*, *>) {
        val payload = payload(args)
        val file = cacheFile(payload)
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = payload.mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, payload.fileName)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(
            intent,
            args["chooserTitle"]?.toString()?.takeIf { it.isNotBlank() } ?: "Megosztás",
        )
        withContext(Dispatchers.Main) {
            activity.startActivity(chooser)
        }
    }

    private fun saveWithMediaStore(payload: TextFilePayload): String {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, payload.fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, payload.mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw ExpenseValidationException("EXPORT_SAVE_FAILED", "Could not create export file")
        resolver.openOutputStream(uri)?.use { output ->
            output.write(payload.content.toByteArray(Charsets.UTF_8))
        } ?: throw ExpenseValidationException("EXPORT_SAVE_FAILED", "Could not write export file")
        return uri.toString()
    }

    private fun saveLegacyDownload(payload: TextFilePayload): String {
        val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!directory.exists()) directory.mkdirs()
        val file = uniqueFile(directory, payload.fileName)
        file.writeText(payload.content, Charsets.UTF_8)
        return Uri.fromFile(file).toString()
    }

    private fun cacheFile(payload: TextFilePayload): File {
        val directory = File(context.cacheDir, "exports")
        if (!directory.exists()) directory.mkdirs()
        val file = File(directory, payload.fileName)
        file.writeText(payload.content, Charsets.UTF_8)
        return file
    }

    private fun uniqueFile(directory: File, fileName: String): File {
        val requested = File(directory, fileName)
        if (!requested.exists()) return requested
        val extensionIndex = fileName.lastIndexOf('.')
        val base = if (extensionIndex > 0) fileName.substring(0, extensionIndex) else fileName
        val extension = if (extensionIndex > 0) fileName.substring(extensionIndex) else ""
        var index = 2
        while (true) {
            val candidate = File(directory, "$base-$index$extension")
            if (!candidate.exists()) return candidate
            index += 1
        }
    }

    private fun payload(args: Map<*, *>): TextFilePayload {
        val fileName = sanitizeFileName(
            args["fileName"]?.toString()?.takeIf { it.isNotBlank() }
                ?: throw ExpenseValidationException("EXPORT_FILE_NAME_REQUIRED", "Export file name is required"),
        )
        val mimeType = args["mimeType"]?.toString()?.takeIf { it.isNotBlank() } ?: "text/plain"
        val content = args["content"]?.toString()
            ?: throw ExpenseValidationException("EXPORT_CONTENT_REQUIRED", "Export content is required")
        return TextFilePayload(fileName = fileName, mimeType = mimeType, content = content)
    }

    private fun sanitizeFileName(fileName: String): String {
        return fileName.replace(Regex("[^A-Za-z0-9._-]"), "_")
    }

    private data class TextFilePayload(
        val fileName: String,
        val mimeType: String,
        val content: String,
    )
}
