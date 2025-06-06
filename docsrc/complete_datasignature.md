_version 3.0.3_

complete_datasignature
======

__complete_datasignature__ creates a signature for a Stata .dta-file that does __not__ depend on the embedded timestamp but __does__ depend on the data and, optionally, no other metadata, variable and value labels only, or all metadata.

__complete_datasignature__ extends Stata's __datasignature__ by allowing the inclusion of different sets of metadata.


Syntax
------

> complete_datasignature [, dta_file("file.dta") fname("sigfile.ext") nometa fast labels_formats_only]


By default, __complete_datasignature__ will use the dta-file in memory to create create a signature that depends on the data and all metadata, but not the embedded timestamp.

### Options

| Option                     | Description                                        |
|----------------------------|----------------------------------------------------|
| dta_file("file.dta")           | Use  "file.dta"  instead of dta-file in memory       |
| fname("sigfile.ext")           | write signature to "sigfile.ext"     |
| nometa                     | Do not include any metadata -- equivalent of Stata's __datasignature__          |
| labels_formats_only             | Include variable formats, variable and value labels               |
| fast          | use ___datasignature__ in _fast_ mode -- faster but not machine-independent                       |



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

