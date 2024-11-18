compute_sum <- function(folder, input1, input2, output) {
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
    
    before_stats <- get_network_stats()
    func(...)  # Run the passed function
    after_stats <- get_network_stats()
    
    # Calculate and return the differences in network traffic
    network_diff <- lapply(names(before_stats), function(name) {
      if (name %in% names(after_stats)) {
        before <- before_stats[[name]]
        after <- after_stats[[name]]
        list(
          Interface = name,
          Bytes_Sent_Diff = after$Bytes_Sent - before$Bytes_Sent,
          Bytes_Recv_Diff = after$Bytes_Recv - before$Bytes_Recv,
          Packets_Sent_Diff = after$Packets_Sent - before$Packets_Sent,
          Packets_Recv_Diff = after$Packets_Recv - before$Packets_Recv
        )
      }
    })
    return(network_diff)
  }
  
  ###################### ADD NETWORK MONITORING FUNCTION #####################################
  # Download two input files from bucket, generate a sum of their contents, and write back to bucket

  # The function uses the default S3 bucket name, configured in the FaaSr JSON 
  # folder: name of the folder where the inputs and outputs reside
  # input1, input2: names of the input files
  # output: name of the output file
  
  # The bucket is configured in the JSON payload as My_S3_Bucket
  # In this demo code, all inputs/outputs are in the same S3 folder, which is also configured by the user
  # The downloaded files are stored in a "local" folder under names input1.csv and input2.csf
  #
  #faasr_get_file(remote_folder=folder, remote_file=input1, local_file="input1.csv")
  #faasr_get_file(remote_folder=folder, remote_file=input2, local_file="input2.csv")
  
  log_msg <- paste0('Monitoring Results:')
  result_one <- run_with_network_monitoring(faasr_get_file, remote_folder=folder, remote_file=input1, local_file="input1.csv")
  log_msg <- paste0(log_msg, result_one)
  log_msg <- paste0(log_msg, 'Monitoring Results:')
  result_two <- run_with_network_monitoring(faasr_get_file, remote_folder=folder, remote_file=input2, local_file="input2.csv")
  log_msg <- paste0(log_msg, result_two)
  
  # This demo function computes output <- input1 + input2 and stores the output back into S3
  # First, read the local inputs, compute the sum, and store the output locally
  # 
  frame_input1 <- read.table("input1.csv", sep=",", header=T)
  frame_input2 <- read.table("input2.csv", sep=",", header=T)
  frame_output <- frame_input1 + frame_input2
  write.table(frame_output, file="output.csv", sep=",", row.names=F, col.names=T)

  # Now, upload the output file to the S3 bucket
  #
  #faasr_put_file(local_file="output.csv", remote_folder=folder, remote_file=output)
  log_msg <- paste0(log_msg, 'Monitoring Results:')
  result_three <- run_with_network_monitoring(faasr_put_file, local_file="output.csv", remote_folder=folder, remote_file=output)
  log_msg <- paste0(log_msg, result_three)

  # Print a log message
  # 
  log_msg <- paste0(log_msg, 'Function compute_sum finished; output written to ', folder, '/', output, ' in default S3 bucket')
  faasr_log(log_msg)
}	
