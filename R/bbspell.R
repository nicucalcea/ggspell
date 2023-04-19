#' Spell check text and graphics
#'
#' Pass some string into the function and it will spell check it and return the results.
#'
#' @param x The text or ggplot object you want to spell check.
#' @param language Defaults to auto, but you can specify (en-GB, de-DE, fr)
#'
#' @examples
#'
#' ggspell("This is a error.")
#' starwars <- dplyr::starwars |>
#'  head(10) |>
#'  ggplot(aes(x = height, y = name)) +
#'  geom_col() +
#'  geom_text(x = 168.7, y = 10, label = "Firstannotation") +
#'  labs(
#'    title = "This an title mispeling some words",
#'    subtitle = "The subtitle has also erors ,like"
#'  )
#'
# ggspell(starwars_plot)
#'
#' @export
ggspell <- function(x, language = "auto") {
  if (ggplot2::is.ggplot(x)) {
    ggspell_plot(x, language = language)
  } else if (is.character(x)) {
    ggspell_text(x, language = language)
  } else {
    warning("Your object couldn't be spellchecked because it's not text or a ggplot.")
  }
}


#################################################################
##                       Spellcheck text                       ##
#################################################################

ggspell_text <- function(text, language = "auto") {

  # Clean up nasty HTML
  text <- gsub("<iframe.*?iframe>", "", text)
  text <- gsub("<script.*?script>", "", text)
  text <- gsub("<div.*?div>", "", text)
  text <- gsub("<.*?>", "", text)
  text <- gsub("\n  ", " ", text)
  text <- gsub("%", "%25", text) # apparently % needs to be encoded

  proof <- httr::POST(url = "https://api.languagetool.org/v2/check",
                      body = paste0('text="', text, '"&language=', language)) |>
    httr::content()

  proof <- proof$matches |>
    tibble::tibble() |>
    tidyr::unnest_wider(1)

  if (length(proof) > 0) {
    proof <- proof |>
      dplyr::mutate(word = substring(text, offset + 1, offset + length))

    for (i in 1:nrow(proof)) {
      message(paste0(i, ": ",
                     proof[[i, "message"]],
                     ' — "',
                     substring(proof$context[[i]]$text,
                               proof$context[[i]]$offset + 1,
                               proof$context[[i]]$offset + proof$context[[i]]$length),
                     '" in "',
                     proof$context[[i]]$text, '"'))
    }
  }
}


##----------------------------------------------------------------
##                        Spellcheck plots                       -
##----------------------------------------------------------------

ggspell_plot <- function(ggobject, language = "auto") {

  # Extract annotations and geom_text
  annotations <- sapply(ggobject[["layers"]], function(x) x[["aes_params"]][["label"]])
  # annotations[lengths(annotations) != 0] |>
  #   paste(collapse = "\n")

  # Extract title, subtitle and alt text
  labels <- ggobject$labels[c("title", "subtitle", "alt")]

  # Combine all so we can submit a single request
  labels <- c(labels, annotations)
  labels <- labels[lengths(labels) != 0] # remove NAs

  if (length(labels) > 0) {
    paste(labels, collapse = "\n") |>
      ggspell(language = language)
  }
}
