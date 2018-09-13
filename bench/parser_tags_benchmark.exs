Liquid.start()

assign = "{% assign a = 5 %}"

capture =
  "{% capture about_me %} I am {{ age }} and my favorite food is {{ favorite_food }}{% endcapture %}"

case_tag = "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}"
comment = "{% comment %} {% if true %} sadsadasd  {% endif %}{% endcomment %}"
cycle = "{%cycle \"one\", \"two\"%}"
decrement = "{% decrement a %}"
for_tag = "{% for item in array %}{% else %}{% endfor %}"
if_tag = tag = "{% if false %} this text should not go into the output {% endif %}"
include = "{% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %}"
increment = "{% increment a %}"
raw = "{% raw %} {% if true %} {% endraw %}"
tablerow = "{% tablerow item in array %}{% endtablerow %}"

templates = [
  assign: assign,
  capture: capture,
  case: case_tag,
  comment: comment,
  cycle: cycle,
  decrement: decrement,
  for: for_tag,
  if: if_tag,
  include: include,
  increment: increment,
  raw: raw,
  tablerow: tablerow
]

Enum.each(templates, fn {name, markup} ->
    Benchee.run(
      %{
        "#{name}-nimble" => fn -> Liquid.NimbleParser.parse(markup) end
      },
      warmup: 5,
      time: 20
    )
  end
)
