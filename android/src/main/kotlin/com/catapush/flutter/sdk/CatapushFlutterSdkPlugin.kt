package com.catapush.flutter.sdk

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.net.Uri
import androidx.annotation.NonNull
import com.catapush.library.Catapush
import com.catapush.library.interfaces.Callback
import com.catapush.library.interfaces.RecoverableErrorCallback
import com.catapush.library.messages.CatapushMessage
import com.catapush.library.push.models.PushPluginType
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference


class CatapushFlutterSdkPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
  IMessagesDispatchDelegate, IStatusDispatchDelegate {

  companion object {
    private val tappedMessagesQueue = ArrayList<CatapushMessage>()

    private var instanceRef: WeakReference<CatapushFlutterSdkPlugin>? = null
      set(value) {
        field = value
        tappedMessagesQueue.forEach(::handleNotificationTapped)
        tappedMessagesQueue.clear()
      }

    fun handleNotificationTapped(message: CatapushMessage) {
      val instance = instanceRef?.get()
      if (instance != null) {
        instance.dispatchNotificationTapped(message)
      } else {
        tappedMessagesQueue.add(message)
      }
    }
  }

  private var appContext: Context? = null
  private var activity: Activity? = null

  private lateinit var channel : MethodChannel

  init {
    try {
      val pluginType = Catapush::class.java.getDeclaredField("pluginType")
      pluginType.isAccessible = true
      pluginType[Catapush.getInstance() as Catapush] = PushPluginType.Flutter
    } catch (e: Exception) {
      Log.e("CatapushPlugin", "Can't initialize plugin instance", e)
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    CatapushFlutterEventDelegate.setContext(flutterPluginBinding.applicationContext)
    CatapushFlutterEventDelegate.setMessagesDispatcher(this)
    CatapushFlutterEventDelegate.setStatusDispatcher(this)
    appContext = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "Catapush").also {
      it.setMethodCallHandler(this)
    }
    instanceRef = WeakReference(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  @SuppressLint("RestrictedApi")
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    if (call.method == "Catapush#init") {
      if ((Catapush.getInstance() as Catapush).isInitialized.blockingFirst(false)) {
        result.success(mapOf("result" to true))
      } else {
        result.error("bad state", "${call.method} please invoke Catapush.getInstance().init(...) in the Application.onCreate(...) callback of your Android native app", null)
      }

    } else if (call.method == "Catapush#setUser") {
      val identifier = call.argument("identifier") as String?
      val password = call.argument("password") as String?
      if (!identifier.isNullOrBlank() && !password.isNullOrBlank()) {
        Catapush.getInstance().setUser(identifier, password)
        result.success(mapOf("result" to true))
      } else {
        result.error("bad args", "${call.method} arguments:" + call.arguments.toString(), null)
      }

    } else if (call.method == "Catapush#start") {
      Catapush.getInstance().start(object : RecoverableErrorCallback<Boolean> {
        override fun success(response: Boolean) {
          result.success(mapOf("result" to true))
        }
        override fun warning(recoverableError: Throwable) {
          Log.w("CatapushFlutterSdkPlugin", "Recoverable error", recoverableError)
        }
        override fun failure(irrecoverableError: Throwable) {
          result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
        }
      })

    } else if (call.method == "Catapush#stop") {
      Catapush.getInstance().stop(object : Callback<Boolean> {
        override fun success(response: Boolean) {
          result.success(mapOf("result" to true))
        }
        override fun failure(irrecoverableError: Throwable) {
          result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
        }
      })

    } else if (call.method == "Catapush#sendMessage") {
      val message = call.argument("message") as Map<String, Any>?
      val text = message?.get("text") as String?
      val channel = message?.get("channel") as String?
      val replyTo = message?.get("replyTo") as String?
      val file = message?.get("file") as Map<*, *>?
      if (!text.isNullOrBlank() && (file == null || !(file["url"] as String?).isNullOrBlank())) {
        if (file != null) {
          val uri = (file["url"] as String).let {
            if (it.startsWith("/")) {
              Uri.parse("file://${it}")
            } else {
              Uri.parse(it)
            }
          }
          //val mimeType = file["mimeType"] as String?
          Catapush.getInstance().sendFile(uri, text, channel, replyTo, object : Callback<Boolean> {
            override fun success(response: Boolean) {
              result.success(mapOf("result" to true))
            }
            override fun failure(irrecoverableError: Throwable) {
              result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
            }
          })
        } else {
          Catapush.getInstance().sendMessage(text, channel, replyTo, object : Callback<Boolean> {
            override fun success(response: Boolean) {
              result.success(mapOf("result" to true))
            }
            override fun failure(irrecoverableError: Throwable) {
              result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
            }
          })
        }
      } else {
        result.error("bad args", "${call.method} arguments:" + call.arguments.toString(), null)
      }

    } else if (call.method == "Catapush#getAllMessages") {
      Catapush.getInstance().getMessagesAsList(object : Callback<List<CatapushMessage>> {
        override fun success(response: List<CatapushMessage>) {
          result.success(mapOf("result" to response.toMap()))
        }
        override fun failure(irrecoverableError: Throwable) {
          result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
        }
      })

    } else if (call.method == "Catapush#enableLog") {
      val enableLog = call.argument("enableLog") as Boolean?
      if (enableLog != null) {
        if (enableLog)
          Catapush.getInstance().enableLog()
        else
          Catapush.getInstance().disableLog()
        result.success(mapOf("result" to true))
      } else {
        result.error("bad args", "${call.method} arguments:" + call.arguments.toString(), null)
      }

    } else if (call.method == "Catapush#logout") {
      Catapush.getInstance().logout(object : Callback<Boolean> {
        override fun success(response: Boolean) {
          result.success(mapOf("result" to true))
        }
        override fun failure(irrecoverableError: Throwable) {
          result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
        }
      })

    } else if (call.method == "Catapush#sendMessageReadNotificationWithId") {
      val id = call.argument("id") as String?
      if (id != null) {
        Catapush.getInstance().notifyMessageOpened(id)
        result.success(mapOf("result" to true))
      } else {
        result.error("bad args", "${call.method} arguments:" + call.arguments.toString(), null)
      }

    } else if (call.method == "Catapush#getAttachmentUrlForMessage") {
      val id = call.argument("id") as String?
      if (id != null) {
        Catapush.getInstance().getMessageById(id, object : Callback<CatapushMessage> {
          override fun success(response: CatapushMessage) {
            response.file().also {
              when {
                it != null && response.isIn -> {
                  result.success(mapOf(
                    "url" to it.remoteUri(),
                    "mimeType" to it.type()
                  ))
                }
                it != null && !response.isIn -> {
                  result.success(mapOf(
                    "url" to it.localUri()?.replaceFirst("file:///", "/"),
                    "mimeType" to it.type()
                  ))
                }
                else -> {
                  result.error("op failed", "${call.method} unexpected CatapushMessage state or format", null)
                }
              }
            }
          }
          override fun failure(irrecoverableError: Throwable) {
            result.error("op failed", "${call.method} ${irrecoverableError.localizedMessage}", null)
          }
        })
      } else {
        result.error("bad args", "${call.method} arguments:" + call.arguments.toString(), null)
      }

    } else if (call.method == "Catapush#resumeNotifications") {
      Catapush.getInstance().resumeNotifications()
      result.success(null)

    } else if (call.method == "Catapush#pauseNotifications") {
      Catapush.getInstance().pauseNotifications()
      result.success(null)

    } else if (call.method == "Catapush#enableNotifications") {
      Catapush.getInstance().enableNotifications()
      result.success(null)

    } else if (call.method == "Catapush#disableNotifications") {
      Catapush.getInstance().disableNotifications()
      result.success(null)

    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun dispatchMessageReceived(message: CatapushMessage) {
    activity?.runOnUiThread {
      channel.invokeMethod("Catapush#catapushMessageReceived", mapOf("message" to message.toMap()))
    }
  }

  override fun dispatchMessageSent(message: CatapushMessage) {
    activity?.runOnUiThread {
      channel.invokeMethod("Catapush#catapushMessageSent", mapOf("message" to message.toMap()))
    }
  }

  override fun dispatchNotificationTapped(message: CatapushMessage) {
    activity?.runOnUiThread {
      channel.invokeMethod("Catapush#catapushNotificationTapped", mapOf("message" to message.toMap()))
    }
  }

  override fun dispatchConnectionStatus(status: String) {
    activity?.runOnUiThread {
      channel.invokeMethod("Catapush#catapushStateChanged", mapOf("status" to status))
    }
  }

  override fun dispatchError(event: String, code: Int) {
    activity?.runOnUiThread {
      channel.invokeMethod("Catapush#catapushHandleError", mapOf("event" to event, "code" to code))
    }
  }

  private fun List<CatapushMessage>.toMap() : List<Map<String, Any?>> {
    return this.map { it.toMap() }
  }

  private fun CatapushMessage.toMap() : Map<String, Any?> {
    return mapOf(
      "messageId" to this.id(),
      "body" to this.body(),
      "sender" to this.sender(),
      "channel" to this.channel(),
      "optionalData" to this.data(),
      "replyToId" to this.originalMessageId(),
      "state" to this.state(),
      "sentTime" to this.sentTime(),
      "readTime" to this.readTime(),
      "hasAttachment" to (this.file() != null),
    )
  }

}