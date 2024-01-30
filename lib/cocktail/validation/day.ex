defmodule Cocktail.Validation.Day do
  @moduledoc false

  import Integer, only: [mod: 2]
  import Cocktail.Validation.Shift
  import Cocktail.Util, only: [next_gte: 2]

  @type t :: %__MODULE__{days: [Cocktail.day_number()]}

  @enforce_keys [:days]
  defstruct days: []

  @spec new([Cocktail.day()]) :: t
  def new(days), do: %__MODULE__{days: days |> Enum.map(&day_number/1) |> Enum.sort()}

  @spec next_time(t, Cocktail.time(), Cocktail.time()) :: Cocktail.Validation.Shift.result()
  def next_time(%__MODULE__{days: days}, time, _) do
    {current_day, _, _} = Calendar.ISO.day_of_week(time.year, time.month, time.day, :sunday)
    current_day = current_day - 1
    day = next_gte(days, current_day) || hd(days)
    diff = (day - current_day) |> mod(7)

    shift_by(diff, :day, time, :beginning_of_day)
  end

  @spec day_number(Cocktail.day()) :: Cocktail.day_number()
  defp day_number(:sunday), do: 0
  defp day_number(:monday), do: 1
  defp day_number(:tuesday), do: 2
  defp day_number(:wednesday), do: 3
  defp day_number(:thursday), do: 4
  defp day_number(:friday), do: 5
  defp day_number(:saturday), do: 6
  defp day_number(day) when is_integer(day), do: day
end
