package com.fluvi.r49.fixture;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;

/** Drives WA's actual two/three-finger tutorial gestures in a disposable test. */
public final class FrameTutorialTouch extends Instrumentation {
    private Bundle arguments;

    @Override public void onCreate(Bundle arguments) {
        this.arguments = arguments;
        start();
    }

    @Override public void onStart() {
        Bundle output = new Bundle();
        try {
            int x = Integer.parseInt(arguments.getString("x"));
            int y = Integer.parseInt(arguments.getString("y"));
            int fingers = Integer.parseInt(arguments.getString("fingers"));
            if (fingers < 2 || fingers > 3) throw new IllegalArgumentException("fingers");
            MotionEvent.PointerProperties[] ids = new MotionEvent.PointerProperties[fingers];
            MotionEvent.PointerCoords[] positions = new MotionEvent.PointerCoords[fingers];
            for (int i = 0; i < fingers; i++) {
                ids[i] = new MotionEvent.PointerProperties();
                ids[i].id = i;
                ids[i].toolType = MotionEvent.TOOL_TYPE_FINGER;
                positions[i] = new MotionEvent.PointerCoords();
                positions[i].x = x + (i - 1) * 25;
                positions[i].y = y;
                positions[i].pressure = 1;
                positions[i].size = 1;
            }
            UiAutomation automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            long down = SystemClock.uptimeMillis();
            for (int i = 0; i < fingers; i++) {
                int action = i == 0 ? MotionEvent.ACTION_DOWN :
                        MotionEvent.ACTION_POINTER_DOWN | (i << MotionEvent.ACTION_POINTER_INDEX_SHIFT);
                inject(automation, down, i + 1, action, ids, positions);
            }
            SystemClock.sleep(110);
            for (int i = fingers - 1; i >= 0; i--) {
                int action = i == 0 ? MotionEvent.ACTION_UP :
                        MotionEvent.ACTION_POINTER_UP | (i << MotionEvent.ACTION_POINTER_INDEX_SHIFT);
                inject(automation, down, i + 1, action, ids, positions);
            }
            output.putString("gesture", "accepted");
            finish(Activity.RESULT_OK, output);
        } catch (Exception failure) {
            output.putString("error", failure.toString());
            finish(Activity.RESULT_CANCELED, output);
        }
    }

    private static void inject(UiAutomation automation, long down, int count, int action,
                               MotionEvent.PointerProperties[] ids, MotionEvent.PointerCoords[] positions) {
        MotionEvent event = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, count,
                ids, positions, 0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
        try {
            if (!automation.injectInputEvent(event, true)) throw new IllegalStateException("input rejected");
        } finally {
            event.recycle();
        }
    }
}
