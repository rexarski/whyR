if (!require(pacman)) install.packages("pacman")
pacman::p_load("tidyverse", "lubridate", "forecast", "hrbrthemes",
               "patchwork", "imputeTS")
load("tidy_data.RData")

set.seed(2020)

p_a <- ggplot(tidy_data, aes(x=time, y=a_num)) +
  geom_line(color="steelblue") +
  geom_point(alpha=0.8, size=0.5) +
  xlab("") +
  ylab("Number of articles") +
  ggtitle("Time series of daily new articles in 2020") +
  theme_ipsum_rc() +
  theme(axis.text.x=element_text(angle=30, hjust=1)) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 month") +
  # limit=c(as_date("2020-01-01"),as_date("2020-09-30"))) +
  ylim(0, max(tidy_data$a_num) + 10)

recent_tidy_data <- tidy_data %>%
  filter(time>=as_date("2020-08-14"))
p_c <- ggplot(recent_tidy_data, aes(x=time, y=c_num)) +
  geom_line(color="seagreen") +
  geom_point(alpha=0.8, size=0.5) +
  xlab("") +
  ylab("Number of comments") +
  ggtitle("Time series of recent daily new comments") +
  theme_ipsum_rc() +
  theme(axis.text.x=element_text(angle=30, hjust=1)) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 week") +
  # limit=c(as_date("2020-01-01"),as_date("2020-09-30"))) +
  ylim(0, max(tidy_data$c_num) + 10)

# interpolation
p_c2 <- ggplot(tidy_data_impute, aes(x=time, y=c_num)) +
  geom_line(color="seagreen4") +
  geom_point(alpha=0.8, size=0.5) +
  xlab("") +
  ylab("Number of comments") +
  ggtitle("Time series of daily new comments in 2020", 
          subtitle = "With missing data interpolated linearly") +
  theme_ipsum_rc() +
  theme(axis.text.x=element_text(angle=30, hjust=1)) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 month") +
  # limit=c(as_date("2020-01-01"),as_date("2020-09-30"))) +
  ylim(0, max(tidy_data_impute$c_num) + 10)

p_s <- ggplot(tidy_data, aes(x=time, y=score)) +
  geom_line(color="coral") +
  geom_point(alpha=0.8, size=0.5) +
  xlab("") +
  ylab("Top score of articles") +
  ggtitle("Time series of daily top score articles in 2020") +
  theme_ipsum_rc() +
  theme(axis.text.x=element_text(angle=30, hjust=1)) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 month") +
  # limit=c(as_date("2020-01-01"),as_date("2020-09-30"))) +
  ylim(0, max(tidy_data$score) + 50)

p_a / p_s
p_c / p_c2

# --------------------------------------------------------------------
# do time series analysis on:
# 1. the number of posts
# 2. the number of comments
# 3. the `max(score)` within a day

# dat_train <- tidy_data %>%
#   filter(time < as_date("2020-09-01"))
# dat_test <- tidy_data %>%
#   filter(time >= as_date("2020-09-01"))

# mean absolute percentage error
mape <- function(predicted, actual) {
  mape <- mean(abs((predicted - actual)/actual)) * 100
  return(mape)
}

# Article number (ARIMA)
fit_anum_arima <- auto.arima(tidy_data$a_num)
summary(fit_anum_arima)
forecast(fit_anum_arima, h=2)

# Highest score (ARIMA)
fit_score_arima <- auto.arima(tidy_data$score)
summary(fit_score_arima)
forecast(fit_score_arima, h=2)

# # Comment number (TBATS)
# fit_cnum_tbats <- tbats(tidy_data_impute$c_num)
# summary(fit_cnum_tbats)
# forecast(fit_cnum_tbats, h=2)

# Comment number (ARIMA)
fit_cnum_arima <- arima(tidy_data_impute$c_num)
summary(fit_cnum_arima)
forecast(fit_cnum_arima, h=2)

# conclusion
pred_anum <- 93 # 93 new articles on 2020-09-25
pred_score <- 1139 # 1139 new top score on 2020-09-25
pred_cnum <- 1235 # 1641 new comments on 2020-09-25
