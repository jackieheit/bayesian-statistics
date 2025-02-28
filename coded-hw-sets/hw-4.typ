// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [PSYC 529 R Homework 4],
  authors: (
    ( name: [Jacqueline Heitmann],
      affiliation: [25562334],
      email: [] ),
    ),
  sectionnumbering: "1.1.a",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)
#show heading: head => [
  #pagebreak(weak: true)
  #head
  ]

#block[
```r
library(tidyverse)
```

#block[
```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.1.4     ✔ readr     2.1.5
✔ forcats   1.0.0     ✔ stringr   1.5.1
✔ ggplot2   3.5.1     ✔ tibble    3.2.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.1
✔ purrr     1.0.2     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
```

]
```r
words <- read.csv("../data/word_memory_data_summarized.csv")
words
```

#block[
```
       id             condition trials yes_responses prop_yes_resp
1    2002             Memorized     30            27          0.90
2    2002   Related_Unmemorized      6             6          1.00
3    2002 Unrelated_Unmemorized     36             0          0.00
4     LMB             Memorized     30            22          0.73
5     LMB   Related_Unmemorized      6             4          0.67
6     LMB Unrelated_Unmemorized     36             1          0.03
7   egh44             Memorized     30            21          0.70
8   egh44   Related_Unmemorized      6             1          0.17
9   egh44 Unrelated_Unmemorized     36             0          0.00
10 jh3487             Memorized     30            27          0.90
11 jh3487   Related_Unmemorized      6             6          1.00
12 jh3487 Unrelated_Unmemorized     36             0          0.00
13  jhm77             Memorized     30            17          0.57
14  jhm77   Related_Unmemorized      6             2          0.33
15  jhm77 Unrelated_Unmemorized     36             0          0.00
16 mam475             Memorized     30            24          0.80
17 mam475   Related_Unmemorized      6             1          0.17
18 mam475 Unrelated_Unmemorized     36             0          0.00
19 seb235             Memorized     30            30          1.00
20 seb235   Related_Unmemorized      6             6          1.00
21 seb235 Unrelated_Unmemorized     36             0          0.00
22  spp36             Memorized     30            22          0.73
23  spp36   Related_Unmemorized      6             4          0.67
24  spp36 Unrelated_Unmemorized     36             1          0.03
25 ss3998             Memorized     30            23          0.77
26 ss3998   Related_Unmemorized      6             5          0.83
27 ss3998 Unrelated_Unmemorized     36             0          0.00
28  ssg47             Memorized     30            25          0.83
29  ssg47   Related_Unmemorized      6             4          0.67
30  ssg47 Unrelated_Unmemorized     36             0          0.00
31  wz343             Memorized     30            26          0.87
32  wz343   Related_Unmemorized      6             1          0.17
33  wz343 Unrelated_Unmemorized     36             0          0.00
34 yl2456             Memorized     30            25          0.83
35 yl2456   Related_Unmemorized      6             3          0.50
36 yl2456 Unrelated_Unmemorized     36             0          0.00
37  yq222             Memorized     30            26          0.87
38  yq222   Related_Unmemorized      6             2          0.33
39  yq222 Unrelated_Unmemorized     36             0          0.00
40  zl543             Memorized     30            29          0.97
41  zl543   Related_Unmemorized      6             2          0.33
42  zl543 Unrelated_Unmemorized     36             0          0.00
43  zl627             Memorized     30            25          0.83
44  zl627   Related_Unmemorized      6             4          0.67
45  zl627 Unrelated_Unmemorized     36             5          0.14
```

]
]
+ Looking at the data table (you don’t need to import it as an R data frame). Define the following as variables in R:

#block[
#set enum(numbering: "(a)", start: 1)
+ (21/2 points) N: the number of relevant data points (trials)
]

#block[
```r
memorized_ds <- words %>%
  filter(condition == "Memorized")

N <- sum(memorized_ds$trials)

N
```

#block[
```
[1] 450
```

]
]
#block[
#set enum(numbering: "(a)", start: 2)
+ (21/2 points) z: the number of "yes" responses on relevant trials
]

#block[
```r
z <- sum(memorized_ds$yes_responses)
z
```

#block[
```
[1] 369
```

]
]
#block[
#set enum(numbering: "(a)", start: 3)
+ (21/2 points) a: the first prior beta hyperparameter
+ (21/2 points) b: the second prior beta hyperparameter
]

#block[
```r
# beta(4,4)
a <- 4
b <- 4
```

]
#block[
#set enum(numbering: "1.", start: 2)
+ (10 points) Use these variables to compute the posterior beta distribution hyperparameters (call them a post and b post).
]

#block[
```r
a_post <- a + z # prior + successes
b_post <- b + N - z # prior + failures

a_post
```

#block[
```
[1] 373
```

]
```r
b_post
```

