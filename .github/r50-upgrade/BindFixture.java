package com.fluvi.r50.updatefixture;

import android.app.Activity;
import android.app.Instrumentation;
import android.appwidget.AppWidgetHost;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import java.io.File;
import java.io.FileOutputStream;
import java.util.Arrays;
import org.json.JSONArray;
import org.json.JSONObject;

public final class BindFixture extends Instrumentation {
    private Bundle args;

    @Override public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        args = arguments;
        start();
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            Context context = getTargetContext();
            AppWidgetHost wa = new AppWidgetHost(context, 1003);
            AppWidgetHost home = new AppWidgetHost(context, 7222);
            AppWidgetManager widgets = AppWidgetManager.getInstance(context);
            if ("seed".equals(args.getString("phase"))) {
                int active = bind(context, wa, widgets, "orb.FluviHeaderOrbWidgetProvider");
                int obsolete = bind(context, wa, widgets, "financial.FluviFinancialSnapshotWidgetProvider");
                int foreign = bind(context, home, widgets, "orb.FluviOrbWidgetProvider");
                JSONArray recorded = new JSONArray();
                for (int id : new int[]{active, obsolete, foreign}) {
                    JSONObject widget = new JSONObject();
                    widget.put("id", id);
                    widget.put("type", "WIDGET");
                    recorded.put(widget);
                }
                prefs(context, "com.fluvi.app_preferences").edit()
                    .putBoolean("widget_frame_enabled", false)
                    .putString("current_widgets", recorded.toString()).commit();
                prefs(context, "fluvi_runtime_monitoring").edit()
                    .putBoolean("foregroundRequested", false)
                    .putBoolean("backgroundRequested", true).commit();
                prefs(context, "fluvi_home_orb_configurations").edit()
                    .putString("r50UpgradeSentinel", "home-" + foreign).commit();
                prefs(context, "fluvi_financial_snapshot_widget").edit()
                    .putString("r50UpgradeSentinel", "widget-data").commit();
                new File(context.getNoBackupFilesDir(), "header-orb-sharing-v1").createNewFile();
                try (FileOutputStream frames = new FileOutputStream(
                            new File(context.getNoBackupFilesDir(), "header-orb-frames-v1"))) {
                    frames.write(new byte[]{0, 0, 0, 1});
                }
                result.putInt("active", active);
                result.putInt("obsolete", obsolete);
                result.putInt("foreign", foreign);
            } else {
                int active = Integer.parseInt(args.getString("active"));
                int obsolete = Integer.parseInt(args.getString("obsolete"));
                int foreign = Integer.parseInt(args.getString("foreign"));
                SharedPreferences state = prefs(context, "fluvi_balance_orb");
                require(state.getBoolean("migrated", false), "migration recorded");
                require(!state.getBoolean("intended", true), "old disabled frame stayed dormant");
                require(state.getInt("active", -1) == active, "exact fixed ID persisted");
                require(Arrays.equals(wa.getAppWidgetIds(), new int[]{active}), "only the obsolete owned ID removed");
                require(widgets.getAppWidgetInfo(obsolete) == null, "obsolete native record removed");
                require(Arrays.equals(home.getAppWidgetIds(), new int[]{foreign}), "other host unchanged");
                require(prefs(context, "fluvi_home_orb_configurations")
                    .getString("r50UpgradeSentinel", "").equals("home-" + foreign), "home config survives");
                require(prefs(context, "fluvi_financial_snapshot_widget")
                    .getString("r50UpgradeSentinel", "").equals("widget-data"), "finance widget config survives");
                require(!prefs(context, "fluvi_runtime_monitoring").getBoolean("foregroundRequested", true), "FG stays off");
                require(prefs(context, "fluvi_runtime_monitoring").getBoolean("backgroundRequested", false), "BG stays on");
                for (String path : new String[]{"header-orb-sharing-v1", "header-orb-frames-v1", "balance-orb-frames-v2"}) {
                    require(!new File(context.getNoBackupFilesDir(), path).isFile(), "no stale " + path);
                }
            }
            result.putString("r50Fixture", "PASS");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("r50Fixture", "FAIL " + android.util.Log.getStackTraceString(error));
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private static SharedPreferences prefs(Context context, String name) {
        return context.getSharedPreferences(name, Context.MODE_PRIVATE);
    }

    private static void require(boolean ok, String check) {
        if (!ok) throw new AssertionError(check);
    }

    private static int bind(Context context, AppWidgetHost host, AppWidgetManager manager, String provider) {
        int id = host.allocateAppWidgetId();
        require(manager.bindAppWidgetIdIfAllowed(id,
                new ComponentName(context, "com.fluvi.app.widget." + provider)), "fixture grant for " + provider);
        return id;
    }
}
