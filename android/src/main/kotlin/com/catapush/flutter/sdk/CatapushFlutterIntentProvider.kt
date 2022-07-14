package com.catapush.flutter.sdk

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.catapush.library.interfaces.IIntentProvider
import com.catapush.library.messages.CatapushMessage

class CatapushFlutterIntentProvider(private val targetActivityClass: Class<out Activity>): IIntentProvider {

    companion object {
        fun handleIntent(intent: Intent) {
            val entity = intent.data?.authority
            val id =  intent.data?.lastPathSegment
            if (intent.scheme == "catapush" && entity == "messages" && !id.isNullOrBlank()) {
                intent.getParcelableExtra<CatapushMessage>("message")?.apply {
                    CatapushFlutterSdkPlugin.handleNotificationTapped(this)
                }
            }
        }
    }

    override fun getIntentForMessage(
        message: CatapushMessage,
        context: Context
    ): PendingIntent {
        val intent = Intent(
            context,
            targetActivityClass
        ).apply {
            data = Uri.parse("catapush://messages/${message.id()}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("message", message)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_ONE_SHOT
        return PendingIntent.getActivity(context, 0, intent, piFlags)
    }

}