library(piggyback)

con <- cordis_con()

cordis_tables()

# add GITHUB_TOKEN, first create one at GitHub with repo permissions
#file.edit("~/.Renviron")
#readRenviron("~/.Renviron")

pb_new_release("KTH-Library/cordis", "v0.1")

cordis_disconnect(con)
