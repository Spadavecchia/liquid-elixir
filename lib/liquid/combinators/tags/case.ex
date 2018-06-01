defmodule Liquid.Combinators.Tags.Case do
  import NimbleParsec
  alias Liquid.Combinators.Tag

  defp when_tag do
    Tag.define_open("when", fn combinator ->
      combinator
      |> choice([
        parsec(:value_definition),
        parsec(:quoted_token),
        parsec(:variable_definition)
      ])
      |> optional(
        times(choice([parsec(:logical_condition), parsec(:comma_contition_value)]), min: 1)
      )
    end)
  end

  defp head(combinator) do
    combinator
    |> choice([
      parsec(:value_definition),
      parsec(:quoted_token),
      parsec(:variable_definition)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
  end

  defp body(combinator) do
    combinator
    |> times(when_tag(), min: 1)
    |> parsec(:ignore_whitespaces)
    |> optional(times(parsec(:else_tag), min: 1))
  end

  def tag, do: Tag.define_closed("case", &head/1, &body/1)
end
