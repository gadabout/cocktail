defmodule Cocktail.Validation.Interval do
  @moduledoc false

  import Integer, only: [mod: 2]
  import Cocktail.Validation.Shift

  @typep interval_shift_type :: :weeks | :days | :hours | :minutes | :seconds

  @type t :: %__MODULE__{type: Cocktail.frequency, interval: pos_integer}

  @enforce_keys [:type, :interval]
  defstruct type:     nil,
            interval: nil

  @spec new(Cocktail.frequency, pos_integer) :: t
  def new(type, interval), do: %__MODULE__{type: type, interval: interval}

  @spec next_time(t, DateTime.t, DateTime.t) :: Cocktail.Validation.Shift.result
  def next_time(%__MODULE__{type: :weekly, interval: interval}, time, start_time), do: apply_interval(time, start_time, interval, :weeks)
  def next_time(%__MODULE__{type: :daily, interval: interval}, time, start_time), do: apply_interval(time, start_time, interval, :days)
  def next_time(%__MODULE__{type: :hourly, interval: interval}, time, start_time), do: apply_interval(time, start_time, interval, :hours)
  def next_time(%__MODULE__{type: :minutely, interval: interval}, time, start_time), do: apply_interval(time, start_time, interval, :minutes)
  def next_time(%__MODULE__{type: :secondly, interval: interval}, time, start_time), do: apply_interval(time, start_time, interval, :seconds)

  @spec apply_interval(DateTime.t, DateTime.t, pos_integer, interval_shift_type) :: Cocktail.Validation.Shift.result
  defp apply_interval(time, _, 1, _), do: {:no_change, time}
  defp apply_interval(time, start_time, interval, :weeks) do
    # FIXME: there are some bugs here regarding start of week (Sunday vs. Monday),
    # and rollover (since a year has 52 OR 53 weeks in it, depending on the year)
    {_, start_weeknum} = Timex.iso_week(start_time)
    {_, current_weeknum} = Timex.iso_week(time)
    diff = current_weeknum - start_weeknum
    off_by = mod(diff, interval)

    shift_by(off_by * 7, :days, time)
  end
  defp apply_interval(time, start_time, interval, :days) do
    date = DateTime.to_date(time)
    start_date = DateTime.to_date(start_time)

    diff =
      start_date
      |> Timex.diff(date, :days)
      |> mod(interval)

    shift_by(diff, :days, time)
  end
  defp apply_interval(time, start_time, interval, type) do
    start_time
    |> Timex.diff(time, type)
    |> mod(interval)
    |> shift_by(type, time)
  end
end