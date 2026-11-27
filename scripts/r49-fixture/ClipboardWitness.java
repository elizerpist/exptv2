package com.fluvi.r49.fixture;

import android.app.Activity;
import android.os.Bundle;
import android.text.InputType;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;

import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

/** Foreground paste witness for synthetic, disposable-device captures. */
public final class ClipboardWitness extends Activity {
    private EditText field;
    private boolean pasted;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        Button paste = new Button(this);
        paste.setText("Paste capture");
        field = new EditText(this);
        field.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        field.setShowSoftInputOnFocus(false);
        content.addView(paste);
        content.addView(field);
        setContentView(content);
        paste.setOnClickListener(view -> paste());
    }

    @Override
    public void onWindowFocusChanged(boolean focused) {
        super.onWindowFocusChanged(focused);
        if (focused && getIntent().getBooleanExtra("paste", false) && !pasted) {
            pasted = true;
            field.post(this::paste);
        }
    }

    private void paste() {
        field.requestFocus();
        field.setText("");
        if (!field.onTextContextMenuItem(android.R.id.paste)) return;
        try (FileOutputStream out = openFileOutput("paste.txt", MODE_PRIVATE)) {
            out.write(field.getText().toString().getBytes(StandardCharsets.UTF_8));
        } catch (IOException failure) {
            throw new IllegalStateException(failure);
        }
    }
}
