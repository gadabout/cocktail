defmodule Cocktail.Span do
  @moduledoc """
  Struct used to represent a span of time.

  It is composed of the following fields:
  * from: the start time of the span
  * until: the end time of the span

  When expanding a `t:Cocktail.Schedule.t/0`, if it has a duration it will
  produce a list of `t:t/0` instead of a list of `t:Cocktail.time/0`.
  """

  @type t :: %__MODULE__{from: Cocktail.time(), until: Cocktail.time()}

  @type span_compat :: %{:from => Cocktail.time(), :until => Cocktail.time(), optional(atom) => any}

  @type overlap_mode ::
          :contains
          | :is_inside
          | :is_before
          | :is_after
          | :is_equal_to
          | :overlaps_the_start_of
          | :overlaps_the_end_of

  @enforce_keys [:from, :until]
  defstruct from: nil,
            until: nil

  @doc """
  Creates a new `t:t/0` from the given start time and end time.

  ## Examples

      iex> new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      %Cocktail.Span{from: ~N[2017-01-01 06:00:00], until: ~N[2017-01-01 10:00:00]}
  """
  @spec new(Cocktail.time(), Cocktail.time()) :: t
  def new(from, until), do: %__MODULE__{from: from, until: until}

  @doc """
  Uses `Cocktail.Time.compare/2` to determine which span comes first.

  Compares `from` first, then, if equal, compares `until`.

  ## Examples

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> span2 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> compare(span1, span2)
      :eq

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> span2 = new(~N[2017-01-01 07:00:00], ~N[2017-01-01 12:00:00])
      ...> compare(span1, span2)
      :lt

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> span2 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 07:00:00])
      ...> compare(span1, span2)
      :gt
  """
  @spec compare(span_compat, span_compat) :: :lt | :eq | :gt
  def compare(%{from: t, until: until1}, %{from: t, until: until2}), do: Cocktail.Time.compare(until1, until2)
  def compare(%{from: from1}, %{from: from2}), do: Cocktail.Time.compare(from1, from2)

  @doc """
  Returns an `t:overlap_mode/0` to describe how the first span overlaps the second.

  ## Examples

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> span2 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> overlap_mode(span1, span2)
      :is_equal_to

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> span2 = new(~N[2017-01-01 07:00:00], ~N[2017-01-01 09:00:00])
      ...> overlap_mode(span1, span2)
      :contains

      iex> span1 = new(~N[2017-01-01 07:00:00], ~N[2017-01-01 09:00:00])
      ...> span2 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 10:00:00])
      ...> overlap_mode(span1, span2)
      :is_inside

      iex> span1 = new(~N[2017-01-01 06:00:00], ~N[2017-01-01 07:00:00])
      ...> span2 = new(~N[2017-01-01 09:00:00], ~N[2017-01-01 10:00:00])
      ...> overlap_mode(span1, span2)
      :is_before
  """
  @spec overlap_mode(span_compat, span_compat) :: overlap_mode
  def overlap_mode(%{from: from, until: until}, %{from: from, until: until}), do: :is_equal_to

  # credo:disable-for-next-line
  def overlap_mode(%{from: from1, until: until1}, %{from: from2, until: until2}) do
    from_comp = Cocktail.Time.compare(from1, from2)
    until_comp = Cocktail.Time.compare(until1, until2)

    cond do
      from_comp in [:lt, :eq] && until_comp in [:gt, :eq] -> :contains
      from_comp in [:gt, :eq] && until_comp in [:lt, :eq] -> :is_inside
      Cocktail.Time.compare(until1, from2) in [:lt, :eq] -> :is_before
      Cocktail.Time.compare(from1, until2) in [:gt, :eq] -> :is_after
      from_comp == :lt && until_comp == :lt -> :overlaps_the_start_of
      from_comp == :gt && until_comp == :gt -> :overlaps_the_end_of
    end
  end
end
