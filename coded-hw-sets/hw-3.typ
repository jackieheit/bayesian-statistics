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
  title: [Coding Homework 3],
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
]
For reference: θ | p(θ) 0.0 | 0.01 0.2 | 0.40 0.4 | 0.34 0.6 | 0.17 0.8 | 0.03 1.0 | 0.01

1a)

#block[
```r
# make theta, or the possible values that can be taken on by theta which happen to be proportion of zener cards guessed correctly
theta <- c(0, 0.2, 0.4, 0.6, 0.8, 1)

# prior (ie ptheta) which are the presumed probabilities of getting a specific theta value
ptheta <- c(0.01, 0.4, 0.34, 0.17, 0.03, 0.01)
```

]
1b-d) Use theta and your Zener card data ({yi}) to make the following vector: lik = p({yi}|θ) = the likelihood of the data for each value of θ.

Hint: Count the number of correct guesses and use Equation 5.11 from the textbook.

5.11 Equation for reference: \$\\theta^{\#heads} (1-\\theta)^{\#tails}\$ (idk why the latex code isn’t working)

#block[
```r
# load in data
zener <- read.csv("../data/Zener_data.csv")

k <- sum(zener$correct)
n <- nrow(zener)
wrong <- n - k

# k = number of correct zener cards; size = total number of trials; prob = theta
# lik is the equivalent of p(y|theta)
lik <- (theta^k) * ((1 - theta)^wrong)

# compute marginal likelihood - p(y) - which is the likelihood * the probability of theta
marg_lik <- sum(ptheta * lik)
marg_lik
```

#block[
```
[1] 2.04374e-81
```

]
```r
# trying to find the probability of theta given y p(y|theta)
# p(theta|y) = ( p(y|theta) * p(theta) / p(y) ) where the denominator is the marginal likelihood
# and 
post <- (lik * ptheta) / marg_lik
```

]
2a) (a) (10 points) Use ggplot2 with geom line and geom point to plot the prior distribution. Label the plot "Prior distribution" (use ggtitle) and make sure the y-axis is scaled from 0 to 1 (use ylim) for the sake of consistency with the second plot. Hint: The code will be similar to what you used in the first homework, except that you are plotting post instead of the binomial distribution obtained using dbinom.

```r
# prior dist df
prior_df <- data.frame(theta, ptheta)

ggplot(prior_df, aes(x = theta, y = ptheta)) + 
  geom_line() + 
  geom_point() +
  geom_smooth() +
  ylim(0, 1) +
  labs(title = "Prior Distribution", x = "Theta", y = "Prior beliefs")
```

#block[
```
`geom_smooth()` using method = 'loess' and formula = 'y ~ x'
```

]
#block[
```
Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning
-Inf
```

]
#box(image("hw-3_files/figure-typst/unnamed-chunk-4-1.svg"))

2b) Plot the posterior distribution in the same way, following all the guidelines for the prior distribution plot (obviously give it the right title).

```r
# posterior dist df
post_df <- data.frame(theta, post)

ggplot(prior_df, aes(x = theta, y = post)) + 
  geom_line() + 
  geom_point() +
  geom_smooth() +
  ylim(0, 1) +
  labs(title = "Posterior Distribution", x = "Theta", y = "Posterior Probability")
```

#block[
```
`geom_smooth()` using method = 'loess' and formula = 'y ~ x'
```

]
#block[
```
Warning: Removed 47 rows containing missing values or values outside the scale range
(`geom_smooth()`).
```

]
#block[
```
Warning in max(ids, na.rm = TRUE): no non-missing arguments to max; returning
-Inf
```

]
#box(image("hw-3_files/figure-typst/unnamed-chunk-5-1.svg"))

2c) In the prior distribution, there is greater variability across values of theta, reflecting a broader range of possible beliefs about theta. The highest probability density is around theta = 0.20, which corresponds to a prior belief of 40% for that value.

In contrast, the posterior distribution is more defined, with the probability mass concentrated between theta = 0 and theta = 0.35, peaking around theta = 0.15. This shift demonstrates how the data has updated our beliefs, making the posterior distribution more defined and specific compared to the prior. There is also much less variation beyond values of 0.35 with little cases reaching greater values of theta.

#block[
#set enum(numbering: "1.", start: 3)
+ Finally, we will practice summarizing the prior and prior distributions.
]

#block[
#set enum(numbering: "(a)", start: 1)
+ (10 points) Compute the prior mean/expected value of θ (notation: "E\[θ\]") and posterior mean/expected value of θ (notation: "E\[θ|y\]"). Compare the two: did the mean of θ increase or decrease? Hint: This computation will be similar to what you did in homework2.
]

#block[
```r
eprior_theta <- sum(theta * ptheta)
eprior_theta
```

#block[
```
[1] 0.352
```

]
```r
epos_theta <- sum(theta*post)
epos_theta
```

#block[
```
[1] 0.2
```

]
]
The mean decreased.

#block[
#set enum(numbering: "(a)", start: 2)
+ (10 points) Compute the prior variance of θ (notation: "V \[θ\]") and posterior variance of θ (notation: "V \[θ|y\]"). Compare the two: did the variance of θ increase or decrease? Hint: This computation will be similar to what you did in homework 2.
]

#block[
```r
prior_var <- sum(ptheta * (theta - ptheta)^2)
prior_var
```

#block[
```
[1] 0.076246
```

]
```r
post_var <- sum(post * (theta - post)^2)
post_var
```

#block[
```
[1] 0.64
```

]
]
The variance increased!

#block[
#set enum(numbering: "(a)", start: 3)
+ (10 points) The posterior mean of θ (i.e.~E\[θ|y\]) is one way of boiling down the posterior distribution into a single "best guess" about θ, i.e.~a point estimate. Another point estimate is the posterior mode, i.e.~the value of θ with the highest posterior probability. Use the graph of the posterior distribution to identify the posterior mode. Note: The posterior mode is often called the maximum a posteriori or MAP estimate. You don’t need to remember this for the class, but it’s worth mentioning
]

The maximum would be around theta values of 0.15.
