defmodule Liquid.Combinators.LexicalTokenTest do
  use ExUnit.Case
  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "integer value" do
    test_combinator("5", &Parser.value/1, value: 5)
    test_combinator("-5", &Parser.value/1, value: -5)
    test_combinator("0", &Parser.value/1, value: 0)
  end

  test "float value" do
    test_combinator("3.14", &Parser.value/1, value: 3.14)
    test_combinator("-3.14", &Parser.value/1, value: -3.14)
    test_combinator("1.0E5", &Parser.value/1, value: 1.0e5)
    test_combinator("1.0e5", &Parser.value/1, value: 1.0e5)
    test_combinator("-1.0e5", &Parser.value/1, value: -1.0e5)
    test_combinator("1.0e-5", &Parser.value/1, value: 1.0e-5)
    test_combinator("-1.0e-5", &Parser.value/1, value: -1.0e-5)
  end

  test "string value" do
    test_combinator(~S("abc"), &Parser.value/1, value: "abc")
    test_combinator(~S('abc'), &Parser.value/1, value: "abc")
    test_combinator(~S(""), &Parser.value/1, value: "")
    test_combinator(~S("mom's chicken"), &Parser.value/1, value: "mom's chicken")

    test_combinator(
      ~S("text with true and false inside"),
      &Parser.value/1,
      value: "text with true and false inside"
    )

    test_combinator(
      ~S("text with null inside"),
      &Parser.value/1,
      value: "text with null inside"
    )

    test_combinator(~S("這是傳統的中文"), &Parser.value/1, value: "這是傳統的中文")
    test_combinator(~S( "هذا باللغة العربية"), &Parser.value/1, value: "هذا باللغة العربية")
    test_combinator(~S("😁😂😃😉"), &Parser.value/1, value: "😁😂😃😉")
  end

  test "boolean values" do
    test_combinator("true", &Parser.value/1, value: true)
    test_combinator("false", &Parser.value/1, value: false)
  end

  test "nil values" do
    test_combinator("null", &Parser.value/1, value: nil)
    test_combinator("nil", &Parser.value/1, value: nil)
  end

  test "range values" do
    test_combinator("(10..1)", &Parser.value/1, value: {:range, [start: 10, end: 1]})
    test_combinator("(-10..1)", &Parser.value/1, value: {:range, [start: -10, end: 1]})
    test_combinator("(1..10)", &Parser.value/1, value: {:range, [start: 1, end: 10]})
    test_combinator("(1..var)", &Parser.value/1, value: {:range, [start: 1, end: {:variable, ["var"]}]})

    test_combinator(
      "(var[0]..10)",
      &Parser.value/1,
      value: {:range, [start: {:variable, ["var", {:index, 0}]}, end: 10]}
    )

    test_combinator(
      "(var1[0].var2[0]..var3[0])",
      &Parser.value/1,
      value: {:range, [start: {:variable, ["var1", {:index, 0}, "var2", {:index, 0}]}, end: {:variable, ["var3", {:index, 0}]}]}
    )
  end

  test "object values" do
    test_combinator("variable", &Parser.value/1, value: {:variable, ["variable"]})
    test_combinator("variable.value", &Parser.value/1, value: {:variable, ["variable", "value"]})
  end

  test "list values" do
    test_combinator("product[0]", &Parser.value/1, value: {:variable, ["product", {:index, 0}]})
  end

  test "object and list values" do
    test_combinator(
      "products[0].parts[0].providers[0]",
      &Parser.value/1,
      value:
        {:variable, ["products", {:index, 0}, "parts", {:index, 0}, "providers", {:index, 0}]}
    )

    test_combinator(
      "products[parts[0].providers[0]]",
      &Parser.value/1,
      value:
        {:variable,
         ["products", {:index, {:variable, ["parts", {:index, 0}, "providers", {:index, 0}]}}]}
    )
  end

  test "variable with filters and params" do
    test_combinator(
      "{{ var.var1[0][0].var2[3] | filter1 | f2: 1 | f3: 2 | f4: 2, 3 }}",
      &Parser.liquid_variable/1,
      [
        liquid_variable: [
          variable: [
            parts: [
              part: "var",
              part: "var1",
              index: 0,
              index: 0,
              part: "var2",
              index: 3
            ],
            filters: [
              filter: "filter1",
              filter: "f2", params: [value: 2, value: 3],
              filter: "f3", params: [value: 2, value: 3],
              filter: "f4", params: [value: 2, value: 3]
            ]
          ]
        ]
      ]
    )
  end
end
