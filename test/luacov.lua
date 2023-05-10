return {
  statsfile = "<% return os.getenv('STATS_FILE') %>",
  reportfile = "<% return os.getenv('REPORT_FILE') %>",
  includeuntestedfiles = true,
  include = { "src" }
}
