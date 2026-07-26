clear all
// Legacy/simple producer fixture migrated from tests\code\dtas_producer.do.
// It splits sysuse auto into foreign and domestic frames, then saves a
// small frameset for the legacy SCons smoke pipeline.
sysuse auto, clear
frame put * if foreign == 1, into(foreign_cars)
frame put * if foreign == 0, into(domestic_cars)
frames save "outputs/legacy_myset.dtas", frames(default foreign_cars domestic_cars) replace
