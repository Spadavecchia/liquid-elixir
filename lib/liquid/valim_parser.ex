defmodule Liquid.ValimParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`.
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}

  defparsec(:ignore_whitespaces, General.ignore_whitespaces())
  defparsec(:variable_definition, General.variable_definition())
  defparsec(:variable_definition_for_assignment, General.variable_definition_for_assignment())
  defparsec(:variable_name_for_assignment, General.variable_name_for_assignment())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:quoted_variable_name, General.quoted_variable_name())
  defparsec(:variable_name, General.variable_name())

  tag = ascii_string([?a..?z, ?A..?Z], min: 1)
  text = ascii_string([not: ?{], min: 1) |> tag(:literal)

  closing_tag =
    empty()
    |> parsec(:start_tag)
    |> string("end")
    |> concat(tag)
    |> parsec(:end_tag)

  raw = empty() |> parsec(:start_tag) |> string("raw") |> parsec(:end_tag)
  comment = empty() |> parsec(:start_tag) |> string("comment") |> parsec(:end_tag)

  capture =
    empty()
    |> parsec(:start_tag)
    |> string("capture")
    |> choice([parsec(:quoted_variable_name), parsec(:variable_name)])
    |> parsec(:end_tag)

  defparsecp(
    :__parse__,
    # |> repeat_until(choice([parsec(:__parse__), text]), [string("{%"), string("{{")])
    empty()
    |> choice([
      raw,
      comment,
      capture
    ])
    |> traverse(:store_tag_in_context)
    |> choice([parsec(:__parse__), text])
    |> wrap()
    |> concat(closing_tag)
    |> traverse(:check_close_tag_and_emit_tag)
  )

  defp store_tag_in_context(_rest, tag, %{tags: tags} = context, _line, _offset) do
    # inspect(tag)
    tag_name = tag |> Enum.reverse() |> hd()
    {tag, %{context | tags: [tag_name | tags]}}
    # {[tag], %{context | tags: [tag | tags]}}
  end

  defp check_close_tag_and_emit_tag(_rest, acc, context, _line, _offset) do
    [tag_name, end_string, [opening | contents]] = acc

    if "end#{tag_name}" == "end#{opening}" do
      context = update_in(context.tags, &tl/1)

      element =
        case contents do
          [text] -> {String.to_atom(opening), [], text}
          nodes -> {String.to_atom(opening), [], nodes}
        end

      {[element], context}
    else
      {:error,
       "closing tag end#{inspect(tag_name)} did not match opening tag #{inspect(opening)}"}
    end
  end

  @doc """
  Validates and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(""), do: {:ok, []}

  def parse(markup, opts \\ []) do
    opts = Keyword.put(opts, :context, %{tags: []})

    case __parse__(markup, opts) do
      {:ok, template, "", %{tags: []}, _line, _offset} ->
        {:ok, template}

      {:ok, template, rest, %{tags: []}, _line, _offset} ->
        {:ok, template ++ [{:literal, rest}]}

      {:ok, _, rest, %{tags: [tag | _]}, line, offset} ->
        {:error, "tag #{inspect(tag)} was not closed", rest, line, offset}

      {:error, reason, rest, _context, line, offset} ->
        {:error, reason, rest, line, offset}
    end
  end
end

# # Run it from root with `mix run examples/simple_xml.exs`
# defmodule SimpleXML do
#   import NimbleParsec

#   @doc """
#   Parses a simple XML.
#   It is meant to show NimbleParsec recursive features.
#   It doesn't support attributes. The content of a tag is
#   either another tag or a text node.
#   """
#   def parse(xml, opts \\ []) do
#     opts = Keyword.put(opts, :context, %{tags: []})

#     case xml(xml, opts) do
#       {:ok, acc, "", %{tags: []}, _line, _offset} ->
#         {:ok, acc}

#       {:ok, _, rest, %{tags: []}, line, offset} ->
#         {:error, "document continued after last closing tag", rest, line, offset}

#       {:ok, _, rest, %{tags: [tag | _]}, line, offset} ->
#         {:error, "tag #{inspect(tag)} was not closed", rest, line, offset}

#       {:error, reason, rest, _context, line, offset} ->
#         {:error, reason, rest, line, offset}
#     end
#   end

#   tag = ascii_string([?a..?z, ?A..?Z], min: 1)
#   text = ascii_string([not: ?<], min: 1)

#   opening_tag =
#     ignore(string("<"))
#     |> concat(tag)
#     |> ignore(string(">"))

#   closing_tag =
#     ignore(string("</"))
#     |> concat(tag)
#     |> ignore(string(">"))

#   defparsecp :xml,
#              opening_tag
#              |> traverse(:store_tag_in_context)
#              |> repeat_until(
#                choice([
#                  parsec(:xml),
#                  text
#                ]),
#                [string("</")]
#              )
#              |> wrap()
#              |> concat(closing_tag)
#              |> traverse(:check_close_tag_and_emit_tag)

#   defp store_tag_in_context(_rest, [tag], %{tags: tags} = context, _line, _offset) do
#     {[tag], %{context | tags: [tag | tags]}}
#   end

#   defp check_close_tag_and_emit_tag(_rest, acc, context, _line, _offset) do
#     [closing, [opening | contents]] = acc

#     if closing == opening do
#       context = update_in(c{ntext.tags, &tl/1)

#       element =
#         case contents do
#           [text] -> {String.to_atom(opening), [], text}
#           nodes -> {String.to_atom(opening), [], nodes}
#         end

#       {[element], context}
#     else
#       {:error, "closing tag #{inspect(closing)} did not match opening tag #{inspect(opening)}"}
#     end
#   end
# end
