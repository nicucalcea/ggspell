#' Spell check text and graphics
#'
#' Pass some string into the function and it will spell check it and return the results.
#'
#' @param x The text or ggplot object you want to spell check.
#' @param language Defaults to auto, but you can specify (en-GB, de-DE, fr)
#' @param ... Any other \href{https://languagetool.org/http-api/#/default}{parameters supported by the API}.
#'
#' @examples
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
ggspell <- function(x, language = "auto", ...) {
  if (ggplot2::is.ggplot(x)) {
    ggspell_plot(x, language = language, ...)
  } else if (is.character(x)) {
    ggspell_text(x, language = language, ...)
  } else {
    warning("Your object couldn't be spellchecked because it's not text or a ggplot.")
  }
}


#################################################################
##                       Spellcheck text                       ##
#################################################################

ggspell_text <- function(text, language = "auto", ...) {

  # Clean up nasty HTML
  text <- gsub("<iframe.*?iframe>", "", text)
  text <- gsub("<script.*?script>", "", text)
  text <- gsub("<div.*?div>", "", text)
  text <- gsub("<.*?>", "", text)
  text <- gsub("\n  ", " ", text)
  text <- gsub("%", "%25", text) # apparently % needs to be encoded

  data = list(
    `text` = text,
    `language` = language,
    `enabledOnly` = "false",
    ...
  )

  proof <- httr::POST(url = "https://api.languagetool.org/v2/check",
                      body = data, encode = "form") |>
    httr::content()

  proof <- proof$matches |>
    tibble::tibble() |>
    tidyr::unnest_wider(1)

  if (length(proof) > 0) {
    proof <- proof |>
      dplyr::mutate(word = substring("This an title mispeling some words", offset + 1, offset + length))

    for (i in 1:nrow(proof)) {

      sentence <- proof$context[[i]]$text

      error_message <- proof[[i, "message"]]
      cat(paste0("—— ", error_message, " ——\n"))

      mistake <- substring(sentence,
                           proof$context[[i]]$offset + 1,
                           proof$context[[i]]$offset + proof$context[[i]]$length)

      correct_spelling <- proof$replacements[[i]][[1]] |> unlist()

      sentence_without_start <- substring(sentence,
                                          0,
                                          proof$context[[i]]$offset)
      sentence_without_end <-  substring(sentence,
                                         proof$context[[i]]$offset + proof$context[[i]]$length + 1,
                                         nchar(sentence))
      cat(paste0(crayon::red("✗  "), sentence_without_start, crayon::red(mistake), sentence_without_end, "\n"))
      cat(paste0(crayon::green("✓  "), sentence_without_start, crayon::green(correct_spelling), sentence_without_end, "\n\n"))

      }
  }
}


##----------------------------------------------------------------
##                        Spellcheck plots                       -
##----------------------------------------------------------------

ggspell_plot <- function(ggobject, language = "auto", ...) {

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
    ggspell_text(paste0(labels, collapse = "\n"),
            language = language, ...)
  }
}
