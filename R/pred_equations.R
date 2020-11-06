pred_nec3param <- function(b_beta, b_nec, b_top, x) {
  b_top * exp(-b_beta * (x - b_nec) *
    ifelse(x - b_nec < 0, 0, 1))
}

pred_nec4param <- function(b_beta, b_bot, b_nec, b_top, x) {
  b_bot + (b_top - b_bot) * exp(-b_beta * (x - b_nec) *
    ifelse(x - b_nec < 0, 0, 1))
}

pred_nechorme <- function(b_top, b_slope, b_beta, b_nec, x) {
  (b_top + b_slope * x) * exp(-b_beta * (x - b_nec) *
    ifelse(x - b_nec < 0, 0, 1))
}

pred_nechorme4 <- function(b_beta, b_bot, b_slope, b_nec, b_top, x) {
  b_bot + ((b_top + b_slope * x) - b_bot) * exp(-b_beta * (x - b_nec) *
                                  ifelse(x - b_nec < 0, 0, 1))
}

pred_necsigm <- function(b_beta, b_top, b_nec, b_d, x) {
  b_top * exp(-b_beta * ifelse(x - b_nec < 0, 0, (x - b_nec)^exp(b_d)) *
    ifelse(x - b_nec < 0, 0, 1))
}

pred_ecxlin <- function(b_top, b_slope, x) {
  b_top - b_slope * x
}

pred_ecxexp <- function(b_top, b_beta, x) {
  b_top * exp(-b_beta * x)
}

pred_ecxsigm <- function(b_top, b_beta, b_d, x) {
  b_top * exp(-b_beta * x^exp(b_d))
}

pred_ecx4param <- function(b_top, b_bot, b_ec50, b_beta, x) {
  b_top + (b_bot - b_top) /
    (1 + exp((b_ec50 - x) * b_beta))
}

pred_ecxwb1 <- function(b_bot, b_top, b_beta, b_ec50, x) {
  b_bot + (b_top - b_bot) *
    exp(-exp(b_beta * (x - b_ec50)))
}

pred_ecxwb2 <- function(b_bot, b_top, b_beta, b_ec50, x) {
  b_bot + (b_top - b_bot) *
    (1 - exp(-exp(b_beta * (x - b_ec50))))
}