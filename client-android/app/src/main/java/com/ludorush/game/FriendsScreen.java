package com.ludorush.game;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

public final class FriendsScreen extends BaseScreen {

    private static final String[] ONLINE_NAMES = {"StarLord99","QueenBee","RushMaster","NightOwl"};
    private static final int[]    ONLINE_COLORS = {0xffE53935,0xff8E24AA,0xff0288D1,0xff43A047};
    private static final String[] ONLINE_EMOJIS = {"S","Q","R","N"};

    private static final Object[][] FRIENDS = {
        {"Khalid M.", 1450, true,  false},
        {"Amina R.",  1210, false, false},
        {"Jake T.",   1380, true,  true},
        {"Fatima S.", 900,  false, false},
        {"Dev P.",    1550, true,  false},
    };

    private FrameLayout modalOverlay;
    private boolean modalVisible = false;

    public FriendsScreen(Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);

        body.addView(buildSearchBar(), lp(-1, -2, 0, 0, 0, dp(20)));

        addSectionLabel(body, "ONLINE NOW");
        body.addView(buildOnlineRow(), lp(-1, -2, 0, 0, 0, dp(22)));

        addSectionLabel(body, "ALL FRIENDS");
        body.addView(buildFriendsList(), lp(-1, -2, 0, 0, 0, dp(22)));

        addSectionLabel(body, "FRIEND REQUESTS");
        body.addView(buildRequestsSection(), lp(-1, -2, 0, 0, 0, dp(16)));

        FrameLayout frame = new FrameLayout(activity);
        View shell = createScreenShellRaw("Friends", buildHeaderExtra(), body);
        frame.addView(shell, new FrameLayout.LayoutParams(-1, -1));

        modalOverlay = buildAddFriendModal();
        modalOverlay.setVisibility(View.GONE);
        frame.addView(modalOverlay, new FrameLayout.LayoutParams(-1, -1));

