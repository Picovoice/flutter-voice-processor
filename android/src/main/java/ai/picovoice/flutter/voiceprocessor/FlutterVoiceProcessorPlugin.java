package ai.picovoice.flutter.voiceprocessor;

import android.util.Log;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class FlutterVoiceProcessorPlugin
  implements FlutterPlugin, ActivityAware {

  private static final String LOG_TAG = "FlutterVoiceProcessorPlugin";

  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private FlutterVoiceProcessorHandler voiceProcessorHandler;
  private FlutterPluginBinding pluginBinding;
  private ActivityPluginBinding activityBinding;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    activityBinding = binding;
    voiceProcessorHandler =
      new FlutterVoiceProcessorHandler(binding.getActivity());
    activityBinding.addRequestPermissionsResultListener(voiceProcessorHandler);

    methodChannel =
      new MethodChannel(
        pluginBinding.getBinaryMessenger(),
        "flutter_voice_processor_methods"
      );
    methodChannel.setMethodCallHandler(voiceProcessorHandler);

    eventChannel =
      new EventChannel(
        pluginBinding.getBinaryMessenger(),
        "flutter_voice_processor_events"
      );
    eventChannel.setStreamHandler(voiceProcessorHandler);
  }

  @Override
  public void onDetachedFromActivity() {
    activityBinding.removeRequestPermissionsResultListener(
      voiceProcessorHandler
    );
    activityBinding = null;
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    voiceProcessorHandler = null;
    methodChannel = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
    ActivityPluginBinding binding
  ) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }
}
