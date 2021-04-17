defmodule WorkloadReportsGeneratorParallelism do
  alias WorkloadReportsGeneratorParallelism.Parser

  @names [
    "Daniele",
    "Mayk",
    "Giuliano",
    "Cleiton",
    "Jakeliny",
    "Joseph",
    "Diego",
    "Danilo",
    "Rafael",
    "Vinicius"
  ]

  @months [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ]

  @years [
    2016,
    2017,
    2018,
    2019,
    2020
  ]

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report ->
      sum_values(line, report)
    end)
  end

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report ->
      sum_reports(report, result)
    end)
  end

  defp sum_values([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = Map.put(all_hours, name, all_hours[name] + hours)

    # Build report by name and month
    month = Enum.at(@months, month - 1)
    months_map = Map.put(hours_per_month[name], month, hours_per_month[name][month] + hours)
    hours_per_month = Map.put(hours_per_month, name, months_map)

    # build report by name and year
    years_map = Map.put(hours_per_year[name], year, hours_per_year[name][year] + hours)
    hours_per_year = Map.put(hours_per_year, name, years_map)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)

    hours_per_month =
      Map.merge(hours_per_month1, hours_per_month2, fn _key, value1, value2 ->
        Map.merge(value1, value2, fn _key, x, y -> x + y end)
      end)

    hours_per_year =
      Map.merge(hours_per_year1, hours_per_year2, fn _key, value1, value2 ->
        Map.merge(value1, value2, fn _key, x, y -> x + y end)
      end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp report_acc do
    all_hours = Enum.into(@names, %{}, &{&1, 0})

    hours_per_month =
      Enum.into(@names, %{}, fn name ->
        {name, Enum.into(@months, %{}, &{&1, 0})}
      end)

    hours_per_year =
      Enum.into(@names, %{}, fn name ->
        {name, Enum.into(@years, %{}, &{&1, 0})}
      end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
