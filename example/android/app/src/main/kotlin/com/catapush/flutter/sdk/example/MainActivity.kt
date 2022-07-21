package com.catapush.flutter.sdk.example

import android.content.Intent
import android.os.Bundle
import com.catapush.flutter.sdk.CatapushFlutterIntentProvider
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CatapushFlutterIntentProvider.handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        CatapushFlutterIntentProvider.handleIntent(intent)
    }

}
