#' @title Rescale design weights for multilevel analysis
#' @name scale_weights
#'
#' @description Most functions to fit multilevel and mixed effects models only
#'    allow to specify frequency weights, but not design (i.e. sampling or probability)
#'    weights, which should be used when analyzing complex samples and survey data.
#'    \code{scale_weights()} implements an algorithm proposed by Aaparouhov (2006)
#'    and Carle (2009) to rescale design weights in survey data to account for
#'    the grouping structure of multilevel models, which then can be used for
#'    multilevel modelling.
#'
#' @param x A data frame.
#' @param cluster.id Variable indicating the grouping structure (strata) of
#'    the survey data.
#' @param pweight Variable indicating the probability (design or sampling)
#'    weights of the survey data.
#'
#' @return \code{x}, with two new variables: \code{svywght_a} and \code{svywght_b},
#'    which represent the rescaled design weights to use in multilevel models.
#'
#' @references Carle AC. \emph{Fitting multilevel models in complex survey data with design weights: Recommendations.} BMC Medical Research Methodology 2009, 9(49): 1-13
#'    \cr \cr
#'    Aaparouhov T. \emph{General Multi-Level Modeling with Sampling Weights.} Communications in Statistics—Theory and Methods 2006, 35: 439–460
#'
#' @importFrom dplyr group_by summarise n right_join enquo
#' @importFrom tibble as_tibble
#' @importFrom rlang .data
#' @export
scale_weights <- function(x, cluster.id, pweight) {

  # quote cluster.id and get name as string

  quo.id <- dplyr::enquo(cluster.id)
  id.name <- dplyr::quo_name(quo.id)


  # quote sample weights and get name as string

  quo.weights <- dplyr::enquo(pweight)
  pw.name <- dplyr::quo_name(quo.weights)


  # compute sum of weights per cluster

  tmp <- x %>%
    dplyr::group_by(!! quo.id) %>%
    dplyr::summarise(
      sum_wij = sum(!! quo.weights),
      nj = n()
    ) %>%
    dplyr::right_join(x, by = id.name)


  # multiply the original weight by the fraction of the
  # sampling unit total population based on Carle 2009

  tmp$svywght_a <- tmp[[pw.name]] * tmp$nj / tmp$sum_wij
  tmp$svywght_b <- tmp[[pw.name]] * tmp$sum_wij / tmp$sum_wij ^ 2

  tibble::as_tibble(tmp)
}
