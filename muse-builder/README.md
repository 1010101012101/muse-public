MUSE-Builder
========

Run
----
corpus-crawler contains the code for running the builder. See Readme here: 

    https://github.com/museprogram/muse/blob/master/muse-builder/corpusCrawler/README.md

Setup Docker containers
-----------------------

I had to resort to installing all of the packages after the container was deployed (run-time) because there were too many packages to install them at container build time (at the time docker only supported 127 install instructions/states with their checkpointed filesystem).
 
After the basic container instantiation (that’s on muse2 in a salt state), I made the following changes for the Ubuntu containers (this wasn’t necessary for the fedora containers):
 
Changed /etc/apt/sources.list to the following:
 
    deb http://us.archive.ubuntu.com/ubuntu/ trusty main restricted
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty main restricted

    deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates main restricted
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-updates main restricted

    deb http://us.archive.ubuntu.com/ubuntu/ trusty universe
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty universe
    deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates universe
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-updates universe


    deb http://us.archive.ubuntu.com/ubuntu/ trusty multiverse
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty multiverse
    deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates multiverse
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-updates multiverse

    deb http://us.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse
    deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse

    deb http://security.ubuntu.com/ubuntu trusty-security main restricted
    deb-src http://security.ubuntu.com/ubuntu trusty-security main restricted
    deb http://security.ubuntu.com/ubuntu trusty-security universe
    deb-src http://security.ubuntu.com/ubuntu trusty-security universe
    deb http://security.ubuntu.com/ubuntu trusty-security multiverse
    deb-src http://security.ubuntu.com/ubuntu trusty-security multiverse

 
This process installs the all of the packages available (or tries to at least):
 
    apt-cache search --names-only \[a-z\]* | sed 's/\ \(.*\)//') > package_list

and then using package_list as stdin for this script:


    while read p
    do
        echo "::::::" $p
        apt-get -y build-dep $p
    done < "${1:-/dev/stdin}"


but first you have to run 

    dpkg-reconfigure debconf

and set the "Noninteractive" option to "critical" so it doesn't keep stopping and asking you to manually configure things like the root password for the SQL server. 
 
After the first round which took nearly to a week to run, I diff’d the installed packages with the packages that existed but weren’t installed and tried to manually install them.
 
For fedora the process was simpler but followed the same setup. 
 
I ran the following to construct the yum package list on each versioned fedora container:
 
    yum list all | cut -d ' ' -f 1 > package_list
 
And then ran a fedora variant of the loop within the script on the resulting file list:
 
    while read p
    do
        echo "::::::" $p
        yum install -y $p
    done < "${1:-/dev/stdin}"
 
After the script completed, I went through and diffed the installed packages with the packages available looking for ones that didn’t install and then manually went through those packages to see if I could install them. For most of them, I could not (version issues, dependency issues with other installed packages, etc…).

