package com.fluvi.r49.fixture;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.Activity;
import android.app.Instrumentation;
import android.app.KeyguardManager;
import android.content.Context;
import android.hardware.display.DisplayManager;
import android.os.PowerManager;
import android.view.Display;
import android.app.UiAutomation;
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
    private boolean stateWitness;
    @Override
    public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        stateWitness = "true".equals(arguments.getString("stateWitness"));
        interactiveWindows = "true".equals(arguments.getString("interactiveWindows"));
        start();
    }

    @Override
    public void onStart() {
        Bundle result = new Bundle();
        try {
            if (stateWitness) {
                Context context = getTargetContext();
                long startElapsed = SystemClock.elapsedRealtimeNanos();
                long startUp = SystemClock.uptimeMillis();
                Display display = context.getSystemService(DisplayManager.class).getDisplay(Display.DEFAULT_DISPLAY);
                int state = display == null ? -1 : display.getState();
                boolean interactive = context.getSystemService(PowerManager.class).isInteractive();
                boolean locked = context.getSystemService(KeyguardManager.class).isKeyguardLocked();
                result.putString("platform", "display=" + state + " interactive=" + interactive
                        + " locked=" + locked + " startUp=" + startUp + " endUp=" + SystemClock.uptimeMillis()
                        + " startEl=" + startElapsed + " endEl=" + SystemClock.elapsedRealtimeNanos());
                finish(Activity.RESULT_OK, result);
                return;
            }
            UiAutomation automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
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
