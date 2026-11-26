# R44.6 indexed query parent RED

Application source: `7c3caaffd2bd476463d57a4f309feca5d7e2077e`. The two candidate reader assertions were applied temporarily to this parent. The successful empty query and framework exception both incorrectly returned `INELIGIBLE`; each assertion failed for the expected result-code mismatch. The candidate fix and tests are on application branch `implement/r44-6-android17-orb`. These are local JVM unit-test transcripts, not phone screen data or Android compositor evidence.
