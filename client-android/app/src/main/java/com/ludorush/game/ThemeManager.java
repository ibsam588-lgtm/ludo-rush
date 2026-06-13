package com.ludorush.game;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Royal Rush theme — premium Ludo game aesthetic.
 * Deep purple canvas (à la Ludo Star) with gold accents and classic vivid piece colours.
 */
public final class ThemeManager {

    private static ThemeManager instance;
    private final SharedPreferences prefs;
    private boolean dark;

    private ThemeManager(Context ctx) {
        prefs = ctx.getApplicationContext().getSharedPreferences("ludo_settings", 0);
        dark = prefs.getBoolean("dark_mode", true);
    }

    public static ThemeManager get(Context ctx) {
        if (instance == null) instance = new ThemeManager(ctx);
        return instance;
    }

    public boolean isDark()  { return dark; }

    public void setDark(boolean d) {
        dark = d;
        prefs.edit().putBoolean("dark_mode", d).apply();
    }

    // ── Backgrounds ───────────────────────────────────────────────────────────
    public int bgPage()      { return dark ? 0xff150020 : 0xffFFF0FB; }
    public int bgSurface()   { return dark ? 0xff2A0B49 : 0xffFFE15A; }
    public int bgCard()      { return dark ? 0xff3B145B : 0xffFFFFFF; }
    public int bgCardHigh()  { return dark ? 0xff6E1C83 : 0xffFFD6F0; }
    public int bgHeader()    { return dark ? 0xff4D0F69 : 0xffFF4FA3; }
    public int bgBoard()     { return dark ? 0xff23102F : 0xffFFF9DD; }
    public int bgMetric()    { return dark ? 0x33FFD426 : 0xffFFF0A6; }
    public int bgSel()       { return dark ? 0xff9A24D4 : 0xff40D8FF; }
    public int bgDanger()    { return dark ? 0xff2A1218 : 0xffffE0EC; }
    public int bgGradStart() { return dark ? 0xffFFD426 : 0xffFFD426; }
    public int bgGradEnd()   { return dark ? 0xffFF9A00 : 0xffFF9A00; }
    public int bgHeroStart() { return dark ? 0xffA51FE0 : 0xffFF67B7; }
    public int bgHeroEnd()   { return dark ? 0xff1E0638 : 0xff37D5FF; }
    public int bgBottomBar() { return dark ? 0xff6B255F : 0xff6738E8; }
    public int bgInput()     { return dark ? 0xff35104F : 0xffFFF7D7; }

    // ── Text ──────────────────────────────────────────────────────────────────
    public int txtPrimary()   { return dark ? 0xffFFFFFF : 0xff25102F; }
    public int txtSecondary() { return dark ? 0xEEFFF0FF : 0xff5A245C; }
    public int txtMuted()     { return dark ? 0xCCFFECA8 : 0xff7A3E7F; }
    public int txtDim()       { return dark ? 0x77FFFFFF : 0xffA066A8; }
    public int txtHero()      { return 0xffFFFFFF; }
    public int txtVer()       { return dark ? 0x44FFFFFF : 0xffA0BBCC; }

    // ── Borders / strokes ─────────────────────────────────────────────────────
    public int strokeCard()     { return dark ? 0x77FFD426 : 0xff8D4CFF; }
    public int strokeCardAlt()  { return dark ? 0x55FFD426 : 0xffD7C8FF; }
    public int strokeCardGlow() { return dark ? 0xBBFFD426 : 0xffFF4FA3; }
    public int strokeSel()      { return GOLD; }
    public int strokeAccent()   { return dark ? 0xAAFFD426 : 0xff7C4DFF; }
    public int strokeDanger()   { return dark ? 0x55E53935 : 0xffFF8AB3; }
    public int strokeGrad()     { return dark ? 0xffFFD426 : 0xff7C4DFF; }

    // ── System bar ────────────────────────────────────────────────────────────
    public int sysBarColor() { return dark ? 0xff150020 : 0xffFFF0FB; }

    // ── Brand palette ─────────────────────────────────────────────────────────

    /** Classic Ludo piece colours — vivid and saturated. */
    public static final int RED    = 0xffF32B2B;   // punchy red
    public static final int BLUE   = 0xff1565E0;   // bright royal blue
    public static final int YELLOW = 0xffFFD000;   // golden yellow
    public static final int GREEN  = 0xff2DB34A;   // vivid green

    /** Home-lane tints — strong enough to read on cream path cells. */
    public static final int RED_SOFT    = 0xffFF8A80;   // warm coral
    public static final int BLUE_SOFT   = 0xff82B1FF;   // electric blue tint
    public static final int YELLOW_SOFT = 0xffFFE57F;   // warm gold tint
    public static final int GREEN_SOFT  = 0xff69F0AE;   // bright mint

    /** UI accents. */
    public static final int GOLD         = 0xffFFD426;
    public static final int AMBER        = 0xffFF9A00;
    public static final int TEAL         = 0xff32D3C8;
    public static final int VIOLET       = 0xff7C3AED;   // legacy alias
    public static final int INDIGO       = 0xff3949AB;   // legacy alias
    public static final int SURFACE_GLOW = 0x22FFD700;

    /** Legacy aliases — kept so existing call-sites compile unchanged. */
    public static final int BLUE_LIGHT  = 0xff90CAF9;
    public static final int GREEN_LIGHT = 0xffA5D6A7;
}