        return frame;
    }

    private View createScreenShellRaw(String title, View headerRight, View content) {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());
        root.addView(createHeaderWithRight(title, headerRight), lp(-1, -2));

        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);
        LinearLayout body2 = new LinearLayout(activity);
        body2.setOrientation(LinearLayout.VERTICAL);
        body2.setPadding(dp(18), dp(12), dp(18), dp(20));
        body2.addView(content, lp(-1, -2));
        scroll.addView(body2, new ScrollView.LayoutParams(-1, -2));
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(scroll, sp);
        return root;
    }

    private LinearLayout createHeaderWithRight(String title, View rightView) {
        LinearLayout h = new LinearLayout(activity);
        h.setOrientation(LinearLayout.HORIZONTAL);
        h.setGravity(Gravity.CENTER_VERTICAL);
        h.setPadding(dp(4), dp(14), dp(12), dp(14));
        h.setBackground(card(theme.bgHeader(), 0, theme.strokeCard()));

        Button back = new Button(activity);
        back.setAllCaps(false); back.setText("<");
        back.setTextColor(ThemeManager.GOLD); back.setTextSize(26);
        back.setTypeface(Typeface.DEFAULT_BOLD); back.setBackground(null);
        back.setPadding(dp(12), 0, dp(8), 0);
        back.setOnClickListener(v -> callback.goBack());
        h.addView(back, lp(dp(52), dp(52)));

        LinearLayout titleBadge = new LinearLayout(activity);
        titleBadge.setOrientation(LinearLayout.HORIZONTAL);
        titleBadge.setGravity(Gravity.CENTER_VERTICAL);
        TextView t = text(title, 18, ThemeManager.GOLD, Typeface.BOLD);
        titleBadge.addView(t, lp(-2, -2, 0, 0, dp(8), 0));
        TextView onlineBadge = badge("3 online", 0xff2DB34A, Color.WHITE);
        titleBadge.addView(onlineBadge);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        h.addView(titleBadge, tp);

        if (rightView != null) h.addView(rightView, lp(-2, dp(40)));
        return h;
    }

    private View buildHeaderExtra() {
        Button addBtn = new Button(activity);
        addBtn.setAllCaps(false); addBtn.setText("+ Add");
        addBtn.setTextColor(0xff1A0800); addBtn.setTextSize(12);
        addBtn.setTypeface(Typeface.DEFAULT_BOLD);
        addBtn.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(20)));
        addBtn.setPadding(dp(12), 0, dp(12), 0);
        addBtn.setOnClickListener(v -> showModal());
        return addBtn;
    }

    private View buildSearchBar() {
        LinearLayout bar = new LinearLayout(activity);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setBackground(card(theme.bgCard(), dp(24), theme.strokeCard()));
        bar.setPadding(dp(14), dp(10), dp(14), dp(10));
        TextView icon = text("🔍", 16, theme.txtMuted(), Typeface.NORMAL);
        bar.addView(icon, lp(-2, -2, 0, 0, dp(8), 0));
        EditText search = new EditText(activity);
        search.setBackground(null);
        search.setHint("Search friends...");
        search.setHintTextColor(theme.txtDim());
        search.setTextColor(theme.txtPrimary());
        search.setTextSize(14);
        bar.addView(search, new LinearLayout.LayoutParams(0, -2, 1));
        return bar;
    }

    private View buildOnlineRow() {
        HorizontalScrollView hsv = new HorizontalScrollView(activity);
        hsv.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(0, dp(2), 0, dp(4));
        for (int i = 0; i < ONLINE_NAMES.length; i++) {
            row.addView(buildOnlineCard(i));
        }
        hsv.addView(row, new LinearLayout.LayoutParams(-2, -2));
        return hsv;
    }

    private View buildOnlineCard(int idx) {
        String name = ONLINE_NAMES[idx];
        int color = ONLINE_COLORS[idx];
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(10), dp(12), dp(10), dp(12));
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        LinearLayout.LayoutParams mlp = new LinearLayout.LayoutParams(dp(88), -2);
        mlp.rightMargin = dp(10);
        card.setLayoutParams(mlp);
        FrameLayout avatarFrame = new FrameLayout(activity);
        View av = new View(activity);
        av.setBackground(circle(color));
        avatarFrame.addView(av, new FrameLayout.LayoutParams(dp(42), dp(42)));
        TextView ini = new TextView(activity);
        ini.setText(ONLINE_EMOJIS[idx]);
        ini.setTextColor(0xffffffff);
        ini.setTextSize(16);
        ini.setTypeface(Typeface.DEFAULT_BOLD);
        ini.setGravity(Gravity.CENTER);
        avatarFrame.addView(ini, new FrameLayout.LayoutParams(dp(42), dp(42), Gravity.CENTER));
        View dot = new View(activity);
        dot.setBackground(circle(0xff43A047));
        FrameLayout.LayoutParams dlp = new FrameLayout.LayoutParams(dp(11), dp(11));
        dlp.gravity = Gravity.BOTTOM | Gravity.END;
        avatarFrame.addView(dot, dlp);
        card.addView(avatarFrame, lp(-2, dp(42), 0, 0, 0, dp(6)));
        String label = name.length() > 9 ? name.substring(0, 8) + "…" : name;
        TextView nameV = text(label, 11, theme.txtPrimary(), Typeface.BOLD);
        nameV.setGravity(Gravity.CENTER);
        card.addView(nameV, lp(-1, -2, 0, 0, 0, dp(6)));
        Button challenge = new Button(activity);
        challenge.setAllCaps(false);
        challenge.setText("▶ Play");
        challenge.setTextSize(11);
        challenge.setTextColor(0xff1A0800);
        challenge.setTypeface(Typeface.DEFAULT_BOLD);
        challenge.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(12)));
        card.addView(challenge, lp(-1, dp(28)));
        return card;
    }

    private View buildFriendsList() {
        LinearLayout section = new LinearLayout(activity);
        section.setOrientation(LinearLayout.VERTICAL);
        if (FRIENDS.length == 0) {
            section.addView(buildEmptyState(), lp(-1, -2));
            return section;
        }
        for (Object[] f : FRIENDS) {
            section.addView(buildFriendCard(f), lp(-1, -2, 0, 0, 0, dp(8)));
        }
        return section;
    }

    private View buildFriendCard(Object[] friend) {
        String name     = (String)  friend[0];
        int    trophies = (Integer) friend[1];
        boolean online  = (Boolean) friend[2];
        boolean pending = (Boolean) friend[3];
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        card.setPadding(dp(14), dp(13), dp(14), dp(13));
        int color = ONLINE_COLORS[Math.abs(name.hashCode()) % ONLINE_COLORS.length];
        FrameLayout avatarF = new FrameLayout(activity);
        View av = new View(activity);
        av.setBackground(circle(color));
        avatarF.addView(av, new FrameLayout.LayoutParams(dp(42), dp(42)));
        TextView ini = text(name.substring(0, 1), 18, 0xffffffff, Typeface.BOLD);
        ini.setGravity(Gravity.CENTER);
        avatarF.addView(ini, new FrameLayout.LayoutParams(dp(42), dp(42), Gravity.CENTER));
        if (online) {
            View dot = new View(activity);
            dot.setBackground(circle(0xff43A047));
            FrameLayout.LayoutParams dlp = new FrameLayout.LayoutParams(dp(10), dp(10));
            dlp.gravity = Gravity.BOTTOM | Gravity.END;
            avatarF.addView(dot, dlp);
        }
        card.addView(avatarF, lp(dp(42), dp(42), 0, 0, dp(12), 0));
        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        info.addView(text(name, 14, theme.txtPrimary(), Typeface.BOLD), lp(-2, -2));
        String sub = "🏆 " + trophies + "  •  " + (online ? "Online" : "Offline");
        info.addView(text(sub, 12, theme.txtMuted(), Typeface.NORMAL), lp(-2, -2, 0, dp(3), 0, 0));
        card.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
        if (pending) {
            TextView tag = text("Pending", 11, ThemeManager.AMBER, Typeface.NORMAL);
            tag.setBackground(card(0x22FFC107, dp(8), 0));
            tag.setPadding(dp(8), dp(4), dp(8), dp(4));
            card.addView(tag, lp(-2, -2));
        } else {
            Button ch = new Button(activity);
            ch.setAllCaps(false);
            ch.setText(online ? "Challenge" : "Message");
            ch.setTextSize(12);
            ch.setTextColor(0xff1A0800);
            ch.setTypeface(Typeface.DEFAULT_BOLD);
            ch.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(12)));
            card.addView(ch, lp(dp(92), dp(34)));
        }
        return card;
    }

    private View buildRequestsSection() {
        LinearLayout section = new LinearLayout(activity);
        section.setOrientation(LinearLayout.VERTICAL);
        section.addView(buildRequestCard("SkyWalker77", 0xff0288D1, 0));
        section.addView(buildRequestCard("IronFist", 0xffC62828, dp(8)));
        return section;
    }

    private View buildRequestCard(String name, int color, int topMargin) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        card.setPadding(dp(14), dp(12), dp(14), dp(12));
        LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(-1, -2);
        clp.topMargin = topMargin;
        card.setLayoutParams(clp);
        FrameLayout avF = new FrameLayout(activity);
        View av = new View(activity);
        av.setBackground(circle(color));
        avF.addView(av, new FrameLayout.LayoutParams(dp(42), dp(42)));
        TextView ini = text(name.substring(0, 1), 18, 0xffffffff, Typeface.BOLD);
        ini.setGravity(Gravity.CENTER);
        avF.addView(ini, new FrameLayout.LayoutParams(dp(42), dp(42), Gravity.CENTER));
        card.addView(avF, lp(dp(42), dp(42), 0, 0, dp(12), 0));
        card.addView(text(name, 14, theme.txtPrimary(), Typeface.BOLD),
            new LinearLayout.LayoutParams(0, -2, 1));
        Button accept = new Button(activity);
        accept.setAllCaps(false); accept.setText("Accept");
        accept.setTextSize(12); accept.setTextColor(0xff1A0800);
        accept.setTypeface(Typeface.DEFAULT_BOLD);
        accept.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(12)));
        LinearLayout.LayoutParams alp = new LinearLayout.LayoutParams(dp(80), dp(34));
        alp.rightMargin = dp(8);
        card.addView(accept, alp);
        Button decline = new Button(activity);
        decline.setAllCaps(false); decline.setText("Decline");
        decline.setTextSize(12); decline.setTextColor(theme.txtMuted());
        decline.setBackground(card(0, dp(12), theme.strokeCard()));
        card.addView(decline, lp(dp(74), dp(34)));
        return card;
    }

    private View buildEmptyState() {
        LinearLayout empty = new LinearLayout(activity);
        empty.setOrientation(LinearLayout.VERTICAL);
        empty.setGravity(Gravity.CENTER);
        empty.setPadding(dp(32), dp(40), dp(32), dp(40));
        empty.addView(new TwoPersonView(activity), lp(dp(80), dp(60), 0, 0, 0, dp(16)));
        empty.addView(text("No friends yet", 18, theme.txtPrimary(), Typeface.BOLD),
            lp(-2, -2, 0, 0, 0, dp(8)));
        empty.addView(text("Add friends to challenge them!", 14, theme.txtMuted(), Typeface.NORMAL),
            lp(-2, -2));
        return empty;
    }

    private FrameLayout buildAddFriendModal() {
        FrameLayout overlay = new FrameLayout(activity);
        overlay.setBackground(new android.graphics.drawable.ColorDrawable(0xCC000000));
        overlay.setOnClickListener(v -> hideModal());
        LinearLayout box = new LinearLayout(activity);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setBackground(card(theme.bgCard(), dp(20), theme.strokeCard()));
        box.setPadding(dp(24), dp(24), dp(24), dp(24));
        box.setOnClickListener(v -> {});
        FrameLayout.LayoutParams blp = new FrameLayout.LayoutParams(dp(300), -2, Gravity.CENTER);
        box.setLayoutParams(blp);
        box.addView(text("Add Friend", 18, theme.txtPrimary(), Typeface.BOLD),
            lp(-2, -2, 0, 0, 0, dp(16)));
        EditText input = new EditText(activity);
        input.setHint("Enter username or ID");
        input.setHintTextColor(theme.txtDim());
        input.setTextColor(theme.txtPrimary());
        input.setTextSize(15);
        input.setBackground(card(theme.bgCard(), dp(12), theme.strokeCard()));
        input.setPadding(dp(14), dp(12), dp(14), dp(12));
        box.addView(input, lp(-1, -2, 0, 0, 0, dp(20)));
        LinearLayout btns = new LinearLayout(activity);
        btns.setOrientation(LinearLayout.HORIZONTAL);
        btns.setGravity(Gravity.END);
        Button cancel = new Button(activity);
        cancel.setAllCaps(false); cancel.setText("Cancel");
        cancel.setTextSize(14); cancel.setTextColor(theme.txtMuted());
        cancel.setBackground(null);
        cancel.setOnClickListener(v -> hideModal());
        LinearLayout.LayoutParams clp2 = new LinearLayout.LayoutParams(-2, dp(44));
        clp2.rightMargin = dp(8);
        btns.addView(cancel, clp2);
        Button send = new Button(activity);
        send.setAllCaps(false); send.setText("Send Request");
        send.setTextSize(14); send.setTextColor(0xff1A0800);
        send.setTypeface(Typeface.DEFAULT_BOLD);
        send.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(14)));
        btns.addView(send, lp(-2, dp(44)));
        box.addView(btns, lp(-1, -2));
        overlay.addView(box);
        return overlay;
    }

    private void showModal() {
        modalOverlay.setVisibility(View.VISIBLE);
        modalOverlay.setAlpha(0f);
        modalOverlay.animate().alpha(1f).setDuration(220).start();
    }

    private void hideModal() {
        modalOverlay.animate().alpha(0f).setDuration(180)
            .withEndAction(() -> modalOverlay.setVisibility(View.GONE)).start();
    }

    static class TwoPersonView extends View {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        TwoPersonView(android.content.Context ctx) { super(ctx); }
        @Override protected void onDraw(Canvas c) {
            int w = getWidth(), h = getHeight();
            p.setColor(0xff8E24AA);
            c.drawCircle(w * 0.35f, h * 0.30f, h * 0.22f, p);
            c.drawRoundRect(w * 0.05f, h * 0.55f, w * 0.65f, h * 0.98f, h * 0.15f, h * 0.15f, p);
            p.setColor(0xff0288D1);
            c.drawCircle(w * 0.68f, h * 0.30f, h * 0.20f, p);
            c.drawRoundRect(w * 0.40f, h * 0.55f, w * 0.95f, h * 0.98f, h * 0.15f, h * 0.15f, p);
        }
    }
}
