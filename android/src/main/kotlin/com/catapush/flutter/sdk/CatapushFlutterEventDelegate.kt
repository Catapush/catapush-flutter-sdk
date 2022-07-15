package com.catapush.flutter.sdk

import android.content.Context
import com.catapush.library.exceptions.CatapushAuthenticationError
import com.catapush.library.exceptions.CatapushConnectionError
import com.catapush.library.exceptions.PushServicesException
import com.catapush.library.interfaces.ICatapushEventDelegate
import com.catapush.library.messages.CatapushMessage
import com.catapush.library.push.models.PushPlatformType
import com.google.android.gms.common.GoogleApiAvailability
import java.lang.ref.WeakReference
import java.lang.reflect.Modifier

object CatapushFlutterEventDelegate: ICatapushEventDelegate {

    private var contextRef: WeakReference<Context>? = null
    private var messagesDispatcher: IMessagesDispatchDelegate? = null
    private var statusDispatcher: IStatusDispatchDelegate? = null

    fun setContext(context: Context) {
        this.contextRef = WeakReference(context)
    }

    fun setMessagesDispatcher(messagesDispatcher: IMessagesDispatchDelegate) {
        this.messagesDispatcher = messagesDispatcher
    }

    fun setStatusDispatcher(statusDispatcher: IStatusDispatchDelegate) {
        this.statusDispatcher = statusDispatcher
    }

    override fun onDisconnected(error: CatapushConnectionError) {
        statusDispatcher?.dispatchConnectionStatus("disconnected")
    }

    override fun onMessageOpened(message: CatapushMessage) {
    }

    override fun onMessageOpenedConfirmed(message: CatapushMessage) {
    }

    override fun onMessageSent(message: CatapushMessage) {
        messagesDispatcher?.dispatchMessageSent(message)
    }

    override fun onMessageSentConfirmed(message: CatapushMessage) {
    }

    override fun onMessageReceived(message: CatapushMessage) {
        messagesDispatcher?.dispatchMessageReceived(message)
    }

    override fun onMessageReceivedConfirmed(message: CatapushMessage) {
    }

    override fun onRegistrationFailed(error: CatapushAuthenticationError) {
        CatapushAuthenticationError::class.java.declaredFields.firstOrNull {
            Modifier.isStatic(it.modifiers)
                    && it.type == Integer::class
                    && it.getInt(error) == error.reasonCode
        }?.also { statusDispatcher?.dispatchError(it.name, error.reasonCode) }
    }

    override fun onConnecting() {
        statusDispatcher?.dispatchConnectionStatus("connecting")
    }

    override fun onConnected() {
        statusDispatcher?.dispatchConnectionStatus("connected")
    }

    override fun onPushServicesError(e: PushServicesException) {
        if (PushPlatformType.GMS.name == e.platform && e.isUserResolvable) {
            // It's a GMS error and it's user resolvable: show a notification to the user
            val gmsAvailability = GoogleApiAvailability.getInstance()
            /*gmsAvailability.setDefaultNotificationChannelId(
                context, brandSupport.getNotificationChannelId(context)
            )*/
            contextRef?.get()?.also {
                gmsAvailability.showErrorNotification(it, e.errorCode)
            }
        }
    }

}