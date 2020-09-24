# 1. setup

if (!require(pacman)) install.packages("pacman")
pacman::p_load("tidyverse", "jsonlite", "tidyjson", "tidyr",
               "lubridate")

# 2. clean articles data

articles <- fromJSON(readLines('data/hackathon/data/articles.json'))
jsons <- list.files('data/hackathon/data', pattern="*.json", full.names=TRUE)

tidy_articles <- tibble(
  by = unlist(articles$by),
  descendants = unlist(articles$descendants),
  id = unlist(articles$id),
  # comment_count = lengths(articles$kids),
  kids = articles$kids,
  score = unlist(articles$score),
  time = unlist(articles$time),
  title = unlist(articles$title),
  type = unlist(articles$type),
  url = sapply(articles$url, function(X) if (length(X) == 0) NA_character_ 
               else paste(X, collapse = " "))
) %>%
  mutate(time = parse_datetime(time)) %>%
  filter(time >= as.Date("2020-01-01"))

articles_by_day <- tidy_articles %>%
  group_by(time=floor_date(time, "day")) %>%
  summarize(a_num=n())

daily_top <- tidy_articles %>%
  group_by(time=floor_date(time, "day")) %>%
  select(time, score) %>%
  group_by(time) %>%
  summarize(score=max(score))

# 3. clean comments data

# remove the empty one "comments.json", as well as recent ones (different
# structure)
jsons <- jsons[!(jsons %in% c("data/hackathon/data/articles.json",
                              "data/hackathon/data/comments.json",
                             "data/hackathon/data/comments_recent.json"))]
# clean up the rest comments files
comments <- tibble()
for (file in jsons) {
  partial <- fromJSON(readLines(file, encoding = "utf8"))
  comments <- comments %>%
    bind_rows(partial)
}
rm(partial)

comments <- tibble(
  by = sapply(comments$by, function(X) if (length(X) == 0) NA_character_ 
              else paste(X, collapse = " ")),
  id = unlist(comments$id),
  kids = comments$kids,
  parent = unlist(comments$parent),
  text = sapply(comments$text, function(X) if (length(X) == 0) NA_character_ 
                else paste(X, collapse = " ")),
  time = unlist(comments$time),
  type = unlist(comments$type),
  deleted = sapply(comments$deleted, function(X) if (length(X) == 0) NA_character_ 
                   else paste(X, collapse = " ")),
  dead = sapply(comments$dead, function(X) if (length(X) == 0) NA_character_ 
                else paste(X, collapse = " "))
)

comments_raw <- comments
comments <- comments %>%
  arrange(id) %>%
  group_by(id) %>%
  slice(1) %>%
  select(time, id) %>%
  mutate(time = parse_datetime(time)) %>%
  filter(time >= as.Date("2020-01-01"))

recent_comments <- fromJSON(readLines('data/hackathon/data/comments_recent.json',
                               encoding="utf8")) %>%
  as_tibble() %>%
  mutate(time = parse_datetime(time)) %>%
  drop_na() %>%
  select(id, time) %>%
  filter(time >= as.Date("2020-01-01"))
  
tidy_comments <- bind_rows(comments, recent_comments) %>%
  arrange(id) %>%
  group_by(id) %>%
  slice(1)

comments_by_day <- tidy_comments %>%
  group_by(time=floor_date(time, "day")) %>%
  summarize(c_num=n())

# 4. aggregate all together for challenge 1

tidy_data <- articles_by_day %>%
  inner_join(daily_top, by = "time") %>%
  left_join(comments_by_day, by = "time") %>%
  mutate(time = as_date(time))

save(tidy_data, articles_by_day, daily_top, comments_by_day,
     comments_raw, tidy_data_impute,  file = "tidy_data.RData")

# clean up
# rm(list = ls())
# gc()
