package com.exptv2.app.expense

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.security.SecureRandom
import kotlin.math.roundToInt

class ExpenseSettingsStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)

    fun loadSettings(
        biometricAvailable: Boolean = false,
        biometricLabel: String = "Nem elerheto",
    ): Map<String, Any?> = mapOf(
        "themeSettings" to loadThemeSettings(),
        "fastInfoConfig" to loadFastInfoConfig(),
        "pushRecurringSettings" to loadPushRecurringSettings(),
        "notificationSettings" to loadNotificationSettings(),
        "securitySettings" to loadSecuritySettings(
            biometricAvailable = biometricAvailable,
            biometricLabel = biometricLabel,
        ),
    )

    fun loadThemeSettings(): Map<String, Any?> {
        return mapOf(
            "magnetType" to prefs.getString(KEY_MAGNET_TYPE, "fade"),
            "cardColor" to prefs.getString(KEY_CARD_COLOR, "lightgray"),
            "theme" to legacyTheme(),
            "backgroundColor" to prefs.getString(KEY_BACKGROUND_COLOR, "gray"),
            "boxColor" to prefs.getString(KEY_BOX_COLOR, "gray"),
            "buttonSurfaceStyle" to prefs.getString(KEY_BUTTON_SURFACE_STYLE, "neutralNeutral"),
            "contentSurfaceStyle" to prefs.getString(KEY_CONTENT_SURFACE_STYLE, "neutralNeutral"),
            "categoryMenuColor" to prefs.getString(KEY_CATEGORY_MENU_COLOR, "lightgray"),
            "categoryMenuSurfaceStyle" to prefs.getString(KEY_CATEGORY_MENU_SURFACE_STYLE, "neutralNeutral"),
            "categoryCardColor" to prefs.getString(KEY_CATEGORY_CARD_COLOR, "lightgray"),
            "categoryCardSurfaceStyle" to prefs.getString(KEY_CATEGORY_CARD_SURFACE_STYLE, "neutralNeutral"),
            "categoryMenuPresentation" to prefs.getString(KEY_CATEGORY_MENU_PRESENTATION, "inline"),
            "categoryCardShadowEnabled" to prefs.getBoolean(KEY_CATEGORY_CARD_SHADOW_ENABLED, true),
            "logboxShadowEnabled" to prefs.getBoolean(KEY_LOGBOX_SHADOW_ENABLED, false),
            "headerPillShadowEnabled" to prefs.getBoolean(KEY_HEADER_PILL_SHADOW_ENABLED, true),
            "summaryPillShadowEnabled" to prefs.getBoolean(KEY_SUMMARY_PILL_SHADOW_ENABLED, true),
            "searchPillShadowEnabled" to prefs.getBoolean(KEY_SEARCH_PILL_SHADOW_ENABLED, true),
            "ghostLogboxSurfaceStyle" to (
                prefs.getString(KEY_GHOST_LOGBOX_SURFACE_STYLE, null)?.takeIf { it.isNotBlank() }
                    ?: legacyGhostLogboxSurfaceStyle()
                ),
            "ghostLogboxSettings" to loadGhostLogboxSettings(),
            "backheaderStyle" to prefs.getString(KEY_BACKHEADER_STYLE, "classic"),
            "centerBackheaderDesign" to prefs.getString(
                KEY_CENTER_BACKHEADER_DESIGN,
                "neutral",
            ),
            "centerPartitionRingEnabled" to prefs.getBoolean(
                KEY_CENTER_PARTITION_RING_ENABLED,
                false,
            ),
            "centerBadgeDiscEnabled" to prefs.getBoolean(
                KEY_CENTER_BADGE_DISC_ENABLED,
                true,
            ),
            "centerBadgeBorderMode" to prefs.getString(
                KEY_CENTER_BADGE_BORDER_MODE,
                "limitOnly",
            ),
            "centerBadgeWhiteDiscOpacities" to loadOpacityList(
                KEY_CENTER_BADGE_WHITE_DISC_OPACITIES,
                DEFAULT_CENTER_BADGE_WHITE_DISC_OPACITIES,
            ),
            "centerBadgeWhiteIconOpacities" to loadOpacityList(
                KEY_CENTER_BADGE_WHITE_ICON_OPACITIES,
                DEFAULT_CENTER_BADGE_WHITE_ICON_OPACITIES,
            ),
            "centerBadgeWhiteProgressOpacities" to loadOpacityList(
                KEY_CENTER_BADGE_WHITE_PROGRESS_OPACITIES,
                DEFAULT_CENTER_BADGE_WHITE_PROGRESS_OPACITIES,
            ),
            "centerBadgeColoredBackgroundOpacity" to prefs.getInt(
                KEY_CENTER_BADGE_COLORED_BACKGROUND_OPACITY,
                DEFAULT_CENTER_BADGE_COLORED_BACKGROUND_OPACITY,
            ),
            "designProfile" to (
                prefs.getString(KEY_DESIGN_PROFILE, null)?.takeIf { it.isNotBlank() }
                    ?: legacyDesignProfile()
                ),
            "appColor" to (
                prefs.getString(KEY_APP_COLOR, null)?.takeIf { it.isNotBlank() }
                    ?: legacyAppColor()
                ),
        )
    }

    fun updateThemeSettings(args: Map<*, *>): Map<String, Any?> {
        val theme = legacyTheme(args["theme"]?.toString())
        val buttonSurfaceStyle = args["buttonSurfaceStyle"]?.toString() ?: "neutralNeutral"
        val contentSurfaceStyle = args["contentSurfaceStyle"]?.toString() ?: "neutralNeutral"
        val ghostLogboxSurfaceStyle = args["ghostLogboxSurfaceStyle"]?.toString()?.takeIf { it.isNotBlank() }
            ?: legacyGhostLogboxSurfaceStyle(legacyDesignProfile(buttonSurfaceStyle, contentSurfaceStyle))
        val ghostLogboxSettings = args["ghostLogboxSettings"] as? Map<*, *> ?: emptyMap<Any?, Any?>()

        prefs.edit()
            .putString(KEY_MAGNET_TYPE, args["magnetType"]?.toString() ?: "fade")
            .putString(KEY_CARD_COLOR, args["cardColor"]?.toString() ?: "lightgray")
            .putString(KEY_THEME, theme)
            .putString(KEY_BACKGROUND_COLOR, args["backgroundColor"]?.toString() ?: "gray")
            .putString(KEY_BOX_COLOR, args["boxColor"]?.toString() ?: "gray")
            .putString(KEY_BUTTON_SURFACE_STYLE, buttonSurfaceStyle)
            .putString(KEY_CONTENT_SURFACE_STYLE, contentSurfaceStyle)
            .putString(KEY_CATEGORY_MENU_COLOR, args["categoryMenuColor"]?.toString() ?: "lightgray")
            .putString(KEY_CATEGORY_MENU_SURFACE_STYLE, args["categoryMenuSurfaceStyle"]?.toString() ?: "neutralNeutral")
            .putString(KEY_CATEGORY_CARD_COLOR, args["categoryCardColor"]?.toString() ?: "lightgray")
            .putString(KEY_CATEGORY_CARD_SURFACE_STYLE, args["categoryCardSurfaceStyle"]?.toString() ?: "neutralNeutral")
            .putString(KEY_CATEGORY_MENU_PRESENTATION, args["categoryMenuPresentation"]?.toString() ?: "inline")
            .putBoolean(KEY_CATEGORY_CARD_SHADOW_ENABLED, boolArg(args["categoryCardShadowEnabled"], true))
            .putBoolean(KEY_LOGBOX_SHADOW_ENABLED, boolArg(args["logboxShadowEnabled"], false))
            .putBoolean(KEY_HEADER_PILL_SHADOW_ENABLED, boolArg(args["headerPillShadowEnabled"], true))
            .putBoolean(KEY_SUMMARY_PILL_SHADOW_ENABLED, boolArg(args["summaryPillShadowEnabled"], true))
            .putBoolean(KEY_SEARCH_PILL_SHADOW_ENABLED, boolArg(args["searchPillShadowEnabled"], true))
            .putString(KEY_GHOST_LOGBOX_SURFACE_STYLE, ghostLogboxSurfaceStyle)
            .putString(
                KEY_GHOST_LOGBOX_BORDER_STYLE,
                ghostLogboxSettings["borderStyle"]?.toString() ?: "dashed"
            )
            .putBoolean(
                KEY_GHOST_LOGBOX_BACKGROUND_OPACITY_ENABLED,
                boolArg(ghostLogboxSettings["backgroundOpacityEnabled"], true)
            )
            .putBoolean(
                KEY_GHOST_LOGBOX_AVATAR_OPACITY_ENABLED,
                boolArg(ghostLogboxSettings["avatarOpacityEnabled"], false)
            )
            .putBoolean(
                KEY_GHOST_LOGBOX_TEXT_OPACITY_ENABLED,
                boolArg(ghostLogboxSettings["textOpacityEnabled"], false)
            )
            .putBoolean(
                KEY_GHOST_LOGBOX_AVATAR_BADGE_ENABLED,
                boolArg(ghostLogboxSettings["avatarBadgeEnabled"], true)
            )
            .putString(
                KEY_GHOST_LOGBOX_TEXT_TONE,
                ghostLogboxSettings["textTone"]?.toString() ?: "normal"
            )
            .putBoolean(
                KEY_GHOST_LOGBOX_EXPECTED_LABEL_ENABLED,
                boolArg(ghostLogboxSettings["expectedLabelEnabled"], true)
            )
            .putString(KEY_BACKHEADER_STYLE, args["backheaderStyle"]?.toString() ?: "classic")
            .putString(
                KEY_CENTER_BACKHEADER_DESIGN,
                args["centerBackheaderDesign"]?.toString() ?: "neutral"
            )
            .putBoolean(
                KEY_CENTER_PARTITION_RING_ENABLED,
                boolArg(args["centerPartitionRingEnabled"], false)
            )
            .putBoolean(
                KEY_CENTER_BADGE_DISC_ENABLED,
                boolArg(args["centerBadgeDiscEnabled"], true)
            )
            .putString(
                KEY_CENTER_BADGE_BORDER_MODE,
                args["centerBadgeBorderMode"]?.toString()?.takeIf { it.isNotBlank() }
                    ?: "limitOnly"
            )
            .putString(
                KEY_CENTER_BADGE_WHITE_DISC_OPACITIES,
                JSONArray(
                    opacityListArg(
                        args["centerBadgeWhiteDiscOpacities"],
                        DEFAULT_CENTER_BADGE_WHITE_DISC_OPACITIES,
                    ),
                ).toString(),
            )
            .putString(
                KEY_CENTER_BADGE_WHITE_ICON_OPACITIES,
                JSONArray(
                    opacityListArg(
                        args["centerBadgeWhiteIconOpacities"],
                        DEFAULT_CENTER_BADGE_WHITE_ICON_OPACITIES,
                    ),
                ).toString(),
            )
            .putString(
                KEY_CENTER_BADGE_WHITE_PROGRESS_OPACITIES,
                JSONArray(
                    opacityListArg(
                        args["centerBadgeWhiteProgressOpacities"],
                        DEFAULT_CENTER_BADGE_WHITE_PROGRESS_OPACITIES,
                    ),
                ).toString(),
            )
            .putInt(
                KEY_CENTER_BADGE_COLORED_BACKGROUND_OPACITY,
                opacityArg(
                    args["centerBadgeColoredBackgroundOpacity"],
                    DEFAULT_CENTER_BADGE_COLORED_BACKGROUND_OPACITY,
                ),
            )
            .remove(KEY_DESIGN_PROFILE)
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

    fun loadNotificationSettings(): Map<String, Any?> = mapOf(
        "androidPushEnabled" to prefs.getBoolean(KEY_NOTIFICATION_ANDROID_PUSH_ENABLED, true),
        "inAppCardsEnabled" to prefs.getBoolean(KEY_NOTIFICATION_IN_APP_CARDS_ENABLED, true),
        "limitAlertsEnabled" to prefs.getBoolean(KEY_NOTIFICATION_LIMIT_ALERTS_ENABLED, true),
        "recurringAlertsEnabled" to prefs.getBoolean(KEY_NOTIFICATION_RECURRING_ALERTS_ENABLED, true),
        "transactionAlertsEnabled" to prefs.getBoolean(KEY_NOTIFICATION_TRANSACTION_ALERTS_ENABLED, true),
    )

    fun updateNotificationSettings(args: Map<*, *>): Map<String, Any?> {
        prefs.edit()
            .putBoolean(KEY_NOTIFICATION_ANDROID_PUSH_ENABLED, boolArg(args["androidPushEnabled"], true))
            .putBoolean(KEY_NOTIFICATION_IN_APP_CARDS_ENABLED, boolArg(args["inAppCardsEnabled"], true))
            .putBoolean(KEY_NOTIFICATION_LIMIT_ALERTS_ENABLED, boolArg(args["limitAlertsEnabled"], true))
            .putBoolean(KEY_NOTIFICATION_RECURRING_ALERTS_ENABLED, boolArg(args["recurringAlertsEnabled"], true))
            .putBoolean(KEY_NOTIFICATION_TRANSACTION_ALERTS_ENABLED, boolArg(args["transactionAlertsEnabled"], true))
            .apply()
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

    private fun loadGhostLogboxSettings(): Map<String, Any?> = mapOf(
        "borderStyle" to prefs.getString(KEY_GHOST_LOGBOX_BORDER_STYLE, "dashed"),
        "backgroundOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_BACKGROUND_OPACITY_ENABLED, true),
        "avatarOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_AVATAR_OPACITY_ENABLED, false),
        "textOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_TEXT_OPACITY_ENABLED, false),
        "avatarBadgeEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_AVATAR_BADGE_ENABLED, true),
        "textTone" to prefs.getString(KEY_GHOST_LOGBOX_TEXT_TONE, "normal"),
        "expectedLabelEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_EXPECTED_LABEL_ENABLED, true),
    )

    private fun boolArg(value: Any?, default: Boolean): Boolean = when (value) {
        is Boolean -> value
        is Number -> value.toInt() != 0
        is String -> value.equals("true", ignoreCase = true) || value == "1"
        else -> default
    }

    private fun loadOpacityList(key: String, default: List<Int>): List<Int> {
        val raw = prefs.getString(key, null) ?: return default
        val values = runCatching { jsonArrayToList(JSONArray(raw)) }.getOrNull()
            ?: return default
        return opacityListArg(values, default)
    }

    private fun opacityListArg(value: Any?, default: List<Int>): List<Int> {
        val values = when (value) {
            is List<*> -> value
            is JSONArray -> jsonArrayToList(value)
            else -> null
        }
        return default.mapIndexed { index, fallback ->
            opacityArg(values?.getOrNull(index), fallback)
        }
    }

    private fun opacityArg(value: Any?, default: Int): Int {
        val parsed = when (value) {
            is Number -> value.toDouble()
            is String -> value.trim().toDoubleOrNull()
            else -> null
        } ?: return default
        return parsed.roundToInt().coerceIn(0, 100)
    }

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

    private fun legacyGhostLogboxSurfaceStyle(
        legacyProfile: String = prefs.getString(KEY_DESIGN_PROFILE, null)?.takeIf { it.isNotBlank() }
            ?: legacyDesignProfile(),
    ): String {
        return if (legacyProfile == "neumorphism") "insetInset" else "neutralNeutral"
    }

    private fun legacyTheme(theme: String? = prefs.getString(KEY_THEME, null)): String {
        return if (theme == "Pink") "Pink" else "Türkiz"
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
        private const val KEY_CATEGORY_MENU_COLOR = "categoryMenuColor"
        private const val KEY_CATEGORY_MENU_SURFACE_STYLE = "categoryMenuSurfaceStyle"
        private const val KEY_CATEGORY_CARD_COLOR = "categoryCardColor"
        private const val KEY_CATEGORY_CARD_SURFACE_STYLE = "categoryCardSurfaceStyle"
        private const val KEY_CATEGORY_MENU_PRESENTATION = "categoryMenuPresentation"
        private const val KEY_CATEGORY_CARD_SHADOW_ENABLED = "categoryCardShadowEnabled"
        private const val KEY_LOGBOX_SHADOW_ENABLED = "logboxShadowEnabled"
        private const val KEY_HEADER_PILL_SHADOW_ENABLED = "headerPillShadowEnabled"
        private const val KEY_SUMMARY_PILL_SHADOW_ENABLED = "summaryPillShadowEnabled"
        private const val KEY_SEARCH_PILL_SHADOW_ENABLED = "searchPillShadowEnabled"
        private const val KEY_GHOST_LOGBOX_SURFACE_STYLE = "ghostLogboxSurfaceStyle"
        private const val KEY_GHOST_LOGBOX_BORDER_STYLE = "ghostLogboxBorderStyle"
        private const val KEY_GHOST_LOGBOX_BACKGROUND_OPACITY_ENABLED = "ghostLogboxBackgroundOpacityEnabled"
        private const val KEY_GHOST_LOGBOX_AVATAR_OPACITY_ENABLED = "ghostLogboxAvatarOpacityEnabled"
        private const val KEY_GHOST_LOGBOX_TEXT_OPACITY_ENABLED = "ghostLogboxTextOpacityEnabled"
        private const val KEY_GHOST_LOGBOX_AVATAR_BADGE_ENABLED = "ghostLogboxAvatarBadgeEnabled"
        private const val KEY_GHOST_LOGBOX_TEXT_TONE = "ghostLogboxTextTone"
        private const val KEY_GHOST_LOGBOX_EXPECTED_LABEL_ENABLED = "ghostLogboxExpectedLabelEnabled"
        private const val KEY_BACKHEADER_STYLE = "backheaderStyle"
        private const val KEY_CENTER_BACKHEADER_DESIGN = "centerBackheaderDesign"
        private const val KEY_CENTER_PARTITION_RING_ENABLED = "centerPartitionRingEnabled"
        private const val KEY_CENTER_BADGE_DISC_ENABLED = "centerBadgeDiscEnabled"
        private const val KEY_CENTER_BADGE_BORDER_MODE = "centerBadgeBorderMode"
        private const val KEY_CENTER_BADGE_WHITE_DISC_OPACITIES = "centerBadgeWhiteDiscOpacities"
        private const val KEY_CENTER_BADGE_WHITE_ICON_OPACITIES = "centerBadgeWhiteIconOpacities"
        private const val KEY_CENTER_BADGE_WHITE_PROGRESS_OPACITIES = "centerBadgeWhiteProgressOpacities"
        private const val KEY_CENTER_BADGE_COLORED_BACKGROUND_OPACITY = "centerBadgeColoredBackgroundOpacity"
        private const val KEY_DESIGN_PROFILE = "designProfile"
        private const val KEY_APP_COLOR = "appColor"
        private const val KEY_FAST_INFO = "fastInfoConfig"
        private const val KEY_PUSH_RECURRING_CONFLICT_POLICY = "pushRecurringConflictPolicy"
        private const val KEY_NOTIFICATION_ANDROID_PUSH_ENABLED = "notificationAndroidPushEnabled"
        private const val KEY_NOTIFICATION_IN_APP_CARDS_ENABLED = "notificationInAppCardsEnabled"
        private const val KEY_NOTIFICATION_LIMIT_ALERTS_ENABLED = "notificationLimitAlertsEnabled"
        private const val KEY_NOTIFICATION_RECURRING_ALERTS_ENABLED = "notificationRecurringAlertsEnabled"
        private const val KEY_NOTIFICATION_TRANSACTION_ALERTS_ENABLED = "notificationTransactionAlertsEnabled"
        private const val KEY_SECURITY_PIN_SALT = "securityPinSalt"
        private const val KEY_SECURITY_PIN_HASH = "securityPinHash"
        private const val KEY_SECURITY_BIOMETRIC_ENABLED = "securityBiometricEnabled"
        private val DEFAULT_CENTER_BADGE_WHITE_DISC_OPACITIES = listOf(18, 13, 10, 9, 8)
        private val DEFAULT_CENTER_BADGE_WHITE_ICON_OPACITIES = listOf(100, 72, 58, 48, 42)
        private val DEFAULT_CENTER_BADGE_WHITE_PROGRESS_OPACITIES = listOf(100, 72, 58, 48, 42)
        private const val DEFAULT_CENTER_BADGE_COLORED_BACKGROUND_OPACITY = 72
    }
}
