CLAIM: Red fruit enables reproduction
PRIMITIVES_CHAIN:
  subclaim basic_a ("Apples are red fruit"):
    - p1_apples_are_fruit.md: "Apples are botanically classified as fruit"
    - p3_red_is_color.md: "Red is a visible color wavelength"
    - p6_apples_are_red.md: "Apples are often red"
  subclaim basic_b ("Seeds enable reproduction"):
    - p2_fruit_has_seeds.md: "Botanical fruit contains seeds"
    - p4_seeds_enable_reproduction.md: "Seeds enable plant reproduction"
DEPTH: 2
CONFIDENCE: absolute
VALID: YES
REASON: All dependencies resolve through two subclaims to five existing primitives, all with absolute confidence. The AND-type claim chains correctly — basic_a establishes that apples are red fruit (via p1, p3, p6) and basic_b establishes that seeds enable reproduction (via p2, p4), jointly supporting the top-level claim that red fruit enables reproduction.
