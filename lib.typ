// ==========================================
// 1. 导入依赖包
// ==========================================
// 引入 pergamon 包，用于高级参考文献管理
#import "@preview/pergamon:0.6.0": *
// 假设你本地有 colors.typ 和 color-box.typ，引入颜色相关定义
#import "colors.typ": *
#import "color-box.typ": *
// 引入 codly 包，用于美化代码块
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

// ==========================================
// 2. 字体与全局变量配置
// ==========================================
// 无衬线字体（用于标题），加粗权重设为 800
#let sans = "Microsoft YaHei"
#let sans-weight = 800
// 衬线字体（用于正文）：英文优先 Times New Roman，中文回退到宋体
#let serif = ("Times New Roman", "SimSun")

// 全局正文字号
#let text-size = 12pt

// 定义主题色
#let darkgreen = rgb("#2ecc40").darken(20%) // 引用高亮色
#let darkblue = rgb("#0074d9").darken(20%)  // 默认链接色

// ==========================================
// 3. 参考文献格式配置 (Pergamon)
// ==========================================
// 配置引用格式为“作者-年份”
#let fcite = format-citation-authoryear()

// 配置参考文献列表的详细格式
#let fref = format-reference(
  name-format: "{given} {family}", // 姓名格式
  format-quotes: it => it, // 不强制加引号
  print-date-after-authors: true, // 日期放在作者后
  reference-label: fcite.reference-label,
  // 屏蔽不需要显示的字段（如月份、天、编辑等）
  suppress-fields: (
    "*": ("month", "day"),
    "inproceedings": ("editor", "publisher", "pages", "location"),
  ),
  eval-scope: ("todo": x => text(fill: red, x)), // 处理 TODO 标记
  bibstring: ("in": "In"),
  bibstring-style: "long",
)

// 封装一个打印参考文献的函数，供外部调用
#let print-bananote-bibliography() = {
  print-bibliography(
    format-reference: fref,
    sorting: "nyt", // 按 Name, Year, Title 排序
    label-generator: fcite.label-generator,
  )
}

