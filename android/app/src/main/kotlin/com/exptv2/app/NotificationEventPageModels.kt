package com.exptv2.app

data class NotificationEventPageQuery(
    val limit: Int,
    val offset: Int,
    val startMillis: Long?,
    val endMillis: Long?,
    val query: String,
    val status: String,
    val packageName: String,
)

data class NotificationEventPageRow(
    val event: NotificationEventEntity,
    val status: String,
    val linkedTransactionId: Int?,
) {
    fun toMap(): Map<String, Any?> {
        val displayText = listOf(event.text, event.bigText, event.subText)
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
            .joinToString("\n")
        return event.toMap() + mapOf(
            "displayText" to displayText,
            "status" to status,
            "statusText" to NotificationEventStatus.displayText(status),
            "linkedTransactionId" to linkedTransactionId,
        )
    }
}

data class NotificationEventPage(
    val events: List<NotificationEventPageRow>,
    val totalCount: Int,
    val limit: Int,
    val offset: Int,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "events" to events.map { it.toMap() },
        "totalCount" to totalCount,
        "limit" to limit,
        "offset" to offset,
    )
}
