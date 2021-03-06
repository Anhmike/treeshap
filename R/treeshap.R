#' Calculate SHAP values of a tree ensemble model.
#'
#' Check the structure of your ensemble model and calculate feature importance using \code{treeshap()} function.
#'
#'
#' @param model Unified dataframe representation of the model created with a (model).unify function.
#' @param x Observations to be explained. A dataframe with the same columns as in the training set of the model.
#' @param interactions Wheter to calculate SHAP interaction values. By default is \code{FALSE}.
#'
#' @return If \code{interactions = FALSE} then *SHAP values* for given observations. A dataframe with the same columns as in the training set of the model.
#' Value from a column and a row is the SHAP value of the feature of the observation.
#'
#' If \code{interactions = TRUE} then *SHAP interaction values* for given observations.
#' A 3 dimensional array, where third dimension corresponds to the observation, and every 2d slice is a matrix containing SHAP interaction values for this observation.
#'
#' @export
#'
#' @importFrom Rcpp sourceCpp
#' @useDynLib treeshap
#'
#' @seealso
#' \code{\link{xgboost.unify}} for \code{XGBoost models}
#' \code{\link{lightgbm.unify}} for \code{LightGBM models}
#' \code{\link{gbm.unify}} for \code{GBM models}
#' \code{\link{catboost.unify}} for \code{catboost models}
#' \code{\link{randomForest.unify}} for \code{randomForest models}
#' \code{\link{ranger.unify}} for \code{ranger models}
#'
#' @examples
#' \dontrun{
#' library(xgboost)
#' data <- fifa20$data[colnames(fifa20$data) != 'work_rate']
#' target <- fifa20$target
#'
#' # calculating simple SHAP values
#' param <- list(objective = "reg:squarederror", max_depth = 3)
#' xgb_model <- xgboost::xgboost(as.matrix(data), params = param, label = target, nrounds = 200)
#' unified_model <- xgboost.unify(xgb_model)
#' treeshap(unified_model, head(data, 3))
#'
#' # calculating SHAP interaction values
#' param2 <- list(objective = "reg:squarederror", max_depth = 20)
#' xgb_model2 <- xgboost::xgboost(as.matrix(data), params = param, label = target, nrounds = 10)
#' unified_model2 <- xgboost.unify(xgb_model)
#' treeshap(unified_model2, head(data, 3), interactions = TRUE)
#'}
treeshap <- function(model, x, interactions = FALSE) {
  # argument check
  if (!all(c("Tree", "Node", "Feature", "Split", "Yes", "No", "Missing", "Quality/Score", "Cover") %in% colnames(model))) {
    stop("Given model dataframe is not a correct unified dataframe representation. Use (model).unify function.")
  }

  doesnt_work_with_NAs <- all(is.na(model$Missing)) #any(is.na(model$Missing) & !is.na(model$Feature)) #
  if (doesnt_work_with_NAs && any(is.na(x))) {
    stop("Given model does not work with missing values. Dataset x should not contain missing values.")
  }

  # adapting model representation to C++ and extracting from dataframe to vectors
  roots <- which(model$Node == 0) - 1
  yes <- model$Yes - 1
  no <- model$No - 1
  missing <- model$Missing - 1
  feature <- match(model$Feature, colnames(x)) - 1
  is_leaf <- is.na(model$Feature)
  value <- model[["Quality/Score"]]
  cover <- model$Cover

  # creating matrix containing information whether each observation fulfills each node split condition
  feature_columns <- feature + 1
  feature_columns[is.na(feature_columns)] <- 1
  fulfills <- t(t(x[, feature_columns]) <= model$Split)
  fulfills[, is.na(feature_columns)] <- NA

  if (!interactions) {
    # computing basic SHAPs
    shaps <- matrix(numeric(0), ncol = ncol(x))
    for (obs in 1:nrow(x)) {
      shaps_row <- treeshap_cpp(ncol(x), fulfills[obs, ], roots,
                                yes, no, missing, feature, is_leaf, value, cover)
      shaps <- rbind(shaps, shaps_row)
    }

    colnames(shaps) <- colnames(x)
    rownames(shaps) <- c()
    shaps <- as.data.frame(shaps)
    attr(shaps, "class") <- c("data.frame", "shaps")
    return(shaps)
  } else {
    # computing SHAP interaction values
    interactions_array <- array(numeric(0),
                                dim = c(ncol(x), ncol(x), nrow(x)),
                                dimnames = list(colnames(x), colnames(x), c()))
    for (obs in 1:nrow(x)) {
      interactions_slice <- treeshap_interactions_cpp(ncol(x), fulfills[obs, ], roots, yes,
                                                      no, missing, feature, is_leaf, value, cover)
      interactions_array[, , obs] <- interactions_slice
    }
    attr(interactions_array, "class") <- c("array", "shap.interactions")
    return(interactions_array)
  }
}

