#' nsec.default
#'
#' Extracts the predicted nsec value as desired from an object of class
#' \code{\link{bayesnecfit}} or \code{\link{bayesnecfit}}.
#'
#' @param object An object of class \code{\link{bayesnecfit}} or
#' \code{\link{bayesmanecfit}} returned by \code{\link{bnec}}.
#' @param sig_val Probability value to use as the lower quantile to test
#' significance of the predicted posterior values.
#' against the lowest observed concentration (assumed to be the control), to
#' estimate NEC as an interpolated NOEC value from smooth ECx curves.
#' @param precision The number of unique x values over which to find nsec -
#' large values will make the nsec estimate more precise.
#' @param posterior A \code{\link[base]{logical}} value indicating if the full
#' posterior sample of calculated nsec values should be returned instead of
#' just the median and 95 credible intervals.
#' @param hormesis_def A \code{\link[base]{character}} vector, taking values
#' of "max" or "control". See Details.
#' @param xform A function to apply to the returned estimated concentration
#' values.
#' @param x_range A range of x values over which to consider extracting nsec.
#' @param prob_vals A vector indicating the probability values over which to
#' return the estimated nsec value. Defaults to 0.5 (median) and 0.025 and
#' 0.975 (95 percent credible intervals).
#'
#' @details For \code{hormesis_def}, if "max", then nsec values are calculated
#' as a decline from the maximum estimates (i.e. the peak at nec);
#' if "control", then ECx values are calculated relative to the control, which
#' is assumed to be the lowest observed concentration.
#'
#' @seealso \code{\link{bnec}}
#'
#' @return A vector containing the estimated nsec value, including upper and
#' lower 95% credible interval bounds.
#'
#' @importFrom stats quantile predict
#'
#' @examples
#' \dontrun{
#' library(brms)
#' library(bayesnec)
#' options(mc.cores = parallel::detectCores())
#' data(nec_data)
#'
#' exmp <- bnec(data = nec_data, x_var = "x", y_var = "y",
#'              model = c("nec4param", "ecx4param"),
#'              family = Beta(link = "identity"), priors = my_priors,
#'              iter = 1e4, control = list(adapt_delta = 0.99))
#' exmp_2 <- pull_out(exmp, "ecx4param")
#' nsec(exmp, sig_val = 0.05)
#' nsec(exmp_2)
#' }
#'
#' @export
nsec.default <- function(object, sig_val = 0.01, precision = 1000,
                         posterior = FALSE, x_range = NA,
                         hormesis_def = "control", xform = NA,
                         prob_vals = c(0.5, 0.025, 0.975)) {
  if(length(prob_vals)<3 | prob_vals[1]<prob_vals[1] | prob_vals[1]>prob_vals[3] | prob_vals[2]>prob_vals[3]){
    stop("prob_vals must include central, lower and upper quantiles, in that order")
  }
  if (length(grep("ecx", object$model)) > 0) {
    mod_class <- "ecx"
  } else {
    mod_class <- "nec"
  }
  
  pred_vals <- predict(object, precision = precision, x_range = x_range)
  p_samples <- pred_vals$posterior
  x_vec <- pred_vals$data$x
  
  reference <- quantile(p_samples[, 1], sig_val)
  
  if (grepl("horme", object$model)) {
    n <- seq_len(nrow(p_samples))
    p_samples <- do_wrapper(n, modify_posterior, object, x_vec,
                            p_samples, hormesis_def, fct = "rbind")
    nec_posterior <- unlist(posterior_samples(object$fit,
                                              pars = "nec_Intercept"))
    if (hormesis_def == "max") {
      reference <- quantile(apply(pred_vals$posterior, 2, max),
                            probs = sig_val)
    }
  }
  nsec_out <- apply(p_samples, 1, nsec_fct,  reference, x_vec)
  if (inherits(xform, "function")) {
    nsec_out <- xform(nsec_out)
  }
  label <- paste("ec", sig_val, sep = "_")
  nsec_estimate <- quantile(unlist(nsec_out), probs = prob_vals)
  names(nsec_estimate) <- paste(label, clean_names(nsec_estimate), sep = "_")
  attr(nsec_estimate, 'precision') <- precision      
  attr(nsec_out, 'precision') <- precision
  attr(nsec_estimate, 'sig_val') <- sig_val      
  attr(nsec_out, 'sig_val') <- sig_val
  if (!posterior) {
    nsec_estimate
  } else {
    nsec_out
  }
}

