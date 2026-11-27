package com.fluvi.r49.fixture;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.os.SystemClock;
import android.os.Trace;
import android.util.Log;
import android.view.View;

/** A disposable launcher and an independent colored synchronization patch. */
public final class R52ReferenceActivity extends Activity {
    private Reference view;
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        view = new Reference();
        setContentView(view);
        update(getIntent());
    }
    @Override protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        update(intent);
    }
    private void update(Intent intent) {
        view.code = intent.getIntExtra("sync", 0);
        view.invalidate();
    }
    private final class Reference extends View {
        private final Paint paint = new Paint();
        int code;
        int last = -1;
        Reference() { super(R52ReferenceActivity.this); }
        @Override protected void onDraw(Canvas canvas) {
            canvas.drawColor(Color.rgb(15, 20, 27));
            paint.setColor(code == 1 ? Color.rgb(253, 27, 145)
                : code == 2 ? Color.rgb(18, 225, 149) : Color.rgb(23, 190, 235));
            canvas.drawRect(.06f * getWidth(), .10f * getHeight(),
                .27f * getWidth(), .25f * getHeight(), paint);
            if (code != last) {
                last = code;
                Trace.setCounter("fluvi.r52.reference", code);
                Trace.beginSection("FluviR52.referenceDraw");
                Log.i("FluviR52Witness", "sync=" + code +
                    " drawUp=" + SystemClock.uptimeMillis() +
                    " drawEl=" + SystemClock.elapsedRealtimeNanos());
                Trace.endSection();
            }
        }
    }
}
