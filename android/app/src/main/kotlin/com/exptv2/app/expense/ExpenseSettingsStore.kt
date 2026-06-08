package com.exptv2.app.expense

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.security.SecureRandom

class ExpenseSettingsStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)

    fun loadSettings(
        biometricAvailable: Boolean = false,
        biometricLabel: String = "Nem elerheto",
    ): Map<String, Any?> = mapOf(
        "themeSettings" to loadThemeSettings(),
        "fastInfoConfig" to loadFastInfoConfig(),
        "pushRecurringSettings" to loadPushRecurringSettings(),
        "securitySettings" to loadSecuritySettings(
            biometricAvailable = biometricAvailable,
            biometricLabel = biometricLabel,
        ),
    )

    fun loadThemeSettings(): Map<String, Any?> {
        return mapOf(
            "magnetType" to prefs.getString(KEY_MAGNET_TYPE, "fade"),
            "cardColor" to prefs.getString(KEY_CARD_COLOR, "lightgray"),
            "theme" to prefs.getString(KEY_THEME, "Türkiz"),
            "backgroundColor" to prefs.getString(KEY_BACKGROUND_COLOR, "gray"),
            "boxColor" to prefs.getString(KEY_BOX_COLOR, "gray"),
            "buttonSurfaceStyle" to prefs.getString(KEY_BUTTON_SURFACE_STYLE, "neutralNeutral"),
            "contentSurfaceStyle" to prefs.getString(KEY_CONTENT_SURFACE_STYLE, "neutralNeutral"),
            "backheaderStyle" to prefs.getString(KEY_BACKHEADER_STYLE, "classic"),
            "designProfile" to (
                prefs.getString(KEY_DESIGN_PROFILE, null)?.takeIf { it.isNotBlank() }
                    ?: legacyDesignProfile()
                ),
            "nightMode" to (
                prefs.getString(KEY_NIGHT_MODE, null)?.takeIf { it.isNotBlank() }
                    ?: legacyNightMode()
                ),
            "appColor" to (
                prefs.getString(KEY_APP_COLOR, null)?.takeIf { it.isNotBlank() }
                    ?: legacyAppColor()
                ),
        )
    }

    fun updateThemeSettings(args: Map<*, *>): Map<String, Any?> {
        val theme = args["theme"]?.toString() ?: "Türkiz"
        val buttonSurfaceStyle = args["buttonSurfaceStyle"]?.toString() ?: "neutralNeutral"
        val contentSurfaceStyle = args["contentSurfaceStyle"]?.toString() ?: "neutralNeutral"

        prefs.edit()
            .putString(KEY_MAGNET_TYPE, args["magnetType"]?.toString() ?: "fade")
            .putString(KEY_CARD_COLOR, args["cardColor"]?.toString() ?: "lightgray")
            .putString(KEY_THEME, theme)
            .putString(KEY_BACKGROUND_COLOR, args["backgroundColor"]?.toString() ?: "gray")
            .putString(KEY_BOX_COLOR, args["boxColor"]?.toString() ?: "gray")
            .putString(KEY_BUTTON_SURFACE_STYLE, buttonSurfaceStyle)
            .putString(KEY_CONTENT_SURFACE_STYLE, contentSurfaceStyle)
            .putString(KEY_BACKHEADER_STYLE, args["backheaderStyle"]?.toString() ?: "classic")
            .putString(
                KEY_DESIGN_PROFILE,
                args["designProfile"]?.toString()?.takeIf { it.isNotBlank() }
                    ?: legacyDesignProfile(buttonSurfaceStyle, contentSurfaceStyle)
            )
            .putString(
                KEY_NIGHT_MODE,
                args["nightMode"]?.toString()?.takeIf { it.isNotBlank() }
                    ?: legacyNightMode(theme)
            )
            .putString(
                KEY_APP_COLOR,
                args["appColor"]?.toString()?.takeIf { it.isNotBlank() }
                    ?: legacyAppColor(theme)
            )
            .apply()
        return loadThemeSettings()
    }

    fun loadFastInfoConfig(): Map<String, Any?> {
        val raw = prefs.getString(KEY_FAST_INFO, null) ?: return defaultFastInfoConfig()
        return runCatching { jsonObjectToMap(JSONObject(raw)) }.getOrDefault(defaultFastInfoConfig())
    }

    fun updateFastInfoConfig(args: Map<*, *>): Map<String, Any?> {
        val normalized = ExpenseFastInfoConfigNormalizer.normalize(args)
        prefs.edit().putString(KEY_FAST_INFO, JSONObject(normalized).toString()).apply()
        return normalized
    }

    fun loadPushRecurringSettings(): Map<String, Any?> = mapOf(
        "conflictPolicy" to loadPushRecurringConflictPolicy(),
    )

    fun loadPushRecurringConflictPolicy(): String {
        return normalizePushRecurringConflictPolicy(prefs.getString(KEY_PUSH_RECURRING_CONFLICT_POLICY, null))
    }

    fun updatePushRecurringSettings(args: Map<*, *>): Map<String, Any?> {
        val policy = normalizePushRecurringConflictPolicy(args["conflictPolicy"]?.toString())
        prefs.edit().putString(KEY_PUSH_RECURRING_CONFLICT_POLICY, policy).apply()
        return loadSettings()
    }

    fun loadSecuritySettings(
        biometricAvailable: Boolean = false,
        biometricLabel: String = "Nem elerheto",
    ): Map<String, Any?> {
        val pinEnabled = prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank().not()
        val biometricEnabled = pinEnabled && prefs.getBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
        return mapOf(
            "pinEnabled" to pinEnabled,
            "biometricEnabled" to biometricEnabled,
            "biometricAvailable" to biometricAvailable,
            "biometricLabel" to biometricLabel,
        )
    }

    fun setSecurityPin(pin: String): Map<String, Any?> {
        validatePin(pin)
        val salt = newSalt()
        prefs.edit()
            .putString(KEY_SECURITY_PIN_SALT, salt)
            .putString(KEY_SECURITY_PIN_HASH, hashPin(pin, salt))
            .putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
            .apply()
        return loadSecuritySettings()
    }

    fun changeSecurityPin(currentPin: String, newPin: String): Map<String, Any?> {
        if (!verifySecurityPin(currentPin)) {
            throw ExpenseValidationException("PIN_INVALID", "Invalid PIN")
        }
        return setSecurityPin(newPin)
    }

    fun clearSecurityPin(currentPin: String): Map<String, Any?> {
        if (!verifySecurityPin(currentPin)) {
            throw ExpenseValidationException("PIN_INVALID", "Invalid PIN")
        }
        prefs.edit()
            .remove(KEY_SECURITY_PIN_SALT)
            .remove(KEY_SECURITY_PIN_HASH)
            .putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
            .apply()
        return loadSecuritySettings()
    }

    fun verifySecurityPin(pin: String): Boolean {
        val salt = prefs.getString(KEY_SECURITY_PIN_SALT, null) ?: return false
        val storedHash = prefs.getString(KEY_SECURITY_PIN_HASH, null) ?: return false
        return hashPin(pin, salt) == storedHash
    }

    fun setBiometricEnabled(enabled: Boolean, biometricAvailable: Boolean): Map<String, Any?> {
        val pinEnabled = prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank().not()
        if (enabled && !pinEnabled) {
            throw ExpenseValidationException("PIN_NOT_CONFIGURED", "PIN is required")
        }
        if (enabled && !biometricAvailable) {
            throw ExpenseValidationException("BIOMETRIC_UNAVAILABLE", "Biometric authentication is unavailable")
        }
        prefs.edit().putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, enabled).apply()
        return loadSecuritySettings(
            biometricAvailable = biometricAvailable,
            biometricLabel = if (biometricAvailable) "Biometria elerheto" else "Nem elerheto",
        )
    }

    private fun defaultFastInfoConfig(): Map<String, Any?> = ExpenseFastInfoConfigNormalizer.defaultConfig()

    private fun jsonObjectToMap(json: JSONObject): Map<String, Any?> {
        return json.keys().asSequence().associateWith { key -> jsonValue(json.get(key)) }
    }

    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        return (0 until array.length()).map { index -> jsonValue(array.get(index)) }
    }

    private fun jsonValue(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> jsonObjectToMap(value)
        is JSONArray -> jsonArrayToList(value)
        else -> value
    }

    private fun normalizePushRecurringConflictPolicy(value: String?): String {
        return when (value) {
            PUSH_RECURRING_POLICY_ASK_ON_MULTIPLE -> PUSH_RECURRING_POLICY_ASK_ON_MULTIPLE
            else -> PUSH_RECURRING_POLICY_BEST_MATCH
        }
    }

    private fun legacyDesignProfile(
        buttonSurfaceStyle: String? = prefs.getString(KEY_BUTTON_SURFACE_STYLE, null),
        contentSurfaceStyle: String? = prefs.getString(KEY_CONTENT_SURFACE_STYLE, null),
    ): String {
        val buttonStyle = buttonSurfaceStyle ?: "neutralNeutral"
        val contentStyle = contentSurfaceStyle ?: "neutralNeutral"
        return if (
            buttonStyle == "neutralNeutral" &&
            contentStyle == "neutralNeutral"
        ) {
            "normal"
        } else {
            "neumorphism"
        }
    }

    private fun legacyNightMode(theme: String? = prefs.getString(KEY_THEME, null)): String {
        return if (theme == "Sötét") "cyan" else "off"
    }

    private fun legacyAppColor(theme: String? = prefs.getString(KEY_THEME, null)): String {
        return if (theme == "Pink") "pink" else "turquoise"
    }

    private fun validatePin(pin: String) {
        if (!pin.matches(Regex("\\d{4,6}"))) {
            throw ExpenseValidationException("PIN_REQUIRED", "PIN must be 4 to 6 digits")
        }
    }

    private fun newSalt(): String {
        val bytes = ByteArray(16)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun hashPin(pin: String, salt: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest("$salt:$pin".toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    companion object {
        const val PUSH_RECURRING_POLICY_BEST_MATCH = "automaticBestMatch"
        const val PUSH_RECURRING_POLICY_ASK_ON_MULTIPLE = "askOnMultipleMatches"

        private const val KEY_MAGNET_TYPE = "magnetType"
        private const val KEY_CARD_COLOR = "cardColor"
        private const val KEY_THEME = "theme"
        private const val KEY_BACKGROUND_COLOR = "backgroundColor"
        private const val KEY_BOX_COLOR = "boxColor"
        private const val KEY_BUTTON_SURFACE_STYLE = "buttonSurfaceStyle"
        private const val KEY_CONTENT_SURFACE_STYLE = "contentSurfaceStyle"
        private const val KEY_BACKHEADER_STYLE = "backheaderStyle"
        private const val KEY_DESIGN_PROFILE = "designProfile"
        private const val KEY_NIGHT_MODE = "nightMode"
        private const val KEY_APP_COLOR = "appColor"
        private const val KEY_FAST_INFO = "fastInfoConfig"
        private const val KEY_PUSH_RECURRING_CONFLICT_POLICY = "pushRecurringConflictPolicy"
        private const val KEY_SECURITY_PIN_SALT = "securityPinSalt"
        private const val KEY_SECURITY_PIN_HASH = "securityPinHash"
        private const val KEY_SECURITY_BIOMETRIC_ENABLED = "securityBiometricEnabled"
    }
}
