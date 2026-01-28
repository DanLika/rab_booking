package io.bookbed.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return

            // Bookings channel (new bookings, confirmations, cancellations, payments)
            val bookingsChannel = NotificationChannel(
                "bookbed_bookings",
                "Rezervacije",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Obavijesti o novim rezervacijama, potvrde, otkazivanja i plaćanja"
                enableVibration(true)
            }

            // Marketing channel (trial expiration, promotions)
            val marketingChannel = NotificationChannel(
                "bookbed_marketing",
                "Obavijesti",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Obavijesti o probnom periodu i ažuriranja"
            }

            manager.createNotificationChannels(
                listOf(bookingsChannel, marketingChannel)
            )
        }
    }
}