// ==========================================
// 4. 主模板函数 note
// ==========================================
#let note(
  title: none, // 文章标题
  authors: (), // 作者列表
  date: datetime.today(), // 日期
  version: none, // 版本号
  highlight-by: (), // 需要高亮的作者（用于区分自己的论文）
  banana-color: rgb("#ffdc00"), // 标题装饰块的颜色（香蕉黄）
  abstract: none, // 摘要内容
  doc, // 正文内容
) = {
  // --- 4.1 页面与段落基础设置 ---
  set text(font: serif, size: text-size, lang: "zh") // 设置默认字体
  set page(margin: (x: 2.5cm, y: 3cm), numbering: "I") // 初始页码为罗马数字 (I, II)

  // 设置段落缩进：2em (两个字符)，all: true 确保标题后第一段也缩进
  set par(first-line-indent: (amount: 2em, all: true), spacing: 0.7em, justify: true, leading: 0.7em)

  // --- 4.2 渲染标题 ---
  if title != none {
    set par(first-line-indent: 0em) // 标题本身不缩进
    text(font: sans, size: 17pt, weight: sans-weight, title)
    parbreak()
  }

  // --- 4.3 渲染作者信息 ---
  for (i, author) in authors.enumerate() {
    // 解析作者格式，支持数组传入机构信息
    let name = if type(author) == array { author.at(0) } else { author }
    let affiliation = if type(author) == array and author.len() > 1 { author.at(1) } else { "" }

    text(size: text-size, weight: "bold", name)
    // 如果是第一位作者，右侧显示日期
    if i == 0 and date != none {
      h(1fr)
      date.display("[day] [month repr:long] [year]")
    }

    // 显示机构信息和版本号
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

  // --- 4.4 渲染摘要 (Abstract) ---
  if abstract != none {
    v(2em)
    block[
      #line(length: 105%) // 顶部分割线
      // 使用 absolute placement 放置 "Abstract" 标签
      #place(dx: 2em, dy: -1em, box(
        fill: white,
        inset: 6pt,
        text(font: sans, weight: sans-weight)[Abstract],
      ))
    ]
    v(-0.2em)

    abstract // 插入摘要正文

    v(-0.1em)
    line(length: 105%) // 底部分割线
    v(0.5em)
  }

  // --- 4.5 标题样式设置 (核心样式) ---
  set heading(numbering: "1.1 ") // 开启编号
  let chaptercounter = counter("chapter") // 自定义章节计数器
  let heading-size = 12pt

  // 一级标题样式（带黄色方块的特殊样式）
  show heading.where(level: 1): it => {
    v(2em, weak: true) // 标题前空隙

    block(below: 1em)[
      // 使用 place 将编号放置在左侧边缘外
      #place(dx: -3mm - 2em, dy: -3.5pt)[
        #box(width: 2em)[
          #context {
            align(right)[
              // 黄色小方块
              #box(fill: banana-color, width: 1em, height: 1em)[
                #if it.numbering != none {
                  // 在方块内居中显示数字
                  align(center + horizon, text(font: sans, weight: sans-weight, size: heading-size, [#(
                    counter(heading).get().first()
                  )]))
                }
              ]
            ]
          }
        ]
      ]

      // 渲染标题文字，强制取消首行缩进
      #par(first-line-indent: 0em)[#text(font: sans, weight: sans-weight, size: heading-size, it.body)]
    ]

    // 如果是一级标题，让自定义章节计数器+1，并重置公式计数器
    if it.level == 1 and it.numbering != none {
      chaptercounter.step()
      counter(math.equation).update(0)
    }
  }

  // 其他级别标题的样式
  show heading.where(level: 2): set text(font: sans, weight: sans-weight, size: heading-size)
  show heading.where(level: 2): set block(below: 1em, above: 2em)
  show heading.where(level: 3): set text(font: sans, weight: sans-weight)
  show heading.where(level: 4): set text(font: sans, weight: sans-weight, size: text-size)

  // --- 4.6 链接高亮逻辑 ---
  // 判断引用的作者是否在 highlight-by 列表中
  let maybe-highlight(reference) = {
    if type(highlight-by) == array {
      highlight-by.any(name => name in family-names(reference.fields.labelname))
    } else {
      highlight-by in family-names(reference.fields.labelname)
    }
  }

  // 设置普通链接和引用颜色
  show link: set text(darkblue)
  show ref: set text(darkblue)
  // 如果是引用且作者匹配，改为深绿色
  show link: it => if-citation(it, value => {
    let color = if maybe-highlight(value.reference) { darkgreen } else { darkblue }
    set text(fill: color)
    it
  })

  // --- 4.7 目录与页码重置 ---
  outline(title: "目录")
  pagebreak()

  set page(numbering: "1") // 切换为阿拉伯数字页码
  counter(page).update(1) // 重置页码为 1

  // --- 4.8 公式与图表自定义编号 ---
  // 公式编号格式：(章节号.序号) 例如 (1.1)
  set math.equation(
    numbering: (..nums) => (
      context {
        set text(size: 10pt)
        numbering("(1.1)", chaptercounter.at(here()).first(), ..nums)
      }
    ),
  )

  // 图表编号格式：章节号.序号 例如 1.1
  set figure(
    numbering: (..nums) => (
      context {
        set text(size: 10pt)
        numbering("1.1", chaptercounter.at(here()).first(), ..nums)
      }
    ),
  )

  // --- 4.9 页眉与页脚设置 ---
  set page(
    header: context {
      set par(first-line-indent: 0em)
      set text(font: ("Times New Roman", "kaiti")) // 页眉使用楷体

      if counter(page).at(here()).first() == 0 { return } // 封面不显示

      // 查找当前页的一级标题，用于页眉显示章节名
      let elems = query(heading.where(level: 1).after(here()))
      let before_elems = query(heading.where(level: 1).before(here()))
      let chapter-title = ""

      if elems != () and elems.first().location().page() == here().page() {
        chapter-title = elems.first().body
      } else if before_elems != () {
        chapter-title = before_elems.last().body
      }

      if chapter-title == "" { return }

      // 奇偶页处理：奇数页章节名靠右，偶数页靠左
      let page-number = counter(page).at(here()).first()
      if calc.odd(page-number) {
        h(1fr) + emph(chapter-title)
      } else {
        emph(chapter-title) + h(1fr)
      }

      v(-6pt)
      align(center)[#line(length: 105%, stroke: (thickness: 1pt, dash: "solid"))] // 页眉分割线
    },

    footer: context {
      if counter(page).at(here()).first() == 0 { return }
      let page-number = counter(page).at(here()).first()
      [
        // 页码显示：奇数页靠右，偶数页靠左
        #if calc.odd(page-number) {
          align(right)[#counter(page).display("1 / 1", both: true)]
        } else {
          align(left)[#counter(page).display("1 / 1", both: true)]
        }
      ]
    },
  )

  // --- 4.10 代码块配置 (Codly) ---
  show: codly-init
  // codly(number-format: none) // 若需隐藏行号可解开此行
  codly(languages: codly-languages) // 加载语言图标支持

  // 图表标题字号调整
  show figure.caption: set text(size: 10pt)

  // --- 4.11 渲染正文 ---
  // 使用 refsection 包裹，使参考文献作用域正确
  refsection(format-citation: fcite.format-citation, doc)
}

// 辅助组件：用于分隔章节的星星线
#let sectionline = align(center)[#v(1em) * \* #sym.space.quad \* #sym.space.quad \* * #v(1em)]
