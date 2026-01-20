#import "@preview/pergamon:0.6.0": *
#import "colors.typ": *
#import "color-box.typ": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

#let sans = "Microsoft YaHei"
#let sans-weight = 800
#let serif = ("Times New Roman", "SimSun")

#let text-size = 12pt

#let darkgreen = rgb("#2ecc40").darken(20%)
#let darkblue = rgb("#0074d9").darken(20%)

#let fcite = format-citation-authoryear()
#let fref = format-reference(
  name-format: "{given} {family}",
  format-quotes: it => it,
  print-date-after-authors: true,
  reference-label: fcite.reference-label,
  suppress-fields: (
    "*": ("month", "day"),
    "inproceedings": ("editor", "publisher", "pages", "location"),
  ),
  eval-scope: ("todo": x => text(fill: red, x)),
  bibstring: ("in": "In"),
  bibstring-style: "long",
)

#let print-bananote-bibliography() = {
  print-bibliography(
    format-reference: fref,
    sorting: "nyt",
    label-generator: fcite.label-generator,
  )
}

#let note(
  title: none,
  authors: (),
  date: datetime.today(),
  version: none,
  highlight-by: (),
  banana-color: rgb("#ffdc00"),
  abstract: none,
  doc,
) = {
  set text(font: serif, size: text-size, lang: "zh")
  set page(margin: (x: 2.5cm, y: 3cm), numbering: "I")
  set par(first-line-indent: (amount: 2em, all: true), spacing: 0.7em, justify: true, leading: 0.7em)

  if title != none {
    set par(first-line-indent: 0em)
    text(font: sans, size: 17pt, weight: sans-weight, title)
    parbreak()
  }

  for (i, author) in authors.enumerate() {
    let name = if type(author) == array { author.at(0) } else { author }
    let affiliation = if type(author) == array and author.len() > 1 { author.at(1) } else { "" }


    text(size: text-size, weight: "bold", name)
    if i == 0 and date != none {
      h(1fr)
      date.display("[day] [month repr:long] [year]")
    }

    if affiliation == none and i > 1 and version == none [
    ] else {
      linebreak()
      affiliation
      if i == 0 and version != none {
        h(1fr)
        [Version #version]
      }
    }
    parbreak()
  }

  if abstract != none {
    v(2em)
    block[
      #line(length: 100%)
      #place(dx: 2em, dy: -1em, box(
        fill: white,
        inset: 6pt,
        text(font: sans, weight: sans-weight)[Abstract],
      ))
    ]
    v(-0.2em)

    abstract

    v(-0.1em)
    line(length: 100%)
    v(0.5em)
  }

  set heading(numbering: "1.1 ")
  let chaptercounter = counter("chapter")
  let heading-size = 12pt

  show heading.where(level: 1): it => {
    v(2em, weak: true)

    block(below: 1em)[
      #place(dx: -3mm - 2em, dy: -3.5pt)[
        #box(width: 2em)[
          #context {
            align(right)[
              #box(fill: banana-color, width: 1em, height: 1em)[
                #if it.numbering != none {
                  align(center + horizon, text(font: sans, weight: sans-weight, size: heading-size, [#(
                    counter(heading).get().first()
                  )]))
                }
              ]
            ]
          }
        ]
      ]

      #par(first-line-indent: 0em)[#text(font: sans, weight: sans-weight, size: heading-size, it.body)]
    ]
    if it.level == 1 and it.numbering != none {
      chaptercounter.step()
      counter(math.equation).update(0)
    }
  }

  show heading.where(level: 2): set text(font: sans, weight: sans-weight, size: heading-size)
  show heading.where(level: 2): set block(below: 1em, above: 2em)
  show heading.where(level: 3): set text(font: sans, weight: sans-weight)
  show heading.where(level: 4): set text(font: sans, weight: sans-weight, size: text-size)

  let maybe-highlight(reference) = {
    if type(highlight-by) == array {
      highlight-by.any(name => name in family-names(reference.fields.labelname))
    } else {
      highlight-by in family-names(reference.fields.labelname)
    }
  }

  show link: set text(darkblue)
  show ref: set text(darkblue)
  show link: it => if-citation(it, value => {
    let color = if maybe-highlight(value.reference) { darkgreen } else { darkblue }
    set text(fill: color)
    it
  })
  outline(title: "目录")
  pagebreak()

  set page(numbering: "1")
  counter(page).update(1)

  set math.equation(
    numbering: (..nums) => (
      context {
        set text(size: 10pt)
        numbering("(1.1)", chaptercounter.at(here()).first(), ..nums)
      }
    ),
  )

  set figure(
    numbering: (..nums) => (
      context {
        set text(size: 10pt)
        numbering("1.1", chaptercounter.at(here()).first(), ..nums)
      }
    ),
  )

  set page(
    header: context {
      set par(first-line-indent: 0em)
      set text(font: ("Times New Roman", "kaiti"))

      if counter(page).at(here()).first() == 0 { return }

      let elems = query(heading.where(level: 1).after(here()))
      let before_elems = query(heading.where(level: 1).before(here()))

      let chapter-title = ""

      if elems != () and elems.first().location().page() == here().page() {
        chapter-title = elems.first().body
      } else if before_elems != () {
        chapter-title = before_elems.last().body
      }

      if chapter-title == "" { return }

      let page-number = counter(page).at(here()).first()
      if calc.odd(page-number) {
        h(1fr) + emph(chapter-title)
      } else {
        emph(chapter-title) + h(1fr)
      }

      v(-6pt)
      align(center)[#line(length: 105%, stroke: (thickness: 1pt, dash: "solid"))]
    },

    footer: context {
      if counter(page).at(here()).first() == 0 { return }
      let page-number = counter(page).at(here()).first()
      [
        #if calc.odd(page-number) {
          align(right)[#counter(page).display("1 / 1", both: true)] // 奇数页靠右
        } else {
          align(left)[#counter(page).display("1 / 1", both: true)] // 偶数页靠左
        }
      ]
    },
  )

  show: codly-init
  // codly(number-format: none) //不显示行号
  codly(languages: codly-languages)


  show figure.caption: set text(size: 10pt)

  refsection(format-citation: fcite.format-citation, doc)
}

#let sectionline = align(center)[#v(1em) * \* #sym.space.quad \* #sym.space.quad \* * #v(1em)]
