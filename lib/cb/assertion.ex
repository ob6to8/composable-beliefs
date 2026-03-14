defmodule CB.Assertion do
  @moduledoc """
  Assertion struct and JSON serialization.

  Assertions are the inspectable knowledge graph - structured claims about
  the world that the agent can query, compose, and act on. Stored in
  `org/assertions/assertions.json` as an array.

  ## Kinds

  Three assertion kinds share a single struct with kind-specific fields:

  - **primitive** - an atomic, irreducible claim grounded in a source document,
    person, or observation. Ground truth as stated by the source - even if
    physically untrue, the assertion is that the source said it. A non-reducible
    claim from a single source is one primitive even if it contains multiple
    clauses. Fields: `source`, `evidence`.
  - **compound** - a belief derived by composing two or more assertions. Has
    explicit dependencies and an `implication` field stating what the combination
    means. Fields: `deps`, `implication`.
  - **implication** - a compound whose implication identifies an action, gap, or
    requirement. Connects the knowledge system to the action system via
    `/materialize`. Fields: `deps`, `implication`, `materialized`.

  All kinds carry `subjects` linking to affected entities.

  ## Fields

  - `id` - sequential ID (`a001`, `a002`, etc.)
  - `type` - always `"assertion"`
  - `kind` - `primitive`, `compound`, or `implication`
  - `claim` - human-readable statement of what is believed
  - `source` - provenance string, primitives only (see Source Types below)
  - `evidence` - array of evidence entries, each with `date`, `source`, and
    `detail`. Append-only.
  - `confidence` - 0.0 to 1.0 (see Confidence below)
  - `subjects` - list of `%{"ref" => "path", "type" => "domain"}` linking to
    affected entities
  - `deps` - list of assertion IDs this depends on (compound/implication only)
  - `implication` - reasoning text (compound/implication only)
  - `materialized` - nil or `%{"date" => ..., "todos" => [...]}` (implication only)
  - `status` - `active`, `superseded`, or `retracted`
  - `superseded_by` - ID of the replacing assertion
  - `retracted_on` - ISO date
  - `retracted_reason` - why it was retracted
  - `created` - ISO date

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

  ## Source Types

  | Source | Meaning |
  |---|---|
  | `gmail:<thread_id>` | Email thread |
  | `<file-path>` | Document relative to `org/` |
  | `user:<person>:<date>` | User directly provided the data |
  | `manual:<person>:<date>` | Agent entered data a person provided verbally |
  | `policy` | Domain truth, not sourced from a document |
  | `legacy` | Pre-provenance data |
  """

  @kinds ~w(primitive compound implication)
  @statuses ~w(active superseded retracted)

  @fields [
    :id, :type, :kind, :claim, :source, :evidence, :confidence, :subjects,
    :deps, :implication, :materialized, :status, :superseded_by,
    :retracted_on, :retracted_reason, :created, :_keys
  ]

  @ordered_keys ~w(id type kind claim source evidence confidence subjects deps implication materialized status superseded_by retracted_on retracted_reason created)

  defstruct @fields

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t(),
          kind: String.t() | nil,
          claim: String.t() | nil,
          source: String.t() | nil,
          evidence: list(map()),
          confidence: number() | nil,
          subjects: list(map()),
          deps: list(String.t()),
          implication: String.t() | nil,
          materialized: map() | nil,
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
      evidence: map["evidence"] || [],
      confidence: map["confidence"],
      subjects: map["subjects"] || [],
      deps: map["deps"] || [],
      implication: map["implication"],
      materialized: map["materialized"],
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
