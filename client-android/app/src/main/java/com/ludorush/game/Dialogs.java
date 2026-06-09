package com.ludorush.game;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.Window;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Shared styled confirmation dialog used across screens. */
final class Dialogs {

    private Dialogs() {}

    static void confirm(Activity activity, String emoji, String title, String message,
                        String confirmLabel, Runnable onConfirm) {
        Dialog dialog = new Dialog(activity);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);

        float density = activity.getResources().getDisplayMetrics().density;
        int d20 = (int) (20 * density), d8 = (int) (8 * density);

        LinearLayout panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setGravity(Gravity.CENTER_HORIZONTAL);
        panel.setPadding(d20, (int) (24 * density), d20, d20);
        GradientDrawable bg = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR, new int[]{0xff1A2440, 0xff0F1626});
        bg.setCornerRadius(24 * density);
        bg.setStroke((int) density, 0x55809BC8);
        panel.setBackground(bg);

        TextView icon = new TextView(activity);
        icon.setText(emoji);
        icon.setTextSize(34);
        icon.setGravity(Gravity.CENTER);
        panel.addView(icon);

        TextView titleView = new TextView(activity);
        titleView.setText(title);
        titleView.setTextSize(20);
        titleView.setTextColor(Color.WHITE);
        titleView.setTypeface(Typeface.DEFAULT_BOLD);
        titleView.setGravity(Gravity.CENTER);
        titleView.setPadding(0, d8, 0, 0);
        panel.addView(titleView);

        TextView msg = new TextView(activity);
        msg.setText(message);
        msg.setTextSize(14);
        msg.setTextColor(0xff8B9BB4);
        msg.setGravity(Gravity.CENTER);
        msg.setPadding(0, (int) (4 * density), 0, (int) (18 * density));
        panel.addView(msg);

        LinearLayout buttons = new LinearLayout(activity);
        buttons.setOrientation(LinearLayout.HORIZONTAL);
        panel.addView(buttons, new LinearLayout.LayoutParams(-1, -2));

        Button cancel = new Button(activity);
        cancel.setAllCaps(false);
        cancel.setText("Cancel");
        cancel.setTextColor(Color.WHITE);
        cancel.setTextSize(15);
        cancel.setTypeface(Typeface.DEFAULT_BOLD);
        GradientDrawable cancelBg = new GradientDrawable();
        cancelBg.setColor(0xff1B2740);
        cancelBg.setCornerRadius(16 * density);
        cancelBg.setStroke((int) density, 0x446F84A8);
        cancel.setBackground(cancelBg);
        cancel.setOnClickListener(v -> dialog.dismiss());
        LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, (int) (48 * density), 1);
        cp.setMargins(0, 0, d8, 0);
        buttons.addView(cancel, cp);

        Button confirm = new Button(activity);
        confirm.setAllCaps(false);
        confirm.setText(confirmLabel);
        confirm.setTextColor(Color.WHITE);
        confirm.setTextSize(15);
        confirm.setTypeface(Typeface.DEFAULT_BOLD);
        GradientDrawable confirmBg = new GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT, new int[]{0xffFF3D5A, 0xffFF9F1C});
        confirmBg.setCornerRadius(16 * density);
        confirm.setBackground(confirmBg);
        confirm.setOnClickListener(v -> {
            dialog.dismiss();
            onConfirm.run();
        });
        LinearLayout.LayoutParams kp = new LinearLayout.LayoutParams(0, (int) (48 * density), 1);
        kp.setMargins(d8, 0, 0, 0);
        buttons.addView(confirm, kp);

        dialog.setContentView(panel);
        Window w = dialog.getWindow();
        if (w != null) {
            w.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            w.setLayout((int) (activity.getResources().getDisplayMetrics().widthPixels * 0.82f), -2);
        }
        dialog.show();
    }
}
