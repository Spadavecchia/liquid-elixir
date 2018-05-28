defmodule Liquid.NimbleParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}

  alias Liquid.Combinators.Tags.{
    Assign,
    Comment,
    Decrement,
    Increment,
    Include,
    Raw,
    Cycle,
    If,
    Unless,
    For,
    Tablerow,
    Case,
    Capture
  }

  defparsec(:liquid_variable, General.liquid_variable())
  defparsec(:variable_definition, General.variable_definition())
  defparsec(:variable_name, General.variable_name())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:filter_param, General.filter_param())
  defparsec(:filter, General.filter())
  defparsec(:single_quoted_token, General.single_quoted_token())
  defparsec(:double_quoted_token, General.double_quoted_token())
  defparsec(:quoted_token, General.quoted_token())
  defparsec(:comparison_operators, General.comparison_operators())
  defparsec(:logical_operators, General.logical_operators())
  defparsec(:comma_contition_value, General.comma_contition_value())
  defparsec(:ignore_whitespaces, General.ignore_whitespaces())
  defparsec(:condition, General.condition())
  defparsec(:logical_condition, General.logical_condition())

  defparsec(:number, LexicalToken.number())
  defparsec(:value_definition, LexicalToken.value_definition())
  defparsec(:value, LexicalToken.value())
  defparsec(:object_property, LexicalToken.object_property())
  defparsec(:boolean_value, LexicalToken.boolean_value())
  defparsec(:null_value, LexicalToken.null_value())
  defparsec(:string_value, LexicalToken.string_value())
  defparsec(:object_value, LexicalToken.object_value())
  defparsec(:variable_value, LexicalToken.variable_value())
  defparsec(:range_value, LexicalToken.range_value())

  defp clean_empty_strings(_rest, args, context, _line, _offset) do
    result =
      args
      |> Enum.filter(fn e -> e != "" end)

    {result, context}
  end

  defparsec(
    :__parse__,
    General.liquid_literal()
    |> optional(choice([parsec(:liquid_tag), parsec(:liquid_variable)]))
    |> traverse({:clean_empty_strings, []})
  )

  defparsec(:assign, Assign.tag())
  defparsec(:capture, Capture.tag())
  defparsec(:decrement, Decrement.tag())

  defparsec(:increment, Increment.tag())

  defparsecp(:open_tag_comment, Comment.open_tag())
  defparsecp(:close_tag_comment, Comment.close_tag())
  defparsecp(:not_close_tag_comment, Comment.not_close_tag_comment())
  defparsecp(:comment_content, Comment.comment_content())
  defparsec(:comment, Comment.tag())

  defparsec(:cycle_group, Cycle.cycle_group())
  defparsec(:last_cycle_value, Cycle.last_cycle_value())
  defparsec(:cycle_values, Cycle.cycle_values())
  defparsec(:cycle, Cycle.tag())

  defparsec(:open_tag_raw, Raw.open_tag())
  defparsec(:close_tag_raw, Raw.close_tag())
  defparsecp(:not_close_tag_raw, Raw.not_close_tag_raw())
  defparsec(:raw_content, Raw.raw_content())
  defparsec(:raw, Raw.tag())

  defparsecp(:snippet, Include.snippet())
  defparsec(:variable_atom, Include.variable_atom())
  defparsecp(:var_assignment, Include.var_assignment())
  defparsecp(:with_param, Include.with_param())
  defparsecp(:for_param, Include.for_param())
  defparsec(:include, Include.tag())
  defparsec(:if, If.tag())
  defparsec(:elsif_tag, If.elsif_tag())
  defparsec(:else_tag, If.else_tag())
  defparsec(:unless, If.unless_tag())

  defparsecp(:offset_param, For.offset_param())
  defparsecp(:limit_param, For.limit_param())
  defparsecp(:reversed_param, For.reversed_param())
  defparsecp(:open_tag_for, For.open_tag())
  defparsecp(:close_tag_for, For.close_tag())
  defparsecp(:else_tag_for, For.else_tag())
  defparsecp(:for_sentences, For.for_sentences())
  defparsec(:break_tag_for, For.break_tag())
  defparsec(:continue_tag_for, For.continue_tag())
  defparsec(:for, For.tag())

  defparsecp(:cols_param, Tablerow.cols_param())
  defparsecp(:open_tag_tablerow, Tablerow.open_tag())
  defparsecp(:close_tag_tablerow, Tablerow.close_tag())
  defparsecp(:tablerow_sentences, Tablerow.tablerow_sentences())
  defparsec(:tablerow, Tablerow.tag())

  defparsec(:open_tag_case, Case.open_tag())
  defparsec(:close_tag_case, Case.close_tag())
  defparsec(:when_tag, Case.when_tag())
  defparsec(:case, Case.tag())

  defparsec(
    :liquid_tag,
    choice([
      parsec(:assign),
      parsec(:capture),
      parsec(:decrement),
      parsec(:include),
      parsec(:cycle),
      parsec(:raw),
      parsec(:comment),
      parsec(:for),
      parsec(:break_tag_for),
      parsec(:continue_tag_for),
      parsec(:if),
      parsec(:unless),
      parsec(:tablerow),
      parsec(:case),
      parsec(:increment)
    ])
  )

  @doc """
  Validate and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    case __parse__(markup) do
      {:ok, template, "", _, _, _} ->
        {:ok, template}

      {:ok, _, rest, _, _, _} ->
        {:error, "Error parsing: #{rest}"}
    end
  end
end
