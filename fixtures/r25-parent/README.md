# R25 parent JVM ordering control

Apply `KeyguardR25ParentOrderingTest.kt` under the matching package in the exact
application parent `ad1eac09442cb8d78a992874d22157fe6bd5a05f`, then run
`:app:testDebugUnitTest --tests '*KeyguardR25ParentOrderingTest'`. It models the
parent's queue and held Main continuation using explicit executor barriers;
it does not substitute for a live service, real accessibility read or pixels.
The expected parent result is RED at the B-start-before-release assertion.
