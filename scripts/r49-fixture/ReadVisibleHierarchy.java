package com.fluvi.r49.fixture;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Base64;
import android.util.Xml;
import android.view.accessibility.AccessibilityNodeInfo;

import org.xmlpull.v1.XmlSerializer;

import java.io.IOException;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;

/** Observe the disposable device without suspending the host's accessibility service. */
public final class ReadVisibleHierarchy extends Instrumentation {
    @Override
    public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        start();
    }

    @Override
    public void onStart() {
        Bundle result = new Bundle();
        try {
            UiAutomation automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            AccessibilityServiceInfo info = automation.getServiceInfo();
            info.flags |= AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
            automation.setServiceInfo(info);
            long deadline = SystemClock.uptimeMillis() + 2500;
            String xml;
            boolean hasLabels;
            do {
                StringWriter writer = new StringWriter();
                XmlSerializer serializer = Xml.newSerializer();
                serializer.setOutput(writer);
                serializer.startTag(null, "hierarchy");
                AccessibilityNodeInfo root = automation.getRootInActiveWindow();
                hasLabels = root != null && writeNode(root, serializer, 0);
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
