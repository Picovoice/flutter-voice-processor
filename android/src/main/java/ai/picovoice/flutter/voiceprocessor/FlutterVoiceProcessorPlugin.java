//
// Copyright 2020-2021 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

package ai.picovoice.flutter.voiceprocessor;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class FlutterVoiceProcessorPlugin
  implements FlutterPlugin, ActivityAware {

  private static final String LOG_TAG = "FlutterVoiceProcessorPlugin";

  private MethodChannel methodChannel;
  private EventChannel eventChannel;
  private EventChannel errorEventChannel;
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

    errorEventChannel =
      new EventChannel(
        pluginBinding.getBinaryMessenger(),
        "flutter_voice_processor_error_events"
      );
    errorEventChannel.setStreamHandler(voiceProcessorHandler);
  }

  @Override
  public void onDetachedFromActivity() {
    activityBinding.removeRequestPermissionsResultListener(
      voiceProcessorHandler
    );
    activityBinding = null;
    methodChannel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
    errorEventChannel.setStreamHandler(null);
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
