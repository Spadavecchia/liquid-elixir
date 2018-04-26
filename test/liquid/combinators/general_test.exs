defmodule Liquid.Combinators.GeneralTest do
  use ExUnit.Case
  import Liquid.Helpers

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.General

    defparsec(:whitespace, General.whitespace())
    defparsec(:literal, General.literal())
    defparsec(:ignore_whitespaces, General.ignore_whitespaces())
  end

  test "whitespace must parse 0x0020 and 0x0009" do
    test_combiner(" ", &Parser.whitespace/1, ' ')
  end

  test "literal: every utf8 valid character until open/close tag/variable" do
    test_combiner("Chinese: 你好, English: Whatever, Arabian: مرحبا",
      &Parser.literal/1,
      [literal: ["Chinese: 你好, English: Whatever, Arabian: مرحبا"]]
    )
    test_combiner("stop in {{", &Parser.literal/1, [literal: ["stop in "]])
    test_combiner("stop in {%", &Parser.literal/1, [literal: ["stop in "]])
    test_combiner("stop in %}", &Parser.literal/1, [literal: ["stop in "]])
    test_combiner("stop in }}", &Parser.literal/1, [literal: ["stop in "]])
    test_combiner("{{ this is not processed", &Parser.literal/1, [literal: [""]])
  end

  test "extra_spaces ignore all :whitespaces" do
    test_combiner("      ", &Parser.ignore_whitespaces/1, [])
    test_combiner("    \t\t\t  ", &Parser.ignore_whitespaces/1, [])
    test_combiner("", &Parser.ignore_whitespaces/1, [])
  end
end
