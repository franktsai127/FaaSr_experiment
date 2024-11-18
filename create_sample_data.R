create_sample_data <- function(folder, output1, output2) {
  ###################### ADD NETWORK MONITORING FUNCTION #####################################
  system('sudo apt-get update && apt-get upgrade -y')
  system('sudo apt-get install -y r-base python3 python3-dev python3-pip python3-venv')
  install.packages("reticulate")
  library(reticulate)
  use_python("/usr/bin/python3.10")
  system('sudo pip install --upgrade psutil')
  psutil <- import("psutil")
  
  # Function to fetch and return formatted network statistics
  get_network_stats <- function() {
    net_io <- psutil$net_io_counters(pernic = TRUE)
    stats <- lapply(names(net_io), function(name) {
      interface_stats <- net_io[[name]]
      list(
        Interface = name,
        Bytes_Sent = interface_stats$bytes_sent,
        Bytes_Recv = interface_stats$bytes_recv,
        Packets_Sent = interface_stats$packets_sent,
        Packets_Recv = interface_stats$packets_recv
      )
    })
    names(stats) <- names(net_io)
    return(stats)
  }
  
  # Function to run any given function with network monitoring
  run_with_network_monitoring <- function(func, ...) {
