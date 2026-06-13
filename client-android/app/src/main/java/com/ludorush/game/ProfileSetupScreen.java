package com.ludorush.game;

import android.app.Activity;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.text.InputFilter;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

public final class ProfileSetupScreen extends BaseScreen {

    private static final String[] AVATAR_ICONS = {"⚔", "🧙", "🥷", "🛡", "👑", "🏴", "🤖", "👽"};
    private static final int[] AVATAR_COLORS = {0xffC62828,0xff4527A0,0xff1B5E20,0xff006064,0xffAD1457,0xff37474F,0xff0D47A1,0xff558B2F};
    private static final String[] COUNTRIES = {"🇬🇧","🇺🇸","🇵🇰","🇮🇳","🇸🇦","🇦🇪","🇿🇦","🇳🇬","🇧🇩","🇨🇦","🇦🇺","🇩🇪","🇫🇷","🇧🇷","🇲🇾","🇵🇭"};

    private int selectedAvatar = 0;
    private int selectedCountry = 0;
    private boolean musicOn = true;
    private boolean sfxOn = true;
    private EditText nameField;
    private View[] avatarViews;
    private View[] countryViews;
    private TextView musicPill;
    private TextView sfxPill;

    public ProfileSetupScreen(Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        FrameLayout root = new FrameLayout(activity);
        root.setBackgroundColor(theme.bgPage());

        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(18), dp(24), dp(18), dp(24));

        TextView title = text("Welcome to Ludo Rush!", 24, ThemeManager.GOLD, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        body.addView(title, lp(-1, -2, 0, 0, 0, dp(4)));

        TextView sub = text("Set up your profile to get started", 13, theme.txtMuted(), Typeface.NORMAL);
        sub.setGravity(Gravity.CENTER);
        body.addView(sub, lp(-1, -2, 0, 0, 0, dp(28)));

        addSectionLabel(body, "CHOOSE YOUR AVATAR");
        body.addView(buildAvatarRow(), lp(-1, -2, 0, 0, 0, dp(24)));

        addSectionLabel(body, "DISPLAY NAME");
        body.addView(buildNameField(), lp(-1, -2, 0, 0, 0, dp(24)));

        addSectionLabel(body, "YOUR COUNTRY");
        body.addView(buildCountryRow(), lp(-1, -2, 0, 0, 0, dp(24)));

        addSectionLabel(body, "AUDIO");
        body.addView(buildMusicToggle(), lp(-1, -2, 0, 0, 0, dp(12)));
        body.addView(buildSfxToggle(), lp(-1, -2, 0, 0, 0, dp(28)));

        Button play = primaryButton("Let’s Play!");
        play.setTextSize(18);
        play.setPadding(0, dp(18), 0, dp(18));
        play.setOnClickListener(v -> saveAndContinue());
        body.addView(play, lp(-1, dp(60)));

        scroll.addView(body, new ScrollView.LayoutParams(-1, -2));
        root.addView(scroll, new FrameLayout.LayoutParams(-1, -1));
        return root;
    }

