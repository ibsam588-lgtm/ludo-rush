package com.ludorush.game;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Singleton theme registry.  Call get(ctx) anywhere; toggle() flips dark↔light and
 * persists the preference.  All color methods return int ARGB values safe for
 * View.setBackgroundColor / TextView.setTextColor.
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

    public boolean isDark() { return dark; }

    public void setDark(boolean d) {
        dark = d;
        prefs.edit().putBoolean("dark_mode", d).apply();
    }

    // ── Page / structural backgrounds ─────────────────────────────────────────
    public int bgPage()        { return dark ? 0xff080B13 : 0xffF2F4FF; }
    public int bgHeader()      { return dark ? 0xff0D1320 : 0xffFFFFFF; }
    public int bgCard()        { return dark ? 0xff111A2A : 0xffFFFFFF; }
    public int bgMetric()      { return dark ? 0x221C2A3F : 0xffEEF4FF; }
    public int bgSel()         { return dark ? 0xff1A3A5C : 0xffDCEBFF; }
    public int bgDanger()      { return dark ? 0xff1A1010 : 0xffFFF0F0; }
    public int bgGradStart()   { return dark ? 0xff192133 : 0xffEEF2FF; }
    public int bgGradEnd()     { return dark ? 0xff101827 : 0xffE4EEFF; }

    // ── Text ─────────────────────────────────────────────────────────────────
    public int txtPrimary()    { return dark ? 0xffFFFFFF : 0xff0D1425; }
    public int txtSecondary()  { return dark ? 0xff94A3B8 : 0xff475569; }
    public int txtMuted()      { return dark ? 0xff6B7A90 : 0xff64748B; }
    public int txtDim()        { return dark ? 0xff3A4556 : 0xffCBD5E1; }
    public int txtVer()        { return dark ? 0xff3A4556 : 0xffA0AFCC; }

    // ── Borders ───────────────────────────────────────────────────────────────
    public int strokeCard()    { return dark ? 0x335D6D86 : 0xffC5D8F0; }
    public int strokeCardAlt() { return dark ? 0x225D6D86 : 0xffD8E8FA; }
    public int strokeGrad()    { return dark ? 0x334B5D78 : 0xffCDD8EE; }
    public int strokeSel()     { return ThemeManager.BLUE; }  // selected-mode border, same in both themes
    public int strokeDanger()  { return dark ? 0x44E8293E : 0xffFFCDD2; }

    // ── System bar colors (read by MainActivity) ──────────────────────────────
    public int sysBarColor()   { return dark ? 0xff080B13 : 0xffF2F4FF; }

    // ── Brand palette (unchanged in both themes) ──────────────────────────────
    public static final int RED         = 0xffE8293E;
    public static final int BLUE        = 0xff1E88E5;
    public static final int YELLOW      = 0xffF9A825;
    public static final int GREEN       = 0xff43A047;
    public static final int BLUE_LIGHT  = 0xff42A5F5;
    public static final int GREEN_LIGHT = 0xff66BB6A;
}
