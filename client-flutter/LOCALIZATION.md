# Ludo Rush localization

The Flutter interface uses Android string resources so Google Play's automatic
app-string translations can reach Flutter widgets. After changing English UI
copy, run `python tool/generate_play_strings.py` from `client-flutter`, commit
both generated files, and upload a new Android App Bundle. Play translates the
strings in that uploaded bundle; existing installed bundles are unchanged.

`LocalizedText` and the explicitly translated tooltips/input labels look up the
Android resource for the device locale. Missing translations fall back to the
English source. Flutter Material and Cupertino controls use their own locale
delegates. The generated catalog does not cover runtime-generated sentences or
remote content; add explicit localized templates for those when needed. Review
machine translations with native speakers before treating them as final copy.

Store listing and in-app product translations are managed separately in Play
Console; they are not bundled into this source tree.
