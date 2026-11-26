package com.fluvi.r46receiver;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/** Separate package: the test pastes through Android into a real text field. */
public final class PasteActivity extends Activity {
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        EditText field = new EditText(this);
        field.setContentDescription("R46 paste field");
        field.setSingleLine(false);
        field.requestFocus();
        TextView status = new TextView(this);
        status.setText("Awaiting paste");
        Button button = new Button(this);
        button.setText("Paste report");
        button.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View ignored) {
                try {
                    field.requestFocus();
                    if (!field.onTextContextMenuItem(android.R.id.paste)) throw new IllegalStateException("paste rejected");
                    byte[] bytes = field.getText().toString().getBytes(StandardCharsets.UTF_8);
                    try (FileOutputStream out = new FileOutputStream(new File(getFilesDir(), "report.txt"))) {
                        out.write(bytes); out.getFD().sync();
                    }
                    StringBuilder hash = new StringBuilder();
                    for (byte b : MessageDigest.getInstance("SHA-256").digest(bytes)) hash.append(String.format("%02x", b & 255));
                    status.setText("PASTED " + bytes.length + " " + hash);
                } catch (Exception error) { status.setText("PASTE_FAILED " + error.getClass().getSimpleName()); }
            }
        });
        root.addView(button);
        root.addView(status);
        root.addView(field);
        setContentView(root);
    }
}
