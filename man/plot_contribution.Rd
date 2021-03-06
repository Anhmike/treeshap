% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.R
\name{plot_contribution}
\alias{plot_contribution}
\title{SHAP value based Break-Down plot}
\usage{
plot_contribution(
  shap,
  x = NULL,
  model = NULL,
  max_vars = 5,
  min_max = NA,
  digits = 3,
  title = "SHAP Break-Down",
  subtitle = ""
)
}
\arguments{
\item{shap}{SHAP values dataframe produced with the \code{treeshap} function, containing only one row.}

\item{x}{\code{NULL} or dataframe with 1 observation used to calculate \code{shap}.
Used only for aesthetic reasons - to include observation values for a different variables next to the variable names in labels on the y axis.
By default is \code{NULL} and then labels on the y axis are just variable names.}

\item{model}{\code{NULL} or dataframe containing unified representation of explained model created with a (model).unify function.
Used to calculate mean prediction of the model to use as a baseline.
If \code{NULL} then baseline will be set as \code{0} and difference between individual prediction and model's mean prediction will be explained.}

\item{max_vars}{maximum number of variables that shall be presented. Variables with the highest importance will be presented.
Remaining variables will be summed into one additional contribution. By default \code{5}.}

\item{min_max}{a range of OX axis. By default \code{NA}, therefore it will be extracted from the contributions of \code{x}.
But it can be set to some constants, useful if these plots are to be used for comparisons.}

\item{digits}{number of decimal places (\code{\link{round}}) to be used.}

\item{title}{the plot's title, by default \code{'SHAP Break-Down'}.}

\item{subtitle}{the plot's subtitle. By default no subtitle.}
}
\value{
a \code{ggplot2} object
}
\description{
This function plots contributions of features into the prediction for a single observation.
}
\examples{
\dontrun{
library(xgboost)
data <- fifa20$data[colnames(fifa20$data) != 'work_rate']
target <- fifa20$target
param <- list(objective = "reg:squarederror", max_depth = 3)
xgb_model <- xgboost::xgboost(as.matrix(data), params = param, label = target, nrounds = 200)
unified_model <- xgboost.unify(xgb_model)
x <- head(data, 1)
shap <- treeshap(unified_model, x)
plot_contribution(shap, x, unified_model, min_max = c(0, 120000000))
}
}
\seealso{
\code{\link{treeshap}} for calculation of SHAP values
}
