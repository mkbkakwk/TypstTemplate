// ==========================================
// 1. 依赖与导入 (Imports)
// ==========================================
// 引入 pergamon 包，用于高级参考文献管理 ("作者-年份" 等格式)
#import "@preview/pergamon:0.6.0": *

// 引入 codly 包，用于美化代码块 (显示行号、图标等)
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *

// 引入 cetz 包，用于绘图
#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.0"

#import "colors.typ": *
#import "color-box.typ": *

// ==========================================
// 2. 全局配置 (Configuration)
// ==========================================

// --- 2.1 字体配置 ---
// 标题字体：无衬线字体，设置较粗的字重 (800)
#let sans-font = "Microsoft YaHei"
#let sans-weight = 800

// 正文字体：优先使用 Times New Roman (英文)，中文回退到宋体
#let serif-font = ("Times New Roman", "SimSun")
#let text-size = 12pt

// 没有原生粗体的字体列表
#let pseudo-bold-fonts = "SimSun"

// --- 2.2 颜色配置 ---
// 引用高亮色 (深绿)
#let color-cite = rgb("#2ecc40").darken(20%)
// 默认链接色 (深蓝)
#let color-link = rgb("#0074d9").darken(20%)
// 标题装饰块颜色 (香蕉黄)
#let color-banana = rgb("#ffdc00")

// --- 2.3 表格配置 ---
#let table-config = (
  stroke-outer: 1pt, // 表格上下粗线
  stroke-inner: 0.5pt, // 表头分隔细线
)

// ==========================================
// 3. 工具函数 (Utilities)
// ==========================================

// --- 3.1 三线表生成函数 ---
// 自动将普通 table 转换为三线表格式（顶底粗线，表头细线）
#let three-line-table(it, config: table-config) = context {
  // 如果表格中已经手动包含 hline，则不进行自动处理，防止冲突
  if it.children.any(c => c.func() == table.hline) {
    return it
  }

  let meta = it.fields()
  meta.stroke = none // 清除默认边框
  meta.remove("children") // 移除原有内容以便重新组装

  // 分离表头和单元格内容
  let header = it.children.find(c => c.func() == table.header)
  let cells = it.children.filter(c => c.func() == table.cell)

  // 如果未显式定义 header，则默认第一行为表头
  if header == none {
    let columns = meta.columns.len()
    header = table.header(..cells.slice(0, columns))
    cells = cells.slice(columns)
  }

  // 重新构建表格：顶线 -> 表头 -> 分隔线 -> 内容 -> 底线
  return table(
    ..meta,
    table.hline(stroke: config.stroke-outer),
    header,
    table.hline(stroke: config.stroke-inner),
    ..cells,
    table.hline(stroke: config.stroke-outer),
  )
}

// --- 3.2 参考文献配置 (Pergamon) ---
// 配置引用格式为“作者-年份”
#let fcite = format-citation-authoryear()

// 配置参考文献列表的详细渲染规则
#let fref = format-reference(
  name-format: "{given} {family}", // 姓名显示格式
  format-quotes: it => it, // 不强制给标题加引号
  print-date-after-authors: true, // 日期紧跟作者之后
  reference-label: fcite.reference-label,
  // 屏蔽不需要显示的字段，保持条目简洁
  suppress-fields: (
    "*": ("month", "day"),
    "inproceedings": ("editor", "publisher", "pages", "location"),
  ),
  // 处理 TODO 标记，将其标红显示
  eval-scope: ("todo": x => text(fill: red, x)),
  bibstring: ("in": "In"),
  bibstring-style: "long",
)

// 导出打印参考文献的快捷函数
#let print-bananote-bibliography() = {
  print-bibliography(
    format-reference: fref,
    sorting: "nyt", // 按 Name, Year, Title 排序
    label-generator: fcite.label-generator,
  )
}

// --- 3.3 章节分隔符 ---
// 用于正文中分隔不同逻辑块的星星线
#let sectionline = align(center)[
  #v(1em)
  * \* #sym.space.quad \* #sym.space.quad \* *
  #v(1em)
]

