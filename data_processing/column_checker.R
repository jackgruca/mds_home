    # data_processing/column_checker.R
    library(nflreadr)
    library(dplyr)

    seasons_to_load <- 2021:nflreadr::most_recent_season()

    cat("\n--- COLUMNS FOR Next Gen Stats (Passing) ---\n")
    ngs_pass <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "passing")
    print(colnames(ngs_pass))

    cat("\n\n--- COLUMNS FOR Next Gen Stats (Receiving) ---\n")
    ngs_receive <- nflreadr::load_nextgen_stats(seasons = seasons_to_load, stat_type = "receiving")
    print(colnames(ngs_receive))