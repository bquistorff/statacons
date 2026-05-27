# frames/tests test guide

This folder contains a small test harness for the new `.dtas` / frameset support in `statacons`.

The goal is simple: make sure `statacons` notices the changes that matter in a `.dtas` file, ignores the changes that should not matter, fails clearly on broken `.dtas` files, and works both in batch mode and in interactive Stata sessions.

## In plain terms, what are these tests checking?

There are four main ideas:

1. **Stable signatures for unchanged data.** If the actual frame contents are the same, `statacons` should treat the `.dtas` file as unchanged.
2. **Changed signatures for real data changes.** If a frame is added, dropped, or edited, `statacons` should notice.
3. **Clear failures for broken `.dtas` files.** A malformed frameset should fail loudly, not be accepted quietly.
4. **Correct behavior inside a build pipeline.** When `.dtas` files are used in an SCons build, they should build correctly the first time and not rebuild on an identical second run.

## The main test files

| File | What it does | How it fits |
|---|---|---|
| `run_all.do` | Runs the batch smoke tests in sequence. | This is the simplest entry point for the batch test suite. |
| `smoke_dtas_legacy.do` | Keeps the older small-data `.dtas` signature checks that originally lived under `tests\`. | This is the migrated legacy/simple signature smoke test. |
| `smoke_dtas_blog.do` | Checks core `.dtas` signature behavior using blog-style frames workflows and shipped/vendored datasets. | This is the main "does signing behave sensibly?" test. |
| `smoke_dtas_errors.do` | Checks that malformed `.dtas` files are rejected with errors. | This is the main "fail loudly on bad input" test. |
| `smoke_scons_dtas_legacy.do` | Keeps the older small producer -> `.dtas` -> consumer SCons pipeline that originally lived under `tests\`. | This is the migrated legacy/simple end-to-end pipeline test. |
| `smoke_scons_dtas_blog.do` | Checks that `statacons` can build `.dtas` targets in SCons and does not rebuild them unnecessarily on an identical rerun. | This is the main end-to-end pipeline test. |
| `smoke_dtas_frame_order.do` | Checks that the signature is identical regardless of the order in which frames were created or listed in `frames save`. | This pins the alphabetical-sort behavior that makes signatures stable across different workflows. |
| `smoke_dtas_volatile_chars.do` | Checks that volatile dataset characteristics (e.g. a timestamp written into `_dta[lastrun]`) change the signature by default, and that `skip_char()` suppresses them. | This covers a real-world reason signatures might change without any data change. |
| `smoke_dtas_fralias.do` | Checks that framesets with `fralias` alias variables sign stably when nothing changes, and that a change to the source frame is detected. | This documents the live-alias behavior of `fralias` and confirms signatures respond to it correctly. |
| `smoke_dtas_degenerate.do` | Checks edge cases: a frameset with only one frame, and an empty frameset. | This guards against simple corner cases that the main tests skip over. |
| `smoke_stata17_fallback.do` | Checks that `complete_datasignature` exits with code 198 and emits a specific sentinel string when run under Stata 17. | This is the Stata-side half of the version-guard. It requires a Stata 17 installation and skips cleanly if none is found. |
| `interactive_roundtrip_test.do` | Manually checks that interactive Stata state is restored after signing a `.dtas` file. | This covers the special interactive-mode behavior that batch tests cannot fully check. |
| `interactive_roundtrip_legacy.do` | Keeps the older interactive round-trip checks that originally lived under `tests\`. | This is the migrated legacy/simple interactive test file. |
| `interactive_collision.do` | Manually checks that interactive state is fully restored when the user's in-memory frame names collide with frames inside the target `.dtas`. | This is the hardest interactive edge case: the restoration logic must not corrupt the user's session even when names overlap. |
| `testlib.do` | Defines small helper programs used by the other test files. | This is shared setup code, not a test by itself. |

## What each main test is looking for

### 1. `smoke_dtas_blog.do`

This file checks the basic logic of `.dtas` signatures.

It asks questions like:

- If I save the same frameset with different zip compression, do I get the same signature?
- If I add or remove a frame, does the signature change?
- If I change only one frame, does only that frame's part of the signature change?
- If I recreate the same linked or alias-based workflow twice, do I get the same result both times?
- If I save the same frames in a different order, does the signature change or not?

Why this matters: a good signature should react to **real data changes**, not to unimportant packaging differences.

### 1a. `smoke_dtas_legacy.do`

This is the older, smaller version of the signature smoke test.

It keeps three simple checks together:

- repeated save with the same content gives the same signature
- changing one frame changes the aggregate signature
- `frlink_*` metadata does not create false changes

Why keep it: it is a compact legacy regression file, and moving it here keeps the top-level `tests\` tree from carrying a separate branch-only `.dtas` smoke script.

### 2. `smoke_dtas_errors.do`

This file creates intentionally broken `.dtas` files and checks that `complete_datasignature` refuses to sign them.

It covers cases like:

- a file that is not really a zip archive
- a frameset missing its `.frameinfo` manifest
- a frameset missing one of the embedded `.dta` members
- a frameset with bad manifest contents

Why this matters: if broken inputs are accepted quietly, build results become hard to trust.

### 3. `smoke_scons_dtas_blog.do`

This file checks the build-system side.

It runs two small SCons pipelines:

- a "life expectancy" pipeline based on the frames blog examples
- a linked-frames pipeline based on the framesets/alias-variable blog post

For each pipeline, it checks that:

1. the upstream `.dtas` file can be built
2. a downstream `.dta` file can be built from that `.dtas`
3. running the exact same build again does **not** rewrite the outputs

That last check is important. It compares file modification times before and after the rerun. If those times change, the test concludes that `statacons` rebuilt something it should have left alone.

### 3a. `smoke_scons_dtas_legacy.do`

This is the older, simpler SCons pipeline check.

It uses a very small frameset:

- producer builds `legacy_myset.dtas`
- consumer reopens that frameset and writes `legacy_foreign_from_dtas.dta`

It then reruns the same build and checks that neither output was rewritten.

Why keep it: this is the smallest end-to-end `.dtas` pipeline in the harness, so it is still useful as a simple regression test.

### 4. `interactive_roundtrip_test.do`

This is a **manual** test for interactive Stata.

It checks two tricky cases:

- a user already has linked frames and alias variables in memory, and signing a `.dtas` file should not disturb that setup
- a user already has frames with names like `life1` and `life2`, and signing a `.dtas` file should not clobber them

Why this matters: interactive mode is harder than batch mode because the user's current session state has to be preserved and restored correctly.

### 4a. `interactive_roundtrip_legacy.do`

This is the older interactive round-trip file that was originally created under `tests\`.

It keeps four smaller checks:

- basic round-trip
- empty default frame restoration
- frame-count preservation
- repeated-call signature stability

Why keep it: the newer interactive file is more blog-oriented, while this one is still a useful compact set of session-restoration regressions.

### 5. `smoke_dtas_frame_order.do`

This file checks that the signing logic is independent of the order in which frames appear.

It asks three related questions:

- If I create frame A first and then frame B, versus B first and then A, but save both with `frames(A B)`, do I get the same signature?
- If I save the same two frames in opposite order -- `frames(A B)` versus `frames(B A)` -- do I still get the same signature?
- Are the slots in the signature always labelled in alphabetical frame-name order regardless of creation or save order?

**What success looks like:** all three signatures are identical, and the first slot in the aggregate signature starts with `A=` while the second starts with `B=`.

**What failure looks like:** if the signatures differ, it means the signing code is sensitive to zip entry order inside the `.dtas` archive rather than sorting frame names before hashing. That would make signatures unstable across slightly different workflows that produce the same data.

### 6. `smoke_dtas_volatile_chars.do`

This file checks how `complete_datasignature` handles dataset characteristics that are expected to change on every run -- for example, a `_dta[lastrun]` characteristic that stores a timestamp.

It builds two otherwise identical framesets, written two seconds apart, where the only difference is a `lastrun` characteristic set to the current date and time.

It then asks:

- Do those two framesets produce different signatures by default? (They should, because the timestamp is baked in.)
- If I pass `skip_char("lastrun")`, do the two signatures become identical?
- Does the glob form `skip_char("last*")` also stabilize the signatures?

**What success looks like:** default signing is timestamp-sensitive; both `skip_char` forms produce matching signatures for the otherwise-identical data.

**What failure looks like:** if the default signatures are the same despite different timestamps, the signing code is ignoring characteristics it should be including. If `skip_char` does not stabilize the signatures, the glob-matching logic is broken.

### 7. `smoke_dtas_fralias.do`

This file checks the interaction between `complete_datasignature` and `fralias` -- Stata 18's feature for creating live column aliases that point into another frame.

It builds a frameset with a `persons` frame that has a `fralias` alias column pointing into a linked `txcounty` frame.

It then asks:

- Does a repeated save of the same fralias frameset produce an identical signature? (Stability check.)
- If I mutate one value in the `txcounty` source frame and save again, does the signature change? (Detection check.)
- Does mutating `txcounty` change only the `txcounty` slot, or does it also change the `persons` slot?

**What success looks like:** signatures are stable across identical re-saves, and a mutation in the source frame is detected. As a diagnostic finding: `fralias` aliases are **live** -- they are materialized into the persons frame at `frames save` time, so mutating `txcounty` changes the `persons` slot too, not just the `txcounty` slot. The test records this finding explicitly.

**What failure looks like:** if a mutation in `txcounty` does not change the overall signature, the signing code is missing changes that flow through alias links.

### 8. `smoke_dtas_degenerate.do`

This file checks two edge cases that the main signature tests skip because they focus on multi-frame workflows.

**Subtest A: single-frame frameset.** A frameset with exactly one frame should produce a signature that starts with `framename=` and contains no `|` pipe separator. This confirms the format holds when there is nothing to concatenate.

**Subtest B: empty frameset.** Stata refuses to create an empty `.dtas` file (it requires at least one frame), so this subtest is skipped gracefully on current Stata. It is left in the file as a placeholder in case behavior changes in a future Stata version.

**What success looks like:** the single-frame signature is well-formed (no pipe, starts with the frame name), and the test exits with PASS whether or not Stata accepts an empty frameset.

**What failure looks like:** a single-frame signature containing a spurious `|` or not starting with the frame name would indicate a bug in the signature assembly logic.

### 9. `smoke_stata17_fallback.do`

This file checks the Stata-side half of the version-guard mechanism for users running Stata 17 (which lacks `frames save`/`frames use`).

It requires a real Stata 17 installation at `C:\Program Files\Stata17\`. If no such installation is found, the test prints a PASS note and exits cleanly.

When Stata 17 is present, it runs two sub-tests by invoking Stata 17 via batch files:

- **Sub-test A1: exit code.** `complete_datasignature` should exit Stata with return code 198 when called under Stata 17. This confirms the version guard is working.
- **Sub-test A2: sentinel string.** The same call (this time without `capture`) should write the string `STATACONS_REQUIRES_STATA18` to the log. This is the signal the Python layer watches for when deciding whether to fall back to MD5.

**What success looks like:** Stata 17 returns exit code 0 from the guard-runner (which itself checks that `complete_datasignature` returned 198 and exits 0 on pass, 1 on fail), and `findstr` locates the sentinel string in the nocapture log.

**What failure looks like:** if the exit code check fails, the version guard is not tripping correctly -- Stata 17 may be running without error, which would mean it is trying to sign framesets it cannot read. If the sentinel is missing, the Python fallback will not know to switch to MD5 and may report a corrupt signature instead.

**Note on sub-tests B and C** (Python-side fallback): these are deferred. They would test that `get_dtas_sign` in `stata_utils.py` detects the sentinel and falls back to MD5 under `frameset_signing: auto`, and raises a hard error under `frameset_signing: enabled`. Those tests require running a full SCons pipeline with a Stata 17 binary.

### 4b. `interactive_collision.do`

This is a **manual** test for interactive Stata 18+. Run it by opening Stata interactively from `frames/tests/` and typing `do interactive_collision.do`.

It covers the hardest interactive edge case: what happens when the user already has frames in memory with the **same names** as frames inside the `.dtas` file being signed?

The test sets up a colliding in-memory state on purpose:

- Loads a `collision_target.dtas` containing `X` (4 obs) and `Y` (4 obs).
- Then clears all frames and builds a user `X` frame with 7 observations and data values that differ from the target.
- Makes `X` the active frame.
- Calls `complete_datasignature, frameset_file("out/collision_target.dtas")`.

After the call, it checks:

- Is the active frame still named `X`?
- Does the `X` frame still have 7 observations (not 4)?
- Is `v[1]` still the pre-call value (not overwritten by the target data)?

**What success looks like:** all three checks pass -- the user's colliding session is fully restored and the target `.dtas` was signed without corrupting in-memory state.

**What failure looks like:** if any check fails, the round-trip logic has a bug in the collision case. The most common failure mode would be that the user's `X` frame is left with 4 observations (the target data) rather than the original 7.

## The small do-files in `code/`

These are tiny fixture scripts used by the SCons smoke test.

| File | What it does | How it fits |
|---|---|---|
| `code/dtas_blog_life_producer.do` | Builds `outputs/life_blog.dtas` from three official Stata example datasets. | Upstream producer for the life-expectancy SCons pipeline. |
| `code/dtas_blog_life_consumer.do` | Opens `outputs/life_blog.dtas` and saves a smaller `.dta` derived from one frame. | Downstream consumer for the life-expectancy SCons pipeline. |
| `code/dtas_legacy_producer.do` | Builds `outputs/legacy_myset.dtas` from a small split of `sysuse auto`. | Upstream producer for the migrated legacy/simple SCons pipeline. |
| `code/dtas_legacy_consumer.do` | Opens `outputs/legacy_myset.dtas` and saves a derived `.dta` from the foreign-cars frame. | Downstream consumer for the migrated legacy/simple SCons pipeline. |
| `code/dtas_linked_producer.do` | Builds `outputs/linked_project.dtas` from linked `persons` and `txcounty` data. | Upstream producer for the linked-frames SCons pipeline. |
| `code/dtas_linked_consumer.do` | Opens `outputs/linked_project.dtas`, computes an income ratio, and saves a regular `.dta`. | Downstream consumer for the linked-frames SCons pipeline. |

## Supporting files

These are not do-files, but they help the tests run:

| File | What it does |
|---|---|
| `SConstruct-life` | SCons recipe for the life-expectancy pipeline. |
| `SConstruct-linked` | SCons recipe for the linked-frames pipeline. |
| `SConstruct-legacy` | SCons recipe for the migrated legacy/simple `.dtas` pipeline. |
| `SConstruct` | Older combined SCons fixture kept in the folder. |
| `make_malformed_dtas.py` | Creates broken `.dtas` files for the error tests. |
| `logs/` | Stores SMCL logs written by the SCons smoke test. |
| `outputs/` | Stores temporary test outputs created during runs. |

## How the pieces fit together

If you want the shortest mental model, think of the test harness like this:

- `smoke_dtas_blog.do` asks: **Are the signatures themselves sensible?**
- `smoke_dtas_legacy.do` asks: **Do the old small-data signature regressions still pass?**
- `smoke_dtas_errors.do` asks: **Do broken framesets fail clearly?**
- `smoke_scons_dtas_legacy.do` asks: **Does the old simple `.dtas` pipeline still work and stay a no-op on rerun?**
- `smoke_scons_dtas_blog.do` asks: **Does the build pipeline behave correctly?**
- `smoke_dtas_frame_order.do` asks: **Is the signature independent of frame creation and save order?**
- `smoke_dtas_volatile_chars.do` asks: **Does `skip_char()` correctly suppress volatile metadata?**
- `smoke_dtas_fralias.do` asks: **Are signatures stable for fralias framesets, and are live-alias changes detected?**
- `smoke_dtas_degenerate.do` asks: **Does signing handle a single frame (or no frames) gracefully?**
- `smoke_stata17_fallback.do` asks: **Does the version guard fire correctly under Stata 17?**
- `interactive_roundtrip_test.do` asks: **Does this still behave correctly in a live interactive session?**
- `interactive_roundtrip_legacy.do` asks: **Do the older interactive restoration checks still pass?**
- `interactive_collision.do` asks: **Is the user's session fully restored when their frame names collide with the target `.dtas`?**

And `run_all.do` is simply the batch runner that ties the non-interactive smoke tests together.

## Practical reading order

If you are new to this folder, a good order is:

1. `README-tests.md` -- this overview
2. `smoke_dtas_legacy.do` -- the smallest legacy signature checks
3. `smoke_dtas_blog.do` -- the richer signature ideas
4. `smoke_dtas_errors.do` -- the bad-input checks
5. `smoke_scons_dtas_legacy.do` -- the smallest SCons pipeline
6. `smoke_scons_dtas_blog.do` -- the richer end-to-end build check
7. `smoke_dtas_frame_order.do` -- frame ordering edge case
8. `smoke_dtas_volatile_chars.do` -- volatile characteristics edge case
9. `smoke_dtas_fralias.do` -- live alias edge case
10. `smoke_dtas_degenerate.do` -- single-frame and empty-frameset edge cases
11. `smoke_stata17_fallback.do` -- version guard edge case (Stata 17)
12. `interactive_roundtrip_legacy.do` and `interactive_roundtrip_test.do` -- interactive session restoration
13. `interactive_collision.do` -- the hardest interactive edge case (name collisions)

That order goes from the simplest ideas to the trickiest ones.
