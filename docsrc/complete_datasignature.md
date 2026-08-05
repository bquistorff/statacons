_version 3.1.0_

complete_datasignature
======

__complete_datasignature__ creates a signature for a Stata .dta-file or .dtas frameset that does __not__ depend on the embedded timestamp but __does__ depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

__complete_datasignature__ extends Stata's __datasignature__ by allowing the inclusion of different sets of metadata. When called with __frameset_file__, it signs every frame in a __.dtas__ frameset and returns a concatenation keyed by frame name.


Syntax
------

> complete_datasignature [, dta_file("file.dta") frameset_file("file.dtas") fname("sigfile.ext") nometa fast labels_formats_only skip_char("globlist")]


By default, __complete_datasignature__ will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

### Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| dta_file("file.dta")           | Use  "file.dta"  instead of dta-file in memory       |
| frameset_file("file.dtas")     | Sign a __.dtas__ frameset; iterate frames alphabetically and return "frameA=sigA|frameB=sigB|..." |
| fname("sigfile.ext")           | write signature to "sigfile.ext"     |
| nometa                     | Do not include any metadata -- equivalent of Stata's __datasignature__          |
| labels_formats_only             | Include variable formats, variable and value labels               |
| fast          | use ___datasignature__ in _fast_ mode -- faster but not machine-independent                       |
| skip_char("globlist")     | Skip variable/dataset characteristics whose names match any pattern in the space-separated globlist. The __frameset_file__ path always adds __frlink_*__ to this list. |


### Behavior of __frameset_file__

When __frameset_file__ is set, the program:

1. In interactive mode (__c(mode)__ is empty), saves all in-memory frames to a temporary __.dtas__ so user state can be restored on exit. In batch mode, this round-trip is skipped.
2. Loads the target __.dtas__ via __frames use, clear__.
3. For each frame in alphabetical order, computes a per-frame signature using the same metadata options (__nometa__, __fast__, __labels_formats_only__) plus __skip_char("frlink_*")__.
4. Assembles "frameA=sigA|frameB=sigB|...".
5. In interactive mode, restores the user's frames from the temporary __.dtas__, including the previously-active frame.

Example(s)
----------


            . sysuse auto
    (1978 automobile data)
            . datasignature
    74:12(71728):3831085005:1395876116
            . complete_datasignature, nometa
    74:12(71728):3831085005:1395876116
            . complete_datasignature, labels_formats_only
    74:12(71728):3831085005:1395876116:2144891519
            . complete_datasignature
    74:12(71728):3831085005:1395876116:711253444
            . ret li
    macros:
             r(signature) : "74:12(71728):3831085005:1395876116:711253444"
             . _datasignature, fast
           74:12(71728):3831085005:186045760
             . complete_datasignature, nometa fast
    74:12(71728):3831085005:186045760

            . complete_datasignature, frameset_file("myframeset.dtas")
    census=74:12(71728):...|housing=50:12(...):...




Stored results
----------------

__r(signature)__    signature calculated by __complete_datasignature__

Author
------

__statacons__ team
[https://github.com/bquistorff/statacons](https://github.com/bquistorff/statacons)


- - -

This help file was dynamically produced by
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/)