#block[
```
[1] 85
```

]
]
#block[
#set enum(numbering: "1.", start: 3)
+ We now make a combined plot of the prior and posterior distributions. Hint: Use the file "beta conjugate prior demo" on Canvas as a template for doing all of this. That will make this part of the homework much easier and faster
]

data frame for plotting prior distribution:

#block[
```r
prior_plot_df = data.frame(theta = seq(from = 0, to = 1, length.out = 200),
                           distribution = "prior") %>%
  mutate(p_theta = dbeta(theta, shape1 = a, shape2 = b))
```

]
data frame for plotting the posterior distribution:

#block[
```r
post_plot_df = data.frame(theta = seq(from = 0, to = 1, length.out = 200),
                          distribution = "posterior") %>%
  mutate(p_theta = dbeta(theta, shape1 = a_post, shape2 = b_post))
```

]
combine prior and posterior plotting data frames:

#block[
```r
combo_plot_df = bind_rows(prior_plot_df,
                          post_plot_df)
```

]
combined plot:

```r
combo_plot_df %>% ggplot(aes(x = theta, y = p_theta, color = distribution)) +
  geom_line() +
  scale_x_continuous(breaks = seq(from = 0, to = 1, by = 0.1)) # more marks on x axis
```

#box(image("hw-4_files/figure-typst/unnamed-chunk-9-1.svg"))

#block[
#set enum(numbering: "1.", start: 4)
+ The expected value (mean) and mode (most probable value) are two ways to summarize a probability distribution. Given the hyperparameters a and b of a beta distribution, you can compute the distribution’s mode (ω) and expected value (i.e.~mean, µ) using formulas given in the textbook (page 129) and summarized in Cliff’s notes for chapter 6 (these are on Canvas). Use these formulas and your R variables to compute and display the following:
]

#block[
#set enum(numbering: "(a)", start: 1)
+ (10 points) E\[θ\] (the prior mean of θ)
]

#block[
```r
e_prior <- a / a + b
e_prior
```

#block[
```
[1] 5
```

]
]
#block[
#set enum(numbering: "(a)", start: 2)
+ (10 points) the prior mode of θ.
]

#block[
```r
mode_prior <- (a - 1) / (a + b - 2)
mode_prior
```

#block[
```
[1] 0.5
```

]
]
#block[
#set enum(numbering: "(a)", start: 3)
+ (10 points) E\[θ|N, z\] (the posterior mean of θ)
]

#block[
```r
e_post <- a_post / (a_post + b_post)
e_post
```

#block[
```
[1] 0.8144105
```

]
]
#block[
#set enum(numbering: "(a)", start: 4)
+ (10 points) the posterior mode of θ
]

#block[
```r
mode_post <- (a_post - 1) / (a_post + b_post - 2)
mode_post
```

#block[
```
[1] 0.8157895
```

]
]
#block[
#set enum(numbering: "1.", start: 5)
+ You can use the R function qbeta to find quantiles of a beta distribution.
]

For example, let’s suppose we want to find the median (0.5 quantile, i.e.~50th percentile) of a beta(3, 2) distribution. Then we use the following code: qbeta(p = 0.5, shape1 = 3, shape2 = 2)

This tells use that, assuming a = 3 and b = 2, we have p(θ ≤ 0.6142724) = 0.5. In other words the median of a beta(3, 2) distribution is about 0.61.

Use qbeta to compute the following: (a) (5 points) The 5th percentile (i.e.~0.05 quantile) of the prior distribution

#block[
```r
qbeta(p = 0.05, a, b)
```

#block[
```
[1] 0.2253216
```

]
]
the probability of theta being less than or equal to 0.2253216 is roughly 5% in the prior distribution.

#block[
#set enum(numbering: "(a)", start: 2)
+ (5 points) The 5th percentile of the posterior distribution
]

#block[
```r
qbeta(p = 0.05, a_post, b_post)
```

#block[
```
[1] 0.7837966
```

]
]
The probability of theta being less than or equal to 0.78 is roughly 0.05.

#block[
#set enum(numbering: "(a)", start: 3)
+ (5 points) The 95th percentile (i.e.~0.95 quantile) of the prior distribution
]

#block[
```r
qbeta(p = 0.95, a, b)
```

#block[
```
[1] 0.7746784
```

]
]
#block[
#set enum(numbering: "(a)", start: 4)
+ (5 points) The 95th percentile of the posterior distribution
]

#block[
```r
qbeta(p = 0.95, a_post, b_post)
```

#block[
```
[1] 0.8434619
```

]
]
Note: We can use these percentiles to construct 90% credible intervals for θ: the probability that θ is between the 5th and 95th percentiles of the distribution is 90%. For the sake of time we won’t go into this in detail, but ask me if you have any questions about it (it’s very similar to how you derive frequentist confidence intervals, except using the prior or posterior distribution over θ instead of the sampling distribution of some estimator).