    private View buildAvatarRow() {
        HorizontalScrollView hsv = new HorizontalScrollView(activity);
        hsv.setOverScrollMode(View.OVER_SCROLL_NEVER);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(2), dp(8), dp(2), dp(8));
        avatarViews = new View[AVATAR_ICONS.length + 1];
        for (int i = 0; i < AVATAR_ICONS.length; i++) {
            final int idx = i;
            LinearLayout cell = makeAvatarCell(AVATAR_ICONS[i], AVATAR_COLORS[i], i == selectedAvatar);
            cell.setOnClickListener(v -> selectAvatar(idx));
            avatarViews[i] = cell;
            LinearLayout.LayoutParams alp = new LinearLayout.LayoutParams(dp(68), dp(80));
            alp.setMargins(dp(4), 0, dp(4), 0);
            row.addView(cell, alp);
        }
        LinearLayout upload = makeUploadCell();
        upload.setOnClickListener(v -> Toast.makeText(activity, "Camera coming soon", Toast.LENGTH_SHORT).show());
        avatarViews[AVATAR_ICONS.length] = upload;
        LinearLayout.LayoutParams ulp2 = new LinearLayout.LayoutParams(dp(68), dp(80));
        ulp2.setMargins(dp(4), 0, dp(4), 0);
        row.addView(upload, ulp2);
        hsv.addView(row, new HorizontalScrollView.LayoutParams(-2, -2));
        return hsv;
    }

    private LinearLayout makeAvatarCell(String icon, int color, boolean selected) {
        LinearLayout cell = new LinearLayout(activity);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        GradientDrawable ring = new GradientDrawable();
        ring.setShape(GradientDrawable.OVAL);
        ring.setColor(color);
        ring.setStroke(selected ? dp(3) : dp(1), selected ? ThemeManager.GOLD : 0x44FFFFFF);
        TextView iconTv = new TextView(activity);
        iconTv.setText(icon);
        iconTv.setTextSize(selected ? 26 : 22);
        iconTv.setGravity(Gravity.CENTER);
        iconTv.setBackground(ring);
        iconTv.setScaleX(selected ? 1.12f : 1f);
        iconTv.setScaleY(selected ? 1.12f : 1f);
        cell.addView(iconTv, lp(dp(52), dp(52)));
        return cell;
    }

    private LinearLayout makeUploadCell() {
        LinearLayout cell = new LinearLayout(activity);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        GradientDrawable ring = new GradientDrawable();
        ring.setShape(GradientDrawable.OVAL);
        ring.setColor(theme.bgCard());
        ring.setStroke(dp(2), theme.strokeCard());
        TextView iconTv = new TextView(activity);
        iconTv.setText("+");
        iconTv.setTextSize(28);
        iconTv.setTextColor(ThemeManager.GOLD);
        iconTv.setGravity(Gravity.CENTER);
        iconTv.setBackground(ring);
        cell.addView(iconTv, lp(dp(52), dp(52)));
        return cell;
    }

    private void selectAvatar(int idx) {
        selectedAvatar = idx;
        for (int i = 0; i < AVATAR_ICONS.length; i++) {
            if (avatarViews[i] instanceof LinearLayout) {
                LinearLayout cell = (LinearLayout) avatarViews[i];
                if (cell.getChildCount() > 0 && cell.getChildAt(0) instanceof TextView) {
                    TextView tv = (TextView) cell.getChildAt(0);
                    boolean sel = i == selectedAvatar;
                    GradientDrawable ring = new GradientDrawable();
                    ring.setShape(GradientDrawable.OVAL);
                    ring.setColor(AVATAR_COLORS[i]);
                    ring.setStroke(sel ? dp(3) : dp(1), sel ? ThemeManager.GOLD : 0x44FFFFFF);
                    tv.setBackground(ring);
                    tv.setTextSize(sel ? 26 : 22);
                    tv.setScaleX(sel ? 1.12f : 1f);
                    tv.setScaleY(sel ? 1.12f : 1f);
                }
            }
        }
    }

    private View buildNameField() {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        card.setPadding(dp(16), dp(14), dp(16), dp(14));
        nameField = new EditText(activity);
        nameField.setBackground(null);
        nameField.setTextColor(theme.txtPrimary());
        nameField.setHintTextColor(theme.txtMuted());
        nameField.setTextSize(16);
        nameField.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        nameField.setHint("Enter your name");
        nameField.setSingleLine(true);
        nameField.setFilters(new InputFilter[]{new InputFilter.LengthFilter(20)});
        int rand = (int)(Math.random() * 9000) + 1000;
        nameField.setText("Player" + rand);
        nameField.setSelectAllOnFocus(true);
        card.addView(nameField, lp(-1, -2));
        return card;
    }

    private View buildCountryRow() {
        HorizontalScrollView hsv = new HorizontalScrollView(activity);
        hsv.setOverScrollMode(View.OVER_SCROLL_NEVER);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(2), dp(4), dp(2), dp(4));
        countryViews = new View[COUNTRIES.length];
        for (int i = 0; i < COUNTRIES.length; i++) {
            final int idx = i;
            Button btn = new Button(activity);
            btn.setAllCaps(false);
            btn.setText(COUNTRIES[i]);
            btn.setTextSize(22);
            btn.setIncludeFontPadding(false);
            updateCountryButton(btn, i == selectedCountry);
            btn.setOnClickListener(v -> selectCountry(idx));
            countryViews[i] = btn;
            LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(dp(52), dp(52));
            clp.setMargins(dp(4), 0, dp(4), 0);
            row.addView(btn, clp);
        }
        hsv.addView(row, new HorizontalScrollView.LayoutParams(-2, -2));
        return hsv;
    }

    private void updateCountryButton(Button btn, boolean selected) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(selected ? theme.bgSel() : theme.bgCard());
        d.setStroke(selected ? dp(3) : dp(1), selected ? ThemeManager.GOLD : theme.strokeCard());
        btn.setBackground(d);
    }

    private void selectCountry(int idx) {
        int prev = selectedCountry;
        selectedCountry = idx;
        if (countryViews[prev] instanceof Button) updateCountryButton((Button)countryViews[prev], false);
        if (countryViews[idx] instanceof Button) updateCountryButton((Button)countryViews[idx], true);
    }

    private View buildToggleCard(String label, boolean defaultOn,
            java.util.function.Consumer<TextView> pillRef, java.util.function.Consumer<Boolean> action) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        card.setPadding(dp(18), dp(16), dp(18), dp(16));
        TextView lbl = text(label, 15, theme.txtPrimary(), Typeface.BOLD);
        card.addView(lbl, new LinearLayout.LayoutParams(0, -2, 1));
        TextView pill = new TextView(activity);
        pill.setText("ON");
        pill.setTextColor(0xff1A0800);
        pill.setTextSize(12);
        pill.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        pill.setPadding(dp(16), dp(6), dp(16), dp(6));
        pill.setGravity(Gravity.CENTER);
        GradientDrawable pd = new GradientDrawable();
        pd.setCornerRadius(dp(20));
        pd.setColor(ThemeManager.GOLD);
        pill.setBackground(pd);
        if (pillRef != null) pillRef.accept(pill);
        final boolean[] state = {defaultOn};
        pill.setOnClickListener(v -> {
            state[0] = !state[0];
            pill.setText(state[0] ? "ON" : "OFF");
            GradientDrawable nd = new GradientDrawable();
            nd.setCornerRadius(dp(20));
            nd.setColor(state[0] ? ThemeManager.GOLD : theme.bgSurface());
            pill.setBackground(nd);
            pill.setTextColor(state[0] ? 0xff1A0800 : theme.txtMuted());
            if (action != null) action.accept(state[0]);
        });
        card.addView(pill, lp(-2, -2));
        return card;
    }

    private View buildMusicToggle() {
        return buildToggleCard("Music", true, p -> musicPill = p, on -> musicOn = on);
    }

    private View buildSfxToggle() {
        return buildToggleCard("Sound FX", true, p -> sfxPill = p, on -> sfxOn = on);
    }

    private void saveAndContinue() {
        String name = nameField.getText().toString().trim();
        if (name.isEmpty()) name = "Player";
        SharedPreferences prefs = activity.getSharedPreferences("ludo_settings", 0);
        prefs.edit()
            .putInt("player_avatar", selectedAvatar)
            .putString("player_name", name)
            .putString("player_country", COUNTRIES[selectedCountry])
            .putBoolean("music_enabled", musicOn)
            .putBoolean("sfx_enabled", sfxOn)
            .putBoolean("profile_setup_done", true)
            .apply();
        callback.navigateTo("home");
    }
}
