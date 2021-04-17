defmodule WorkloadReportsGeneratorParallelism.Parser do
  def parse_file(filename) do
    "reports/#{filename}"
    |> File.stream!()
    |> Stream.map(&parse_line/1)
  end

  defp parse_line(line) do
    line
    |> String.trim()
    |> String.split(",")
    |> string_list_to_integer()
  end

  defp string_list_to_integer([head | tail]) do
    tail = Enum.map(tail, &String.to_integer/1)

    [head | tail]
  end
end
