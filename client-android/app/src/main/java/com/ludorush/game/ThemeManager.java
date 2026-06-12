package com.ludorush.game;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Singleton theme registry — the heart of the "Royal Gold" visual identity.
 *
 * Two skins share one luxury language: deep-navy + gold ("Royal Night", dark) and
 * warm-ivory + gold ("Royal Ivory", light).  Player pieces are jewel tones — ruby,
 * sapphire, royal gold and emerald — and stay constant across both skins.
 *
 * Call get(ctx) anywhere; setDark() flips skins and persists.  All color methods
 * return int ARGB values safe for View.setBackgroundColor / TextView.setTextColor.
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
    public int bgPage()        { return dark ? 0xff070B18 : 0xffF7F1E3; }
    public int bgHeader()      { return dark ? 0xff0B1124 : 0xffFFFDF6; }
    public int bgCard()        { return dark ? 0xff111A30 : 0xffFFFDF8; }
    public int bgMetric()      { return dark ? 0x22C79A3A : 0xffF3EAD4; }
    public int bgSel()         { return dark ? 0xff23304F : 0xffFAEFCD; }
    public int bgDanger()      { return dark ? 0xff241016 : 0xffFCECEC; }
    public int bgGradStart()   { return dark ? 0xff1C2745 : 0xffFFF7E4; }
    public int bgGradEnd()     { return dark ? 0xff0F1830 : 0xffF5EBD3; }

    // ── Text ─────────────────────────────────────────────────────────────────
    public int txtPrimary()    { return dark ? 0xffF6F1E4 : 0xff14203B; }
    public int txtSecondary()  { return dark ? 0xffB7BECE : 0xff52607B; }
    public int txtMuted()      { return dark ? 0xff7E8AA0 : 0xff7A86A0; }
    public int txtDim()        { return dark ? 0xff404B62 : 0xffC9BD9C; }
    public int txtVer()        { return dark ? 0xff3C465B : 0xffB8AC8A; }

    // ── Borders ───────────────────────────────────────────────────────────────
    public int strokeCard()    { return dark ? 0x2EC79A3A : 0xffE6D8B6; }
    public int strokeCardAlt() { return dark ? 0x1FC79A3A : 0xffEFE6CC; }
    public int strokeGrad()    { return dark ? 0x44C79A3A : 0xffE2D2A6; }
    public int strokeSel()     { return GOLD; }  // selected-mode border, gold in both skins
    public int strokeDanger()  { return dark ? 0x44E0314B : 0xffF2C9C9; }

    // ── System bar colors (read by MainActivity) ──────────────────────────────
    public int sysBarColor()   { return dark ? 0xff070B18 : 0xffF7F1E3; }

    // ── Jewel player palette (constant across both skins) ──────────────────────
    public static final int RED         = 0xffE0314B; // ruby
    public static final int BLUE        = 0xff2E6BE6; // sapphire
    public static final int YELLOW      = 0xffE9B949; // royal gold (doubles as accent)
    public static final int GREEN       = 0xff1FA873; // emerald
    public static final int BLUE_LIGHT  = 0xff5B95F5;
    public static final int GREEN_LIGHT = 0xff3FC894;

    // ── Royal accents ──────────────────────────────────────────────────────────
    public static final int GOLD        = 0xffE9B949;
    public static final int GOLD_LIGHT  = 0xffFFDD8A;
    public static final int GOLD_DARK   = 0xffB8862B;
    public static final int NAVY        = 0xff0B1330;
    public static final int NAVY_DEEP   = 0xff060A1C;
}
