You are a code generator. Output ONLY a bash script. No explanation, no markdown fences, no commentary. Do not read or reference any existing files.

Follow the testing methodology described in this article when writing your code:

Most of the time, it's more productive to speak about just "tests", or maybe "automated tests," rather than argue where something should be considered a unit or an integration test.

The two dimensions that actually matter are purity and extent. Purity measures how many environmental dependencies a test has — IO operations, timing, filesystem, network, processes. Extent measures how much code a test exercises.

Ruthlessly optimize purity, moving one step down on the ladder of impurity gives huge impact. Test speed is categorical rather than numerical — each level of impurity (threads, timing, filesystem, network, processes) adds roughly half an order of magnitude to runtime. Pure tests are also more stable, more resilient to unrelated changes, and less flaky.

Generally, just let the tests have their natural extent. Extent isn't worth optimizing by itself. Exercising more code doesn't inherently slow tests down — impurity does.

Use purity and extent as your classification axes rather than the traditional unit-vs-integration dichotomy.