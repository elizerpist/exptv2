package com.fluvi.r49.fixture;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.view.InputDevice;
import android.view.MotionEvent;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Base64;
import android.util.Xml;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;

import org.xmlpull.v1.XmlSerializer;

import java.io.IOException;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;

/** Observe the disposable device without suspending the host's accessibility service. */
public final class ReadVisibleHierarchy extends Instrumentation {
    private boolean interactiveWindows;
    private Bundle parameters;
    @Override
    public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        parameters = arguments;
        interactiveWindows = "true".equals(arguments.getString("interactiveWindows"));
        start();
    }

    @Override
    public void onStart() {
        Bundle result = new Bundle();
        try {
            UiAutomation automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            if ("drag".equals(parameters.getString("action"))) {
                drag(automation);
                result.putString("gesture", "PASS");
                finish(Activity.RESULT_OK, result);
                return;
            }

            AccessibilityServiceInfo info = automation.getServiceInfo();
            info.flags |= AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
            if (interactiveWindows) info.flags |= AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;
            automation.setServiceInfo(info);
            long deadline = SystemClock.uptimeMillis() + 2500;
            String xml;
            boolean hasLabels;
            do {
                StringWriter writer = new StringWriter();
                XmlSerializer serializer = Xml.newSerializer();
                serializer.setOutput(writer);
                serializer.startTag(null, "hierarchy");
                if (interactiveWindows) {
                    hasLabels = false;
                    for (AccessibilityWindowInfo window : automation.getWindows()) {
                        AccessibilityNodeInfo root = window.getRoot();
                        if (root != null) hasLabels |= writeNode(root, serializer, 0);
                    }
                } else {
                    AccessibilityNodeInfo root = automation.getRootInActiveWindow();
                    hasLabels = root != null && writeNode(root, serializer, 0);
                }
                serializer.endTag(null, "hierarchy");
                serializer.flush();
                xml = writer.toString();
                if (!hasLabels) SystemClock.sleep(150);
            } while (!hasLabels && SystemClock.uptimeMillis() < deadline);
            result.putString("hierarchy", Base64.encodeToString(
                    xml.getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP));
            finish(Activity.RESULT_OK, result);
        } catch (Exception failure) {
            result.putString("error", failure.toString());
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private void drag(UiAutomation automation) {
        float startX = Float.parseFloat(parameters.getString("x"));
        float startY = Float.parseFloat(parameters.getString("y"));
        float endX = Float.parseFloat(parameters.getString("targetX"));
        float endY = Float.parseFloat(parameters.getString("targetY"));
        long down = SystemClock.uptimeMillis();
        inject(automation, down, MotionEvent.ACTION_DOWN, startX, startY);
        try {
            SystemClock.sleep(800);
            for (int i = 1; i <= 24; i++) {
                SystemClock.sleep(28);
                float progress = i / 24f;
                inject(automation, down, MotionEvent.ACTION_MOVE,
                        startX + (endX - startX) * progress, startY + (endY - startY) * progress);
            }
            SystemClock.sleep(200);
        } finally {
            inject(automation, down, MotionEvent.ACTION_UP, endX, endY);
        }
    }

    private static void inject(UiAutomation automation, long down, int action, float x, float y) {
        MotionEvent event = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, x, y, 0);
        try {
            event.setSource(InputDevice.SOURCE_TOUCHSCREEN);
            if (!automation.injectInputEvent(event, true)) {
                throw new IllegalStateException("Input injection failed for action " + action);
            }
        } finally {
            event.recycle();
        }
    }

    private static boolean writeNode(AccessibilityNodeInfo node, XmlSerializer xml, int depth) throws IOException {
        if (depth >= 30) return false;
        String text = string(node.getText());
        String description = string(node.getContentDescription());
        xml.startTag(null, "node");
        xml.attribute(null, "text", text);
        xml.attribute(null, "content-desc", description);
        xml.attribute(null, "package", string(node.getPackageName()));
        xml.attribute(null, "class", string(node.getClassName()));
        xml.attribute(null, "id", string(node.getViewIdResourceName()));
        xml.attribute(null, "clickable", Boolean.toString(node.isClickable()));
        xml.attribute(null, "visible", Boolean.toString(node.isVisibleToUser()));
        Rect rect = new Rect();
        node.getBoundsInScreen(rect);
        xml.attribute(null, "bounds", "[" + rect.left + "," + rect.top + "][" + rect.right + "," + rect.bottom + "]");
        boolean labelled = !text.isEmpty() || !description.isEmpty();
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) labelled |= writeNode(child, xml, depth + 1);
        }
        xml.endTag(null, "node");
        return labelled;
    }

    private static String string(CharSequence value) {
        return value == null ? "" : value.toString();
    }
}
