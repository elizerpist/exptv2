package com.fluvi.r53.reference;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Build;
import android.os.Bundle;
import android.os.SystemClock;
import android.os.Trace;
import android.util.Log;
import android.view.View;

/** Opaque foreground reference. A regular launcher start always uses the neutral pattern. */
public final class ReferenceActivity extends Activity {
    private static final int BACKGROUND = Color.rgb(18, 25, 37);
    private static final int[][] COLORS = {
        {Color.rgb(252, 229, 93), Color.rgb(41, 231, 232)},
        {Color.rgb(252, 106, 36), Color.rgb(154, 248, 79)},
        {Color.rgb(250, 104, 166), Color.rgb(115, 169, 255)},
    };
    private ReferenceView view;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if (Build.VERSION.SDK_INT >= 30) {
            getWindow().setDecorFitsSystemWindows(false);
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        }
        view = new ReferenceView();
        setContentView(view);
        update(getIntent());
    }

    @Override protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        update(intent);
    }

    private void update(Intent intent) {
        int value = intent.getIntExtra("sync", 0);
        view.phase = value >= 0 && value < COLORS.length ? value : 0;
        view.invalidate();
    }

    private final class ReferenceView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private int phase;
        private int last = -1;

        ReferenceView() {
            super(ReferenceActivity.this);
            setContentDescription("Fluvi feloldási referencia");
        }

        @Override protected void onDraw(Canvas canvas) {
            canvas.drawColor(BACKGROUND);
            drawPattern(canvas, .065f, .215f, COLORS[phase][0], new String[]{"1000", "1000", "1110"});
            drawPattern(canvas, .795f, .725f, COLORS[phase][1], new String[]{"0110", "0001", "1111"});

            paint.setColor(Color.WHITE);
            paint.setTextAlign(Paint.Align.CENTER);
            paint.setTextSize(.039f * getWidth());
            canvas.drawText("Fluvi feloldási referencia", getWidth() * .5f, getHeight() * .36f, paint);

            if (phase != last) {
                last = phase;
                Trace.setCounter("fluvi.r53.reference", phase);
                Trace.beginSection("FluviR53.referenceDraw");
                long upBefore = SystemClock.uptimeMillis();
                long elapsed = SystemClock.elapsedRealtimeNanos();
                long upAfter = SystemClock.uptimeMillis();
                Log.i("FluviR53Reference", "source=" + BuildIdentity.SOURCE
                    + " phase=" + phase + " task=" + getTaskId()
                    + " display=" + getDisplay().getDisplayId() + " extent=" + getWidth() + "x" + getHeight()
                    + " upBefore=" + upBefore + " elapsedNs=" + elapsed + " upAfter=" + upAfter);
                Trace.endSection();
            }
        }

        private void drawPattern(Canvas canvas, float x, float y, int tint, String[] pattern) {
            paint.setColor(tint);
            float cellX = .028f * getWidth();
            float cellY = .013f * getHeight();
            for (int row = 0; row < pattern.length; row++) {
                for (int column = 0; column < pattern[row].length(); column++) {
                    if (pattern[row].charAt(column) != '1') continue;
                    float left = x * getWidth() + column * cellX;
                    float top = y * getHeight() + row * cellY;
                    canvas.drawRect(left, top, left + cellX, top + cellY, paint);
                }
            }
        }
    }
}
