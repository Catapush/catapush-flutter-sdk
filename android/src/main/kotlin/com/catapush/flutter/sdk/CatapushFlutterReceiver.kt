package com.catapush.flutter.sdk

import android.content.Context
import com.catapush.library.CatapushTwoWayReceiver
import com.catapush.library.exceptions.CatapushAuthenticationError
import com.catapush.library.exceptions.PushServicesException
import com.catapush.library.messages.CatapushMessage
import com.catapush.library.push.models.PushPlatformType
import com.google.android.gms.common.GoogleApiAvailability
import java.lang.reflect.Modifier

class CatapushFlutterReceiver: CatapushTwoWayReceiver() {

    companion object {
        private var messagesDispatcher: IMessagesDispatchDelegate? = null
        private var statusDispatcher: IStatusDispatchDelegate? = null

        fun setMessagesDispatcher(messagesDispatcher: IMessagesDispatchDelegate) {
            Companion.messagesDispatcher = messagesDispatcher
        }

        fun setStatusDispatcher(statusDispatcher: IStatusDispatchDelegate) {
            Companion.statusDispatcher = statusDispatcher
        }
    }

    override fun onDisconnected(errorCode: Int, context: Context) {
        statusDispatcher?.dispatchConnectionStatus("disconnected")
    }

    override fun onMessageOpened(message: CatapushMessage, context: Context) {
        // TODO
    }

    override fun onMessageOpenedConfirmed(message: CatapushMessage, context: Context) {
        // TODO
    }

    override fun onMessageSent(message: CatapushMessage, context: Context) {
        messagesDispatcher?.dispatchMessageSent(message)
    }

    override fun onMessageSentConfirmed(message: CatapushMessage, context: Context) {
        // TODO
    }

    override fun onMessageReceived(message: CatapushMessage, context: Context) {
        messagesDispatcher?.dispatchMessageReceived(message)
    }

    override fun onRegistrationFailed(error: CatapushAuthenticationError, context: Context) {
        CatapushAuthenticationError::class.java.declaredFields.firstOrNull {
            Modifier.isStatic(it.modifiers)
                    && it.type == Integer::class
                    && it.getInt(error) == error.reasonCode
        }?.also { statusDispatcher?.dispatchError(it.name, error.reasonCode) }
    }

    override fun onConnecting(context: Context) {
        statusDispatcher?.dispatchConnectionStatus("connecting")
    }

    override fun onConnected(context: Context) {
        statusDispatcher?.dispatchConnectionStatus("connected")
    }

    override fun onPushServicesError(e: PushServicesException, context: Context) {
        // TODO
        if (PushPlatformType.GMS.name == e.platform && e.isUserResolvable) {
            // It's a GMS error and it's user resolvable: show a notification to the user
            val gmsAvailability = GoogleApiAvailability.getInstance()
            /*gmsAvailability.setDefaultNotificationChannelId(
                context, brandSupport.getNotificationChannelId(context)
            )*/
            gmsAvailability.showErrorNotification(context, e.errorCode)
        }
    }

}