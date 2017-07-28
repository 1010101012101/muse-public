muse-mongo
==========

Start up the proper mongo server instance.  Used to store github crawler's project info from github-finder. 

Dependencies

    yum install mongodb

(on Muse2)
Verify the default service isn't started

    sudo service mongo stop

Start the mongo tmux session:

    cd muse-mongo 
    
    run ./tmux-new.sh 
    
from the tmux session: 

    run sudo docker-compose up –d
