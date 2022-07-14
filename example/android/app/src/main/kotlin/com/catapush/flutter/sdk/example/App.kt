package com.catapush.flutter.sdk.example

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import androidx.multidex.MultiDex
import com.catapush.flutter.sdk.CatapushFlutterEventDelegate
import com.catapush.flutter.sdk.CatapushFlutterIntentProvider
import com.catapush.library.Catapush
import com.catapush.library.exceptions.CatapushCompositeException
import com.catapush.library.gms.CatapushGms
import com.catapush.library.interfaces.Callback
import com.catapush.library.interfaces.IIntentProvider
import com.catapush.library.messages.CatapushMessage
import com.catapush.library.notifications.NotificationTemplate
import io.flutter.Log
import io.flutter.app.FlutterApplication


class App : FlutterApplication() {

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "EXAMPLE_CHANNEL"
        const val LOG_TAG = "App"
    }

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }

    override fun onCreate() {
        super.onCreate()

        val notificationColor = ContextCompat.getColor(this, R.color.colorPrimary)
        val notificationSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        // This is the notification template that the Catapush SDK uses to build
        // the status bar notification shown to the user.
        // Customize this template to fit your needs.
        val notificationTemplate = NotificationTemplate.Builder(NOTIFICATION_CHANNEL_ID)
            .swipeToDismissEnabled(true)
            .title(getString(R.string.app_name))
            .vibrationEnabled(true)
            .vibrationPattern(longArrayOf(100, 200, 100, 300))
            .soundEnabled(true)
            .soundResourceUri(notificationSound)
            .circleColor(notificationColor)
            .modalNotificationThemeId(this, R.style.DialogTheme)
            .iconId(R.drawable.ic_stat_notify)
            .useAttachmentPreviewAsLargeIcon(true)
            .modalIconId(R.mipmap.ic_launcher)
            .ledEnabled(true)
            .ledColor(notificationColor)
            .ledOnMS(2000)
            .ledOffMS(1000)
            .build()

        // This is the Android system notification channel that will be used by the Catapush SDK
        // to notify the incoming messages since Android 8.0. It is important that the channel
        // is created before starting Catapush.
        // Customize this channel to fit your needs.
        // See https://developer.android.com/training/notify-user/channels
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager?
        if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelName = "Catapush messages"
            var channel = nm.getNotificationChannel(notificationTemplate.notificationChannelId)
            if (channel == null) {
                channel = NotificationChannel(
                    notificationTemplate.notificationChannelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
                )
                channel.enableVibration(notificationTemplate.isVibrationEnabled)
                channel.vibrationPattern = notificationTemplate.vibrationPattern
                channel.enableLights(notificationTemplate.isLedEnabled)
                channel.lightColor = notificationTemplate.ledColor
                if (notificationTemplate.isSoundEnabled) {
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
                        .build()
                    channel.setSound(notificationTemplate.soundResourceUri, audioAttributes)
                }
            }
            nm.createNotificationChannel(channel)
        }

        Catapush.getInstance()
            .setNotificationIntent(CatapushFlutterIntentProvider(MainActivity::class.java))
            .setSecureCredentialsStoreCallback(object : Callback<Boolean> {
                override fun success(response: Boolean) {
                    Log.i(LOG_TAG, "Secure credentials storage has been initialized!")
                }

                override fun failure(irrecoverableError: Throwable) {
                    Log.w(LOG_TAG, "Can't initialize secure credentials storage.")
                    if (irrecoverableError is CatapushCompositeException) {
                        for (t in irrecoverableError.errors) {
                            Log.e(LOG_TAG, "Can't initialize secure storage", t)
                        }
                    } else {
                        Log.e(LOG_TAG, "Can't initialize secure storage", irrecoverableError)
                    }
                }
            })
            .init(
                this,
                CatapushFlutterEventDelegate,
                listOf(CatapushGms),
                notificationTemplate,
                null,
                object : Callback<Boolean> {
                    override fun success(response: Boolean) {
                        Log.d(LOG_TAG, "Catapush has been successfully initialized")
                    }

                    override fun failure(irrecoverableError: Throwable) {
                        Log.e(LOG_TAG, "Can't initialize Catapush!", irrecoverableError)
                    }
                })
    }

}