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

  # Prepare data for the API call
  data = list(
    `text` = text,
    `language` = language,
    `enabledOnly` = "false",
    ...
  )

  # Call API
  proof <- httr::POST(url = "https://api.languagetool.org/v2/check",
                      body = data, encode = "form") |>
    httr::content()

  # Turn into a tibble
  proof <- proof$matches |>
    tibble::tibble() |>
    tidyr::unnest_wider(1)

  if (length(proof) > 0) {

    for (i in 1:nrow(proof)) {

      # Replace \r with \n for the console output
      sentence <- gsub("\r", "\n", proof$context[[i]]$text)

      error_message <- proof[[i, "message"]]

      cli::cli_h1(error_message)

      mistake <- substring(sentence,
                           proof$context[[i]]$offset + 1,
                           proof$context[[i]]$offset + proof$context[[i]]$length)

      correct_spelling <- proof$replacements[[i]][[1]] |> unlist()

      sentence_start <- substring(sentence,
                                  0,
                                  proof$context[[i]]$offset) |>
        stringr::str_replace_all(".*\\n", "") # remove everything before and including \n

      sentence_end <-  substring(sentence,
                                 proof$context[[i]]$offset + proof$context[[i]]$length + 1,
                                 nchar(sentence)) |>
        stringr::str_replace_all("\\n.*$", "") # remove everything after and including \n

      cli::cli_alert_danger(paste0(sentence_start, cli::col_red(mistake), sentence_end))
      cli::cli_alert_success(paste0(sentence_start, cli::col_green(correct_spelling), sentence_end))
      }
  }
}


##----------------------------------------------------------------
##                        Spellcheck plots                       -
##----------------------------------------------------------------
ggspell_plot <- function(ggobject, language = "auto", ...) {

  # Extract annotations and geom_text
  annotations <- sapply(ggobject[["layers"]], function(x) x[["aes_params"]][["label"]])

  # Extract title, subtitle and alt text
  labels <- ggobject$labels[c("title", "subtitle", "alt")]

  # Combine all so we can submit a single request
  labels <- c(labels, annotations)
  labels <- labels[lengths(labels) != 0] # remove NAs

  if (length(labels) > 0) {
    ggspell_text(paste0(labels, collapse = "\r\n"),
            language = language, ...)
  }
}
