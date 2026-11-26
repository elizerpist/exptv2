package com.fluvi.r46receiver;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.graphics.Rect;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Xml;
import android.view.accessibility.AccessibilityNodeInfo;
import java.io.File;
import java.io.FileOutputStream;
import org.xmlpull.v1.XmlSerializer;

/** Read the real semantics without suppressing the service under test. */
public final class TreeDumpInstrumentation extends Instrumentation {
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }

    @Override public void onStart() {
        try {
            UiAutomation automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            AccessibilityNodeInfo root = null;
            for (int i = 0; i < 20 && root == null; i++) {
                root = automation.getRootInActiveWindow();
                if (root == null) SystemClock.sleep(100);
            }
            if (root == null) throw new IllegalStateException("active tree unavailable");
            try (FileOutputStream out = new FileOutputStream(new File(getTargetContext().getFilesDir(), "tree.xml"))) {
                XmlSerializer xml = Xml.newSerializer();
                xml.setOutput(out, "UTF-8");
                xml.startDocument("UTF-8", true);
                xml.startTag(null, "hierarchy");
                writeNode(xml, root, 0, new int[] {0});
                xml.endTag(null, "hierarchy");
                xml.endDocument();
            }
            finish(Activity.RESULT_OK, Bundle.EMPTY);
        } catch (Exception error) {
            Bundle failure = new Bundle();
            failure.putString("error", error.toString());
            finish(Activity.RESULT_CANCELED, failure);
        }
    }

    private static void writeNode(XmlSerializer xml, AccessibilityNodeInfo node, int depth, int[] count) throws Exception {
        if (depth > 60 || ++count[0] > 5000) return;
        Rect bounds = new Rect();
        node.getBoundsInScreen(bounds);
        xml.startTag(null, "node");
        CharSequence text = node.getText(), description = node.getContentDescription();
        xml.attribute(null, "text", text == null ? "" : text.toString());
        xml.attribute(null, "content-desc", description == null ? "" : description.toString());
        xml.attribute(null, "clickable", Boolean.toString(node.isClickable()));
        xml.attribute(null, "enabled", Boolean.toString(node.isEnabled()));
        xml.attribute(null, "selected", Boolean.toString(node.isSelected()));
        xml.attribute(null, "bounds", "[" + bounds.left + "," + bounds.top + "][" + bounds.right + "," + bounds.bottom + "]");
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo child = node.getChild(i);
            if (child != null) { try { writeNode(xml, child, depth + 1, count); } finally { child.recycle(); } }
        }
        xml.endTag(null, "node");
    }
}
