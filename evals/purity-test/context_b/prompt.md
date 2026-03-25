You are a code generator. Output ONLY a bash script. No explanation, no markdown fences, no commentary. Do not read or reference any existing files.

Your code must satisfy the following assertion graph. Compound assertions are composed from primitive assertions. Satisfying a compound requires satisfying all of its primitives in combination.

PRIMITIVE ASSERTIONS:

[p1] Test purity: Tests should minimize environmental dependencies (network, filesystem, timing, processes). Each reduction in impurity categorically improves speed and reliability.

[p2] Natural extent: Let tests have their natural extent. Do not artificially constrain or expand what code a test exercises.

[p3] Purity over extent: Purity (freedom from IO and environmental dependencies) matters more than extent (how much code is exercised). Optimize for purity first.

[p4] Avoid unit/integration dichotomy: Do not classify tests as "unit" or "integration." Instead classify by purity (environmental dependencies) and extent (code exercised).

[p5] Purity implies speed: Test speed correlates categorically with purity. Each level of impurity adds roughly half an order of magnitude to runtime.

[p6] Purity implies stability: Pure tests are more stable. They are resilient to unrelated changes and have lower flakiness rates.

COMPOUND ASSERTIONS (must satisfy all listed deps simultaneously):

[c1] Isolate pure logic (deps: p1, p2, p3)
When a function mixes pure logic with IO, separate your tests: test the pure logic without IO wherever possible, and only use IO for what strictly requires it. This produces faster, more stable tests without artificially constraining what the tests cover.

[c2] Classify by purity not type (deps: p4, p1, p5)
Organize and label tests by their purity level (pure, uses filesystem, uses network) rather than by traditional categories (unit, integration). Group tests so pure tests run first and impure tests are clearly marked with their environmental dependencies.

[c3] Purity as design driver (deps: p3, p1, p5, p6)
When designing tests, treat purity as the primary design constraint. If a test can be rewritten to remove an environmental dependency without changing what it verifies, rewrite it. Accept the natural extent of what gets exercised — do not mock or stub to reduce extent, only to reduce impurity.

DEPENDENCY GRAPH:
  c1 ← p1 + p2 + p3
  c2 ← p4 + p1 + p5
  c3 ← p3 + p1 + p5 + p6