package com.ludorush.game;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Singleton theme registry — the heart of the "Royal Gold" visual identity.
 *
 * The signature skin is deep royal-navy + antique gold.  Player pieces are jewel
 * tones — crimson ruby, royal sapphire, imperial emerald and amber gold — each
 * paired with a softer companion tint for lanes, gradients and highlights.  A
 * warm-ivory light skin mirrors the same luxury language.
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
    public int bgPage()        { return dark ? 0xff0D1B3E : 0xffF7F1E3; }  // royal navy
    public int bgBoard()       { return dark ? 0xff091428 : 0xffFBF5E6; }  // deep board navy
    public int bgHeader()      { return dark ? 0xff0B1530 : 0xffFFFDF6; }
    public int bgCard()        { return dark ? 0xff13234A : 0xffFFFDF8; }
    public int bgMetric()      { return dark ? 0x22D4AF37 : 0xffF3EAD4; }
    public int bgSel()         { return dark ? 0xff1E3460 : 0xffFAEFCD; }
    public int bgDanger()      { return dark ? 0xff2A1018 : 0xffFCECEC; }
    public int bgGradStart()   { return dark ? 0xff1E3A6E : 0xffFFF7E4; }  // hero gradient (navy)
    public int bgGradEnd()     { return dark ? 0xff0D1B3E : 0xffF5EBD3; }

    // ── Text ─────────────────────────────────────────────────────────────────
    public int txtPrimary()    { return dark ? 0xffF6F1E4 : 0xff14203B; }
    public int txtSecondary()  { return dark ? 0xffBCC6DA : 0xff52607B; }
    public int txtMuted()      { return dark ? 0xff8794AE : 0xff7A86A0; }
    public int txtDim()        { return dark ? 0xff42507A : 0xffC9BD9C; }
    public int txtVer()        { return dark ? 0xff3C4A6E : 0xffB8AC8A; }

    // ── Borders ───────────────────────────────────────────────────────────────
    public int strokeCard()    { return dark ? 0x33D4AF37 : 0xffE6D8B6; }
    public int strokeCardAlt() { return dark ? 0x22D4AF37 : 0xffEFE6CC; }
    public int strokeGrad()    { return dark ? 0x4DD4AF37 : 0xffE2D2A6; }
    public int strokeSel()     { return GOLD; }  // selected-mode border, gold in both skins
    public int strokeDanger()  { return dark ? 0x44DC143C : 0xffF2C9C9; }

    // ── System bar colors (read by MainActivity) ──────────────────────────────
    public int sysBarColor()   { return dark ? 0xff0D1B3E : 0xffF7F1E3; }

    // ── Jewel player palette (constant across both skins) ──────────────────────
    public static final int RED         = 0xffDC143C; // crimson ruby
    public static final int BLUE        = 0xff1E5FA8; // royal sapphire
    public static final int GREEN       = 0xff1B7A3E; // imperial emerald
    public static final int YELLOW      = 0xffD4A017; // amber gold

    // soft companion tints — lanes, gradients, light highlights
    public static final int RED_SOFT    = 0xffE8637D;
    public static final int BLUE_SOFT   = 0xff6B9ED4;
    public static final int GREEN_SOFT  = 0xff62BC85;
    public static final int YELLOW_SOFT = 0xffE8CB6B;

    // legacy aliases (kept so existing screens keep compiling)
    public static final int BLUE_LIGHT  = BLUE_SOFT;
    public static final int GREEN_LIGHT = GREEN_SOFT;

    // ── Royal accents ──────────────────────────────────────────────────────────
    public static final int GOLD        = 0xffD4AF37; // antique gold accent
    public static final int GOLD_LIGHT  = 0xffEAD08A;
    public static final int GOLD_DARK   = 0xffA8842A;
    public static final int NAVY        = 0xff0D1B3E; // page navy
    public static final int NAVY_DEEP   = 0xff091428; // board navy
}
