defmodule Cocktail.Validation.DayOfMonth do
  @moduledoc false

  import Cocktail.Validation.Shift
  import Cocktail.Util

  # assumed that DST can not "take" more than 4 hours between any 2 consecutive days
  @min_dst_resultant_hours 20

  @type t :: %__MODULE__{days: [Cocktail.day_of_month()]}

  @enforce_keys [:days]
  defstruct days: []

  @spec new([Cocktail.day()]) :: t
  def new(days), do: %__MODULE__{days: days}

  @spec next_time(t, Cocktail.time(), Cocktail.time()) :: Cocktail.Validation.Shift.result()
  def next_time(%__MODULE__{days: days}, time, _) do
    current_day_of_month = time.day

    normalized_days =
      days
      |> Enum.sort()
      |> Enum.map(&normalize_day_of_month(&1, time))

    diff =
      case next_gte(normalized_days, current_day_of_month) do
        # go to next month
        nil ->
          next_month_time = shift_time(time, months: 1)

          next_month_normalized_days = Enum.map(days, &normalize_day_of_month(&1, next_month_time))
          next_month_earliest_day = Timex.set(next_month_time, day: hd(Enum.sort(next_month_normalized_days)))
          dst_accounted_days_diff(next_month_earliest_day, time)

        next_earliest_day_of_month ->
          next_earliest_day_of_month - current_day_of_month
      end

    shift_by(diff, :days, time, :beginning_of_day)
  end

  defp normalize_day_of_month(day_of_month, current_time) do
    do_normalize_day_of_month(day_of_month, Timex.days_in_month(current_time))
  end

  defp do_normalize_day_of_month(day_of_month, days_in_month) when day_of_month > days_in_month do
    days_in_month
  end

  defp do_normalize_day_of_month(day_of_month, _days_in_month) when day_of_month > 0 do
    day_of_month
  end

  defp do_normalize_day_of_month(day_of_month, days_in_month) when -day_of_month > days_in_month do
    1
  end

  defp do_normalize_day_of_month(day_of_month, days_in_month) when day_of_month < 0 do
    days_in_month + day_of_month + 1
  end

  defp dst_accounted_days_diff(next_month_earliest_day, time) do
    case Timex.diff(next_month_earliest_day, time, :days) do
      0 ->
        # get the hours diff to ensure we are not falling short because of DST
        if Timex.diff(next_month_earliest_day, time, :hours) > @min_dst_resultant_hours do
          1
        else
          0
        end

      days_diff ->
        days_diff
    end
  end
end
