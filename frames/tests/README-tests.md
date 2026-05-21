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
| `smoke_dtas_blog.do` | Checks core `.dtas` signature behavior using blog-style frames workflows and shipped/vendored datasets. | This is the main "does signing behave sensibly?" test. |
| `smoke_dtas_errors.do` | Checks that malformed `.dtas` files are rejected with errors. | This is the main "fail loudly on bad input" test. |
| `smoke_scons_dtas_blog.do` | Checks that `statacons` can build `.dtas` targets in SCons and does not rebuild them unnecessarily on an identical rerun. | This is the main end-to-end pipeline test. |
| `interactive_roundtrip_test.do` | Manually checks that interactive Stata state is restored after signing a `.dtas` file. | This covers the special interactive-mode behavior that batch tests cannot fully check. |
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

### 4. `interactive_roundtrip_test.do`

This is a **manual** test for interactive Stata.

It checks two tricky cases:

- a user already has linked frames and alias variables in memory, and signing a `.dtas` file should not disturb that setup
- a user already has frames with names like `life1` and `life2`, and signing a `.dtas` file should not clobber them

Why this matters: interactive mode is harder than batch mode because the user's current session state has to be preserved and restored correctly.

## The small do-files in `code/`

These are tiny fixture scripts used by the SCons smoke test.

| File | What it does | How it fits |
|---|---|---|
| `code/dtas_blog_life_producer.do` | Builds `outputs/life_blog.dtas` from three official Stata example datasets. | Upstream producer for the life-expectancy SCons pipeline. |
| `code/dtas_blog_life_consumer.do` | Opens `outputs/life_blog.dtas` and saves a smaller `.dta` derived from one frame. | Downstream consumer for the life-expectancy SCons pipeline. |
| `code/dtas_linked_producer.do` | Builds `outputs/linked_project.dtas` from linked `persons` and `txcounty` data. | Upstream producer for the linked-frames SCons pipeline. |
| `code/dtas_linked_consumer.do` | Opens `outputs/linked_project.dtas`, computes an income ratio, and saves a regular `.dta`. | Downstream consumer for the linked-frames SCons pipeline. |

## Supporting files

These are not do-files, but they help the tests run:

| File | What it does |
|---|---|
| `SConstruct-life` | SCons recipe for the life-expectancy pipeline. |
| `SConstruct-linked` | SCons recipe for the linked-frames pipeline. |
| `SConstruct` | Older combined SCons fixture kept in the folder. |
| `make_malformed_dtas.py` | Creates broken `.dtas` files for the error tests. |
| `logs/` | Stores SMCL logs written by the SCons smoke test. |
| `outputs/` | Stores temporary test outputs created during runs. |

## How the pieces fit together

If you want the shortest mental model, think of the test harness like this:

- `smoke_dtas_blog.do` asks: **Are the signatures themselves sensible?**
- `smoke_dtas_errors.do` asks: **Do broken framesets fail clearly?**
- `smoke_scons_dtas_blog.do` asks: **Does the build pipeline behave correctly?**
- `interactive_roundtrip_test.do` asks: **Does this still behave correctly in a live interactive session?**

And `run_all.do` is simply the batch runner that ties the first three together.

## Practical reading order

If you are new to this folder, a good order is:

1. `README-tests.md` -- this overview
2. `smoke_dtas_blog.do` -- the core signature ideas
3. `smoke_dtas_errors.do` -- the bad-input checks
4. `smoke_scons_dtas_blog.do` -- the end-to-end build check
5. `interactive_roundtrip_test.do` -- the interactive-only edge cases

That order goes from the simplest ideas to the trickiest ones.