// ==========================================
// 4. 主模板函数 (Main Template)
// ==========================================
#let note(
  title: none, // 文章标题
  authors: (), // 作者列表 ["Name", ["Name", "Affiliation"]]
  date: datetime.today(), // 日期
  version: none, // 版本号
  highlight-by: (), // 高亮特定作者（如自己）
  abstract: none, // 摘要内容
  doc, // 正文内容
) = {
  // --- 4.1 页面基础设置 ---
  set text(font: serif-font, size: text-size, lang: "zh")
  set page(margin: (x: 2.5cm, y: 3cm), numbering: "I") // 目录页前使用罗马数字

  // 段落设置：首行缩进 2em，两端对齐
  set par(
    first-line-indent: (amount: 2em, all: true), // all: true 确保标题后第一段也缩进
    spacing: 0.7em,
    justify: true,
    leading: 0.7em,
  )
  set list(indent: 2em)

  // --- 4.2 渲染标题区域 ---
  if title != none {
    // 标题本身不缩进
    par(first-line-indent: 0em)[
      #text(font: sans-font, size: 17pt, weight: sans-weight, title)
    ]
    parbreak()
  }

  // --- 4.3 渲染作者信息 ---
  for (i, author) in authors.enumerate() {
    // 解析作者信息：支持字符串或 [姓名, 机构] 数组
    let name = if type(author) == array { author.at(0) } else { author }
    let affiliation = if type(author) == array and author.len() > 1 { author.at(1) } else { "" }

    text(size: text-size, weight: "bold", name)

    // 第一位作者右侧显示日期
    if i == 0 and date != none {
      h(1fr)
      date.display("[day] [month repr:long] [year]")
    }

    // 显示机构及版本号
    if affiliation == none and i > 1 and version == none {
      // 空操作
    } else {
      linebreak()
      affiliation
      // 版本号显示在第一位作者机构行的右侧
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
      // 使用 absolute placement 将 "Abstract" 标签悬浮在左上角
      #place(dx: 2em, dy: -1em, box(
        fill: white,
        inset: 0.5em,
        text(font: sans-font, weight: sans-weight)[Abstract],
      ))
    ]
    v(0.2em)
    abstract
    line(length: 105%) // 底部分割线
    v(0.5em)
  }

  // --- 4.5 标题样式自定义 (核心视觉逻辑) ---
  set heading(numbering: "1.1 ")
  let chaptercounter = counter("chapter") // 自定义章节计数器（用于图表公式编号）
  let heading-size = 12pt

  // Level 1 标题：左侧带黄色方块编号
  show heading.where(level: 1): it => {
    v(2em, weak: true) // 标题上方间距

    block(below: 1em)[
      // 利用 place 将编号方块放置在左侧页边距外 (-3mm - 2em)
      #place(dx: -3mm - 2em, dy: -3.5pt)[
        #box(width: 2em)[
          #context {
            align(right)[
              // 黄色装饰方块
              #box(fill: color-banana, width: 1em, height: 1em)[
                #if it.numbering != none {
                  // 方块内垂直居中显示数字
                  align(center + horizon, text(
                    font: sans-font,
                    weight: sans-weight,
                    size: heading-size,
                    [#(counter(heading).get().first())],
                  ))
                }
              ]
            ]
          }
        ]
      ]

      // 标题文本，强制取消缩进
      #par(first-line-indent: 0em)[
        #text(font: sans-font, weight: sans-weight, size: heading-size, it.body)
      ]
    ]

    // 逻辑处理：更新章节计数器，重置公式计数器
    if it.level == 1 and it.numbering != none {
      chaptercounter.step()
      counter(math.equation).update(0)
    }
  }

  // 其他级别标题样式
  show heading.where(level: 2): set text(font: sans-font, weight: sans-weight, size: heading-size)
  show heading.where(level: 2): set block(below: 1em, above: 2em)
  show heading.where(level: 3): set text(font: sans-font, weight: sans-weight)
  show heading.where(level: 4): set text(font: sans-font, weight: sans-weight, size: text-size)

  // --- 4.6 伪粗体处理 (Simulated Bold for CJK) ---
  show strong: it => context {
    //  如果 pseudo-bold-fonts 不是数组（是单个字符串），先包成数组，然后统统 map 到 lower
    let targets = if type(pseudo-bold-fonts) == array {
      pseudo-bold-fonts
    } else {
      (pseudo-bold-fonts,)
    }.map(lower)

    // 获取当前字体栈
    let current-fonts = text.font
    let font-list = if type(current-fonts) == array { current-fonts } else { (current-fonts,) }

    // 判断当前是否使用了宋体
    if font-list.any(f => lower(f) in targets) {
      // 描边 0.028em 模拟加粗
      set text(stroke: 0.028em + text.fill)
      it.body
    } else {
      it // 非宋体使用原生粗体
    }
  }

  // --- 4.7 链接与引用高亮 ---
  // 判断引用的作者是否在高亮名单中
  let maybe-highlight(reference) = {
    if type(highlight-by) == array {
      highlight-by.any(name => name in family-names(reference.fields.labelname))
    } else {
      highlight-by in family-names(reference.fields.labelname)
    }
  }

  show link: set text(color-link)
  show ref: set text(color-link)

  // 自定义引用样式：如果是自己的论文，使用绿色高亮
  show link: it => if-citation(it, value => {
    let color = if maybe-highlight(value.reference) { color-cite } else { color-link }
    set text(fill: color)
    it
  })

  // --- 4.8 目录生成与页码重置 ---
  outline(title: "目录")
  pagebreak()

  set page(numbering: "1") // 切换为阿拉伯数字
  counter(page).update(1) // 重置为第 1 页

  // --- 4.9 公式与图表编号 ---
  // 编号格式：(章节号.序号) -> (1.1)
  set math.equation(
    numbering: (..nums) => context {
      set text(size: 10pt)
      numbering("(1.1)", chaptercounter.at(here()).first(), ..nums)
    },
  )

  // 图表编号格式：章节号.序号 -> 1.1
  set figure(
    numbering: (..nums) => context {
      set text(size: 10pt)
      numbering("1.1", chaptercounter.at(here()).first(), ..nums)
    },
  )

  // 调整表格标题位置到上方，且表格内文字稍小
  show figure.where(kind: table): set figure.caption(position: top)
  show table: set text(size: 10pt)
  show table: three-line-table // 应用三线表样式
  show table.cell.where(y: 0): strong // 表头加粗

  // --- 4.10 页眉与页脚 (Header & Footer) ---
  set page(
    header: context {
      set par(first-line-indent: 0em)
      set text(font: ("Times New Roman", "KaiTi")) // 页眉使用楷体

      // 封面页（第0页）不显示
      if counter(page).at(here()).first() == 0 { return }

      // 获取当前章节标题逻辑
      let elems = query(heading.where(level: 1).after(here()))
      let before_elems = query(heading.where(level: 1).before(here()))
      let chapter-title = ""

      if elems != () and elems.first().location().page() == here().page() {
        chapter-title = elems.first().body
      } else if before_elems != () {
        chapter-title = before_elems.last().body
      }

      if chapter-title == "" { return }

      // 奇偶页排版：奇数页靠右，偶数页靠左
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
      // 页码位置：奇数页右下，偶数页左下
      if calc.odd(page-number) {
        align(right)[#counter(page).display("1 / 1", both: true)]
      } else {
        align(left)[#counter(page).display("1 / 1", both: true)]
      }
    },
  )

  // --- 4.11 代码块初始化 (Codly) ---
  show: codly-init
  codly(languages: codly-languages) // 加载语言图标
  show figure.caption: set text(size: 10pt)

  // --- 4.12 渲染正文 ---
  // 使用 refsection 确保参考文献作用域正确
  refsection(format-citation: fcite.format-citation, doc)
}
