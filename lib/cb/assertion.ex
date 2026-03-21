defmodule CB.Assertion do
  @moduledoc """
  Assertion struct and JSON serialization.

  Assertions are the inspectable knowledge graph - structured claims about
  the world that the agent can query, compose, and act on. Stored in
  `org/assertions/assertions.json` as an array.

  ## Kinds

  Four assertion kinds share a single struct with kind-specific fields:

  - **primitive** - an atomic, irreducible claim grounded in a source document,
    person, or observation. Ground truth as stated by the source - even if
    physically untrue, the assertion is that the source said it. A non-reducible
    claim from a single source is one primitive even if it contains multiple
    clauses. Fields: `source`, `quote`, `evidence`.
  - **compound** - a belief derived by composing two or more assertions. Has
    explicit dependencies and an `implication` field stating what the combination
    means. Fields: `deps`, `implication`.
  - **implication** - a compound whose implication identifies an action, gap, or
    requirement. Connects the knowledge system to the action system via
    `/materialize`. Fields: `deps`, `implication`, `materialized`.
  - **patch** - a traversal path through DAG nodes that presents an argument
    structurally rather than rhetorically. Like a modular synthesizer patch -
    the routing IS the argument. The reader traverses the nodes and derives
    their own conclusion from the evidence. Patches accumulate eval conclusions
    from independent sources; confidence is empirical (derived from eval
    agreement) rather than author-assessed.
    Fields: `routing`, `deps`, `conclusion`, `evals`.

  All kinds carry `subjects` linking to affected entities.

  ## Shared fields

  - `id` - sequential ID (`a001`, `a002`, etc.)
  - `type` - always `"assertion"`
  - `kind` - `primitive`, `compound`, `implication`, or `patch`
  - `claim` - human-readable statement of what is believed
  - `confidence` - 0.0 to 1.0, or nil for patches (see Confidence below)
  - `subjects` - list of `%{"ref" => "path", "type" => "domain"}` linking to
    affected entities
  - `evidence` - array of evidence entries, each with `date`, `source`, and
    `detail`. Append-only.
  - `status` - `active`, `superseded`, or `retracted`
  - `created` - ISO date

  ## Primitive-specific fields

  - `source` - provenance string (see Source Types below)
  - `quote` - verbatim source text, nil if source isn't quotable

  ## Compound/Implication-specific fields

  - `deps` - list of assertion IDs this depends on
  - `implication` - reasoning text (what the combination of deps means)

  ## Implication-specific fields

  - `materialized` - nil or `%{"date" => ..., "todos" => [...]}}`

  ## Patch-specific fields

  - `routing` - the traversal diagram (layers, flow, node ordering)
  - `deps` - IDs of all assertions the patch routes through
  - `conclusion` - meta-conclusion derived from evals, nil until sufficient evals
  - `evals` - list of eval entries, each with `source`, `conclusion`,
    `agrees_with_author`, and `notes`

  ## Terminal state fields

  - `superseded_by` - ID of the replacing assertion
  - `retracted_on` - ISO date
  - `retracted_reason` - why it was retracted

  ## Immutability

  Assertions are never edited or deleted. Terminal states only:

  | Status | Meaning |
  |---|---|
  | `active` | Currently believed to be true |
  | `superseded` | Replaced by a newer assertion (link via `superseded_by`) |
  | `retracted` | Found to be wrong (no replacement) |

  ## Confidence

  | Score | Meaning |
  |---|---|
  | 1.0 | Confirmed by authoritative source, specific and unambiguous |
  | 0.9 | Strong source but could change or has minor uncertainty |
  | 0.7 | Reasonable belief with some ambiguity |
  | 0.5 | Plausible but unconfirmed |
  | 0.3 | Weak signal, speculative |
  | 0.0 | Placeholder, known to be incomplete |

  Confidence does not propagate mechanically from deps to compounds.
  Patch confidence is derived from eval agreement, not author-assessed.

  ## Source Types

  | Source | Meaning |
  |---|---|
  | `gmail:<thread_id>` | Email thread |
  | `<file-path>` | Document relative to `org/` |
  | `user:<person>:<date>` | User directly provided the data |
  | `manual:<person>:<date>` | Agent entered data a person provided verbally |
  | `policy` | Domain truth, not sourced from a document |
  | `legacy` | Pre-provenance data |
  | `https://<url>` | External URL |
  | `analysis:<slug>` | Agent/user-generated analysis |
  | `transcript:<slug>` | Conversation transcript |
  | `paper:<slug>` | Academic paper or research |
  """

  @kinds ~w(primitive compound implication patch)
  @statuses ~w(active superseded retracted)

  @fields [
    :id, :type, :kind, :claim, :source, :quote, :evidence, :confidence,
    :subjects, :deps, :implication, :materialized, :routing, :conclusion,
    :evals, :status, :superseded_by, :retracted_on, :retracted_reason,
    :created, :_keys
  ]

  @ordered_keys ~w(id type kind claim source quote evidence confidence subjects deps implication materialized routing conclusion evals status superseded_by retracted_on retracted_reason created)

  defstruct @fields

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t(),
          kind: String.t() | nil,
          claim: String.t() | nil,
          source: String.t() | nil,
          quote: String.t() | nil,
          evidence: list(map()),
          confidence: number() | nil,
          subjects: list(map()),
          deps: list(String.t()),
          implication: String.t() | nil,
          materialized: map() | nil,
          routing: String.t() | nil,
          conclusion: String.t() | nil,
          evals: list(map()),
          status: String.t() | nil,
          superseded_by: String.t() | nil,
          retracted_on: String.t() | nil,
          retracted_reason: String.t() | nil,
          created: String.t() | nil,
          _keys: MapSet.t() | nil
        }

  @doc "Valid assertion kinds."
  def kinds, do: @kinds

  @doc "Valid status values."
  def statuses, do: @statuses

  @doc "Convert a JSON map (string keys) to an Assertion struct."
  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      type: map["type"] || "assertion",
      kind: map["kind"],
      claim: map["claim"],
      source: map["source"],
      quote: map["quote"],
      evidence: map["evidence"] || [],
      confidence: map["confidence"],
      subjects: map["subjects"] || [],
      deps: map["deps"] || [],
      implication: map["implication"],
      materialized: map["materialized"],
      routing: map["routing"],
      conclusion: map["conclusion"],
      evals: map["evals"] || [],
      status: map["status"],
      superseded_by: map["superseded_by"],
      retracted_on: map["retracted_on"],
      retracted_reason: map["retracted_reason"],
      created: map["created"],
      _keys: MapSet.new(Map.keys(map))
    }
  end

  @doc "Convert an Assertion struct to a `Jason.OrderedObject` for serialization."
  def to_map(%__MODULE__{} = a) do
    present_keys = a._keys || MapSet.new(@ordered_keys)

    pairs =
      for key <- @ordered_keys, MapSet.member?(present_keys, key) do
        atom = String.to_existing_atom(key)
        {key, Map.get(a, atom)}
      end

    Jason.OrderedObject.new(pairs)
  end
end
