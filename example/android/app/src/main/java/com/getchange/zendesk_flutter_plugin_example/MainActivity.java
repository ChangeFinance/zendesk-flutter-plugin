package com.getchange.zendesk_flutter_plugin_example;

import android.os.Bundle;
//import io.flutter.app.FlutterActivity;
//import io.flutter.app.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends /*FlutterActivity*/ FlutterFragmentActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
  }
}
