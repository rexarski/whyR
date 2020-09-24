# if (!require(pacman)) install.packages("pacman")
# pacman::p_load("tidyverse", "jsonlite", "tidyjson", "tidyr",
#                "lubridate", "textdata", "tidytext")
# get_sentiments("afinn")
# 
# # only recent comments
# comments <- fromJSON(readLines('data/hackathon/data/comments_recent.json',
#                                       encoding="utf8")) %>%
#   as_tibble() %>%
#   mutate(time = parse_datetime(time)) %>%
#   drop_na() %>%
#   select(by, text, time)
# 
# sentimental_score <- comments$text %>%
#   