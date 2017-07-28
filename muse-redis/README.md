muse-redis
==========

Start up the proper redis server instance.  Used to store corpus uuid mappings and crawler latest id crawled. 

Dependencies

    yum install redis-server

(on Muse2)
Verify the default service isn't started

    sudo service redis stop

Start the redis tmux session:

    cd muse-redis 
    
    run ./tmux-new.sh 
    
from the tmux session: 

    run sudo docker-compose up –d
