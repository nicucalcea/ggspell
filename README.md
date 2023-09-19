ggspell
================

Spell check text and ggplot objects with the LanguageTool API.

Install like this:

``` r
remotes::install_github("nicucalcea/ggspell")
```

Use like this for text.

``` r
# Check text
ggspell::ggspell("This is a error.")
```

    ## 

    ## ── Use “an” instead of ‘a’ if the following word starts with a vowel sound, e.g.

    ## ✖ This is a error.

    ## ✔ This is an error.

Or check an entire plot.

``` r
# Check plot
starwars_plot <- dplyr::starwars |>
  head(10) |>
  ggplot2::ggplot(ggplot2::aes(x = height, y = name)) +
  ggplot2::geom_col() +
  ggplot2::geom_text(x = 168.7, y = 10, label = "Firstannotation") +
  ggplot2::labs(title = "This an title mispeling some words",
       subtitle = "The subtitle has also erors ,like")

ggspell::ggspell(starwars_plot)
```

    ## 

    ## ── A verb may be missing. ──────────────────────────────────────────────────────

    ## ✖ This an title mispeling some words The subti...

    ## ✔ This is an title mispeling some words The subti...

    ## 

    ## ── Use “a” instead of ‘an’ if the following word doesn’t start with a vowel soun

    ## ✖ This an title mispeling some words The subtitle...

    ## ✔ This a title mispeling some words The subtitle...

    ## 

    ## ── Possible spelling mistake found. ────────────────────────────────────────────

    ## ✖ This an title mispeling some words The subtitle has also erors ...

    ## ✔ This an title misspelling some words The subtitle has also erors ...

    ## 

    ## ── Possible spelling mistake found. ────────────────────────────────────────────

    ## ✖ ...peling some words The subtitle has also erors ,like Firstannotation

    ## ✔ ...peling some words The subtitle has also errors ,like Firstannotation

    ## 

    ## ── Put a space after the comma, but not before the comma. ──────────────────────

    ## ✖ ...g some words The subtitle has also erors ,like Firstannotation

    ## ✔ ...g some words The subtitle has also erors, like Firstannotation

    ## 

    ## ── Possible spelling mistake found. ────────────────────────────────────────────

    ## ✖ ...words The subtitle has also erors ,like Firstannotation

    ## ✔ ...words The subtitle has also erors ,like First annotation