#' nsec
#'
#' Extracts the predicted nsec value as desired from an object of class
#' \code{\link{bayesnecfit}} or \code{\link{bayesnecfit}}.
#'
#' @inheritParams nsec.default
#'
#' @param object An object of class \code{\link{bayesnecfit}} or
#' \code{\link{bayesnecfit}} returned by \code{\link{bnec}}.
#'
#' @inherit nsec.default return details seealso examples
#'
#' @export
nsec <- function(object, sig_val = 0.01, precision = 1000,
                 posterior = FALSE, x_range = NA, hormesis_def = "control",
                 xform = NA, prob_vals = c(0.5, 0.025, 0.975)) {
  UseMethod("nsec")
}

#' nsec.bayesnecfit
#'
#' Extracts the predicted nsec value as desired from an object of class
#' \code{\link{bayesnecfit}}.
#'
#' @param object An object of class \code{\link{bayesnecfit}}
#' returned by \code{\link{bnec}}.
#' @param ... Additional arguments to \code{\link{nsec}}
#'
#' @inherit nsec return details seealso examples
#' @export
nsec.bayesnecfit <- function(object, ...) {
  nsec.default(object, ...)
}

#' nsec.bayesmanecfit
#'
#' Extracts the predicted nsec value as desired from an object of class
#' \code{\link{bayesmanecfit}}.
#'
#' @inheritParams nsec
#'
#' @param object An object of class \code{\link{bayesmanecfit}} returned by
#' \code{\link{bnec}}.
#'
#' @inherit nsec return details seealso examples
#'
#' @importFrom stats quantile
#'
#' @export
nsec.bayesmanecfit <- function(object, sig_val = 0.01, precision = 1000,
                               posterior = FALSE, x_range = NA,
                               hormesis_def = "control", xform = NA,
                               prob_vals = c(0.5, 0.025, 0.975)) {
  sample_nsec <- function(x, object, sig_val, precision,
                          posterior, hormesis_def,
                          x_range, xform, prob_vals, sample_size) {
    mod <- names(object$mod_fits)[x]
    target <- suppressMessages(pull_out(object, model = mod))
    out <- nsec.default(target, sig_val = sig_val,
                        precision = precision, posterior = posterior,
                        hormesis_def = hormesis_def, x_range = x_range,
                        xform = xform, prob_vals = prob_vals)
    n_s <- as.integer(round(sample_size * object$mod_stats[x, "wi"]))
    sample(out, n_s)
  }
  sample_size <- object$sample_size
  to_iter <- seq_len(length(object$success_models))
  nsec_out <- sapply(to_iter, sample_nsec, object, sig_val, precision,
                     posterior = TRUE, hormesis_def, x_range,
                     xform, prob_vals, sample_size)
  nsec_out <- unlist(nsec_out)
  label <- paste("ec", sig_val, sep = "_")
  nsec_estimate <- quantile(nsec_out, probs = prob_vals)
  names(nsec_estimate) <- c(label, paste(label, "lw", sep = "_"),
                            paste(label, "up", sep = "_"))
  attr(nsec_estimate, 'precision') <- precision      
  attr(nsec_out, 'precision') <- precision
  attr(nsec_estimate, 'sig_val') <- sig_val      
  attr(nsec_out, 'sig_val') <- sig_val
  if (!posterior) {
    nsec_estimate
  } else {
    nsec_out
  }
}

nsec_fct <- function(y, reference, x_vec) {
  x_vec[min_abs(y - reference)]
}