//
// Copyright 2020-2023 Picovoice Inc.
//
// You may not use this file except in compliance with the license. A copy of the license is located in the "LICENSE"
// file accompanying this source.
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//

package ai.picovoice.flutter.voiceprocessor;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import ai.picovoice.android.voiceprocessor.VoiceProcessor;
import ai.picovoice.android.voiceprocessor.VoiceProcessorErrorListener;
import ai.picovoice.android.voiceprocessor.VoiceProcessorException;
import ai.picovoice.android.voiceprocessor.VoiceProcessorFrameListener;

import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class FlutterVoiceProcessorHandler
        implements
        MethodCallHandler,
        StreamHandler,
        PluginRegistry.RequestPermissionsResultListener {

    private static final String LOG_TAG = "FlutterVoiceProcessorPlugin";
    private static final int RECORD_AUDIO_REQUEST_CODE =
            FlutterVoiceProcessorHandler.class.hashCode();

    private final Activity activity;
    private final VoiceProcessor voiceProcessor;
    private final Handler eventHandler = new Handler(Looper.getMainLooper());
    private Result pendingPermissionResult;
    private Result pendingStartRecordResult;
    private Result pendingStopRecordResult;
    private EventSink frameEventSink;
    private final VoiceProcessorFrameListener frameListener = new VoiceProcessorFrameListener() {
        @Override
        public void onFrame(final short[] frame) {
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (frameEventSink != null) {
                                frameEventSink.success(frame);
                            }
                        }
                    }
            );
        }
    };
    private EventSink errorEventSink;
    private final VoiceProcessorErrorListener errorListener = new VoiceProcessorErrorListener() {
        @Override
        public void onError(VoiceProcessorException error) {
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (pendingStartRecordResult != null) {
                                pendingStartRecordResult.error(
                                        "PV_AUDIO_RECORDER_ERROR",
                                        "Unable to start audio recording: " + error,
                                        null
                                );
                                pendingStartRecordResult = null;
                            } else if (errorEventSink != null) {
                                errorEventSink.success("PV_AUDIO_RECORDER_ERROR: " + error);
                            }
                        }
                    }
            );
        }
    };

    FlutterVoiceProcessorHandler(Activity activity) {
        this.activity = activity;
        this.voiceProcessor = VoiceProcessor.getInstance();
    }

    void close() {
        stop();
        pendingPermissionResult = null;
        pendingStartRecordResult = null;
        pendingStopRecordResult = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "start":
                if (!(call.argument("frameLength") instanceof Integer) ||
                        !(call.argument("sampleRate") instanceof Integer)) {
                    result.error(
                            "PV_INVALID_ARGUMENT",
                            "Invalid argument provided to VoiceProcessor.start",
                            null
                    );
                    break;
                }

                final Integer frameLength = call.argument("frameLength");
                final Integer sampleRate = call.argument("sampleRate");
                pendingStartRecordResult = result;
                start(frameLength, sampleRate);
                break;
            case "stop":
                pendingStopRecordResult = result;
                stop();
                break;
            case "hasRecordAudioPermission":
                hasRecordAudioPermission(result);
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onListen(Object listener, EventSink eventSink) {
        if (listener != null) {
            String type = (String) listener;
            if (type.equals("frame")) {
                frameEventSink = eventSink;
            } else if (type.equals("error")) {
                errorEventSink = eventSink;
            }
        }
    }

    @Override
    public void onCancel(Object listener) {
        if (listener != null) {
            String type = (String) listener;
            if (type.equals("frame")) {
                frameEventSink = null;
            } else if (type.equals("error")) {
                errorEventSink = null;
            }
        }
    }

    public void start(final Integer frameLength, final Integer sampleRate) {
        try {
            voiceProcessor.addErrorListener(errorListener);
            voiceProcessor.addFrameListener(frameListener);
            voiceProcessor.start(frameLength, sampleRate);
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (pendingStartRecordResult != null) {
                                pendingStartRecordResult.success(true);
                                pendingStartRecordResult = null;
                            }
                        }
                    }
            );
        } catch (VoiceProcessorException e) {
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (pendingStartRecordResult != null) {
                                pendingStartRecordResult.error(
                                        "PV_AUDIO_RECORDER_ERROR",
                                        "Unable to start audio recording: " + e,
                                        null
                                );
                                pendingStartRecordResult = null;
                            } else if (errorEventSink != null) {
                                errorEventSink.success("PV_AUDIO_RECORDER_ERROR: " + e);
                            }
                        }
                    }
            );
        }
    }

    public void stop() {
        try {
            voiceProcessor.removeErrorListener(errorListener);
            voiceProcessor.removeFrameListener(frameListener);
            if (voiceProcessor.getNumFrameListeners() == 0) {
                voiceProcessor.stop();
            }
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (pendingStopRecordResult != null) {
                                pendingStopRecordResult.success(true);
                                pendingStopRecordResult = null;
                            }
                        }
                    }
            );
        } catch (VoiceProcessorException e) {
            eventHandler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            if (pendingStopRecordResult != null) {
                                pendingStopRecordResult.error(
                                        "PV_AUDIO_RECORDER_ERROR",
                                        "Unable to stop audio recording: " + e,
                                        null
                                );
                                pendingStopRecordResult = null;
                            } else if (errorEventSink != null) {
                                errorEventSink.success("PV_AUDIO_RECORDER_ERROR: " + e);
                            }
                        }
                    }
            );
        }
    }

    private void hasRecordAudioPermission(@NonNull Result result) {
        if (!voiceProcessor.hasRecordAudioPermission(activity)) {
            pendingPermissionResult = result;
            ActivityCompat.requestPermissions(
                    activity,
                    new String[]{Manifest.permission.RECORD_AUDIO},
                    RECORD_AUDIO_REQUEST_CODE
            );
        } else {
            result.success(true);
        }
    }

    @Override
    public boolean onRequestPermissionsResult(
            int requestCode,
            String[] permissions,
            int[] grantResults
    ) {
        if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
            if (pendingPermissionResult != null) {
                if (grantResults.length > 0 &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    pendingPermissionResult.success(true);
                } else {
                    pendingPermissionResult.success(false);
                }
                pendingPermissionResult = null;
                return true;
            }
        }

        return false;
    }
}
