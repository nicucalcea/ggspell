ggspell
================

Spell check text and ggplot objects with the LanguageTool API.

Install like this:

``` r
remotes::install_github("nicucalcea/ggspell")
```

Use like this:

``` r
# Check text
ggspell("This is a error.")

# Check plot
starwars_plot <- dplyr::starwars |>
  head(10) |>
  ggplot(aes(x = height, y = name)) +
  geom_col() +
  geom_text(x = 168.7, y = 10, label = "Firstannotation") +
  labs(title = "This an title mispeling some words",
       subtitle = "The subtitle has also erors ,like")

ggspell(starwars_plot)
```
