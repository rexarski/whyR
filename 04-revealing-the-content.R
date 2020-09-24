if (!require(pacman)) install.packages("pacman")
pacman::p_load("tidyverse", "lubridate", "patchwork", "RSQLite", "jsonlite",
               "tidytext", "wordcloud", "tm")

# clean 1.98GB data, wow!
content_files <- list.files('data/content', pattern="*.csv", full.names=TRUE)

db <- dbConnect(SQLite(), dbname = "data/content.sqlite")

# create database
dbSendQuery(conn = db,
            "CREATE TABLE CONTENT
            (Url TEXT,
            Content TEXT)
            ")

# list tables in database
# dbListTables(db)
# list columns in a table
# dbListFields(db, "content")

for (file in content_files) {
  x <- read_csv(file)
  Url <- x$url
  Content <- str_squish(x$text)
  data <- cbind.data.frame(Url, Content)
  dbWriteTable(conn = db, name = "content", data,
               append = TRUE, row.names = FALSE)
  # cat(paste0(file, " migrated\n"))
}

articles <- fromJSON(readLines('data/hackathon/data/articles.json'))
tidy_articles <- tibble(
  By = unlist(articles$by),
  Descendants = unlist(articles$descendants),
  Id = unlist(articles$id),
  Score = unlist(articles$score),
  Time = unlist(articles$time),
  Title = unlist(articles$title),
  # type = unlist(articles$type),
  Url = sapply(articles$url, function(X) if (length(X) == 0) NA_character_ 
               else paste(X, collapse = " "))
) %>%
  mutate(Time = parse_datetime(Time)) %>%
  filter(Time >= as.Date("2020-01-01"))

dbSendQuery(conn = db,
            "CREATE TABLE ARTICLES
            (By TEXT,
            Descendants INTEGER,
            Id INTEGER,
            Score INTEGER,
            Time DATETIME,
            Title TEXT,
            Url TEXT)
            ")
dbWriteTable(conn = db, name = "articles", tidy_articles,
             append = TRUE, row.names = FALSE)

august_articles <- tidy_articles %>%
  filter(Time >= as.Date("2020-08-01"), Time < as.Date("2020-09-01"))

dbSendQuery(conn = db,
            "CREATE TABLE AUGUST
            (By TEXT,
            Descendants INTEGER,
            Id INTEGER,
            Score INTEGER,
            Time DATETIME,
            Title TEXT,
            Url TEXT)
            ")
dbWriteTable(conn = db, name = "august", august_articles,
             append = TRUE, row.names = FALSE)

# save(tidy_articles, august_articles, articles, file = "ch4.RData")

august_content <- dbGetQuery(db, paste0("
  SELECT August.Id, Content.Content 
  FROM August
  INNER JOIN Content on Content.Url = August.Url;"))

wordcloud <- tibble(
  word = character(),
  n = integer(),
  Id = integer()
)
for (story in 1:nrow(august_articles)) {
# for (story in 1:1) {
  tidy_dat <- august_content[story,] %>%
    unnest_tokens(word, Content) %>%
    anti_join(stop_words) %>%
    count(word) %>%
    arrange(desc(n)) %>%
    top_n(5)
  tidy_dat$Id <- content$Id
  tidy_dat <- as_tibble(tidy_dat)
  wordcloud <- bind_rows(wordcloud, tidy_dat)
  cat("Total: ", nrow(august_articles), "; Current: ", story)
}

# wordcloud %>%
#   arrange(desc(n)) %>%
#   filter(n <= 20) %>%
#   distinct(Id, word, .keep_all =TRUE)

new_stop_words <- wordcloud %>%
  filter(n >= 20) %>%
  filter(nchar(word) >= 15) %>%
  select(word) %>%
  distinct()
custom_stop_words <- bind_rows(tibble(word = new_stop_words$word,
                                          lexicon = "custom"),
                               stop_words)

# re-run
wordcloud <- tibble(
  word = character(),
  n = integer(),
  Id = integer()
)
for (story in 1:nrow(august_articles)) {
  # for (story in 1:1) {
  tidy_dat <- august_content[story,] %>%
    unnest_tokens(word, Content) %>%
    anti_join(custom_stop_words) %>%
    count(word) %>%
    arrange(desc(n)) %>%
    top_n(5)
  tidy_dat$Id <- content$Id
  tidy_dat <- as_tibble(tidy_dat)
  wordcloud <- bind_rows(wordcloud, tidy_dat)
  cat("Total: ", nrow(august_articles), "; Current: ", story)
}

# wordcloud!
wordcloud %>%
  with(wordcloud(word, n, max.words = 200))

# disconnect db
dbDisconnect(db)
