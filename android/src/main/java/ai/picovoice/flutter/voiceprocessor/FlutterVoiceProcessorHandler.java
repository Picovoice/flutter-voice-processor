package ai.picovoice.flutter.voiceprocessor;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Process;
import android.util.Log;
import android.os.Handler;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.PluginRegistry;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

public class FlutterVoiceProcessorHandler implements MethodCallHandler, StreamHandler,
PluginRegistry.RequestPermissionsResultListener {
  private static final String LOG_TAG = "FlutterVoiceProcessorPlugin";      
  private static final int RECORD_AUDIO_REQUEST_CODE = FlutterVoiceProcessorHandler.class.hashCode();

  private final AtomicBoolean started = new AtomicBoolean(false);
  private final AtomicBoolean stop = new AtomicBoolean(false);
  private final AtomicBoolean stopped = new AtomicBoolean(false);
  
  private final Activity activity;
  private final Handler eventHandler = new Handler();    
  private Result pendingPermissionResult;
  private EventSink bufferEventSink;

  FlutterVoiceProcessorHandler(Activity activity) {    
    this.activity = activity;
  }

  void close() {    
    stop();
    pendingPermissionResult = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {    
    switch (call.method) {
      case "start" :
        final Integer frameLength = call.argument("frameLength");
        final Integer sampleRate = call.argument("sampleRate");
        final boolean didStart = start(frameLength, sampleRate);
        result.success(didStart);
        break;
      case "stop" :
        final boolean didStop = stop();
        result.success(didStop);
        break;
      case "hasRecordAudioPermission" :
        checkRecordAudioPermission(result);
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onListen(Object listener, EventSink eventSink) {
    bufferEventSink = eventSink;
  }

  @Override
  public void onCancel(Object listener) {
    bufferEventSink = null;
  }
  
  
  public boolean start(final Integer frameSize, final Integer sampleRate) {
    
    if (started.get()) {
      return true;
    }
    
    Executors.newSingleThreadExecutor().submit(new Callable<Void>() {
      @Override
      public Void call() {
        android.os.Process.setThreadPriority(Process.THREAD_PRIORITY_URGENT_AUDIO);
        read(frameSize, sampleRate);
        return null;
      }
    });

    while(!started.get()){
      try {
        Thread.sleep(10);
      } catch (InterruptedException e) {
        Log.e(LOG_TAG, e.toString());        
      }
    }

    return true;
  }

  public boolean stop() {
    if (!started.get()) {
      return true;
    }

    stop.set(true);

    while (!stopped.get()) {
      try {
        Thread.sleep(10);
      } catch (InterruptedException e) {
        Log.e(LOG_TAG, e.toString());        
      }
    }

    started.set(false);
    stop.set(false);
    stopped.set(false);    
    return true;
  }
  
  private void checkRecordAudioPermission(@NonNull Result result) {
    boolean isPermissionGranted = ActivityCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED;
    if (!isPermissionGranted) {
      pendingPermissionResult = result;
      ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.RECORD_AUDIO}, RECORD_AUDIO_REQUEST_CODE);
    } else {
      result.success(true);
    }
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
      if (pendingPermissionResult != null) {
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          pendingPermissionResult.success(true);
        } else {
          pendingPermissionResult.error("-2", "Permission denied", null);
        }
        pendingPermissionResult = null;
        return true;
      }
    }

    return false;
  }

  private void read(final Integer frameSize, final Integer sampleRate) {
    
    final int minBufferSize = AudioRecord.getMinBufferSize(
      sampleRate,
      AudioFormat.CHANNEL_IN_MONO,
      AudioFormat.ENCODING_PCM_16BIT);
    final int bufferSize = Math.max(sampleRate / 2, minBufferSize);
    final short[] buffer = new short[frameSize];    
    AudioRecord audioRecord = null;
    try {
      audioRecord = new AudioRecord(
        MediaRecorder.AudioSource.MIC,
        sampleRate,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_16BIT,
        bufferSize);

      audioRecord.startRecording();
      boolean firstBuffer = true;      
      while (!stop.get()) {
        if (audioRecord.read(buffer, 0, buffer.length) == buffer.length) {          
          if(firstBuffer){            
            started.set(true);
            firstBuffer = false;
          }
          
          final ArrayList<Short> bufferObj = new ArrayList();
          for (int i = 0; i < buffer.length; i++)
            bufferObj.add(buffer[i]);

          // send buffer event                      
          eventHandler.post(new Runnable() {
            @Override
            public void run() {
              if(bufferEventSink != null){
                bufferEventSink.success(bufferObj);
              }
            }
          });                  
        }
      }

      audioRecord.stop();
    } catch (IllegalArgumentException | IllegalStateException e) {      
      Log.e(LOG_TAG, e.toString());      
    } finally {
      if (audioRecord != null) {
        audioRecord.release();
      }

      stopped.set(true);
    }
  }
}