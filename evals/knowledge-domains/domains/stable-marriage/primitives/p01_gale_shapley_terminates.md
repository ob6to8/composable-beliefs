---
tags: [algorithm, matching, stability, termination]
domain: stable-marriage
type: math
contestability: none
---

# p01: Gale-Shapley always terminates in a stable matching

The Gale-Shapley algorithm, given complete preference rankings from both sides, always terminates and always produces a stable matching — one where no two people would mutually prefer each other to their assigned partners.

This is proven. The algorithm makes at most N² proposals before terminating.
