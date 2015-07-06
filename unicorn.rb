# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
@dir =  File.expand_path(File.dirname(__FILE__)) + "/"

worker_processes 2
working_directory @dir

timeout 50

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen "#{@dir}tmp/sockets/unicorn.sock", :backlog => 64

# Set process id path
pid "#{@dir}tmp/pids/unicorn.pid"
