package com.catapush.flutter.sdk.example

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.multidex.MultiDex
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

        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager?
        if (nm != null) {
            val channelName = getString(R.string.notifications_channel_name)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                var channel = nm.getNotificationChannel(NOTIFICATION_CHANNEL_ID)
                val shouldCreateOrUpdate =
                    channel == null || !channelName.contentEquals(channel.name)
                if (shouldCreateOrUpdate) {
                    if (channel == null) {
                        channel = NotificationChannel(
                            NOTIFICATION_CHANNEL_ID,
                            channelName,
                            NotificationManager.IMPORTANCE_HIGH
                        )
                        channel.enableVibration(true)
                        channel.vibrationPattern = longArrayOf(100, 200, 100, 300)
                        channel.enableLights(true)
                        channel.lightColor = notificationColor
                        if (notificationSound != null) {
                            val audioAttributes = AudioAttributes.Builder()
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
                                .build()
                            channel.setSound(notificationSound, audioAttributes)
                        }
                    }
                    nm.createNotificationChannel(channel)
                }
            }
        }

        Catapush.getInstance()
            .setNotificationIntent(object : IIntentProvider {
                override fun getIntentForMessage(
                    message: CatapushMessage,
                    context: Context
                ): PendingIntent {
                    val intent = Intent(
                        context,
                        MainActivity::class.java
                    )
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                        PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_ONE_SHOT
                    return PendingIntent.getActivity(context, 0, intent, piFlags)
                }
            })
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
            .init(this, NOTIFICATION_CHANNEL_ID,
                listOf(CatapushGms),
                object : Callback<Boolean> {
                    override fun success(response: Boolean) {
                        Log.d(LOG_TAG, "Catapush has been successfully initialized")
                        val template = NotificationTemplate.builder()
                            .swipeToDismissEnabled(true)
                            .title(this@App.getString(R.string.app_name))
                            .vibrationEnabled(true)
                            .vibrationPattern(longArrayOf(100, 200, 100, 300))
                            .soundEnabled(true)
                            .soundResourceUri(notificationSound)
                            .circleColor(notificationColor)
                            .modalNotificationThemeId(this@App, R.style.DialogTheme)
                            .iconId(R.drawable.ic_stat_notify)
                            .useAttachmentPreviewAsLargeIcon(true)
                            .modalIconId(R.mipmap.ic_launcher)
                            .ledEnabled(true)
                            .ledColor(notificationColor)
                            .ledOnMS(2000)
                            .ledOffMS(1000)
                            .build()
                        Catapush.getInstance().setNotificationTemplate(template)
                    }

                    override fun failure(irrecoverableError: Throwable) {
                        Log.e(LOG_TAG, "Can't initialize Catapush!", irrecoverableError)
                    }
                })
    }

}