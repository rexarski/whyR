if (!require(pacman)) install.packages("pacman")
pacman::p_load("tidyverse", "lubridate", "patchwork", "RSQLite")

# clean 1.98GB data, wow!
content_files <- list.files('data/content', pattern="*.csv", full.names=TRUE)

db <- dbConnect(SQLite(), dbname = "data/content.sqlite")

# create database
dbSendQuery(conn = db,
            "CREATE TABLE CONTENT
            (Url TEXT,
            Content TEXT,
            Score INTEGER,
            ID INTEGER)
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
  cat(paste0(file, " migrated"))
}

# ------------------ under construction ------------------

# x = dbGetQuery(db, "
#    SELECT * FROM content
# "))

# disconnect db
# dbDisconnect(db)
