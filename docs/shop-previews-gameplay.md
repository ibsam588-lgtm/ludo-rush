# Shop previews and gameplay polish

The shop now opens an animated, isolated preview for every product, board, die, and avatar, including locked items. Equipping remains an explicit action and keeps the existing ownership checks. Board previews use the same renderer as the match. Royal Ludo has lavender diamond panels, Carnival has a dotted pattern, Neon has a dark grid, and Classic retains plain cream panels. All five Snakes & Ladders designs can be previewed with moving tokens.

The profile catalog retains its original 12 avatar identities and purchase requirements and adds 12 free expressive avatars (24 total). Selected avatars appear in matches and animate on sixes. A six also triggers a 1.4-second celebration; reduced-motion preferences suppress movement. There are 32 emoji and 24 short phrases, with scrolling pickers and the existing chat age gate.

Each quick, local, bot, create-room, and join-room action shows the applicable rules before starting. Local and bot matches remain practice. Online rewards remain 100 coins for a win and 15 for a completed loss; leaving early earns no coins. The current daily gift (150 coins) and chest (500 coins per three online wins) are preserved. Cosmetic skins do not alter dice odds. Local Ludo no longer forces a six when all tokens are in the yard.

Match rewards, ratings, and club contributions settle once per player in a D1 batch transaction, including after a retry or room restart. Ratings stay within 0–9999. A seat taken over by a bot after resignation is recorded without coins or club contribution and cannot credit an online win to the former player.

Validation covers distinct rendered board previews, preview isolation, explicit avatar equip, locked items, cancellable pre-match rules, repeated six animations, all six local dice outcomes, and SQLite-backed settlement retries. The full Flutter suite and backend typecheck/tests are required before merging. Android CI now runs the Flutter suite before building.

Payment checkout and ad-provider configuration retain their existing availability; this change does not add a new payment integration.
