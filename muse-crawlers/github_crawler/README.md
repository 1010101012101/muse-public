github-crawler
==============

Getting your access token setup
-------------------------------

Instructions can be found

    https://github.com/blog/1509-personal-api-tokens


Dependencies
------------

You will need the following

    mongo (yum)
    redis (uyum)
    docker (yum)
    python (yum)

    docker-compose (see below)

        curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s-uname -m` > /usr/local/bin/docker-compose

        Apply executable permissions to the binary:

           sudo chmod +x /usr/local/bin/docker-compose

        Test the installation.

           $ docker-compose --version docker-compose version 1.14.0, build 1719ceb

   1. Start up your mongodb instance
   
   	See Readme: https://github.com/museprogram/muse/blob/master/muse-mongo/README.md

   2. Start up your redis instance
   
   	See Readme: https://github.com/museprogram/muse/blob/master/muse-redis/README.md


Building Finder
--------
Github-finder must be run before cralwer to grab github project info into mongo.
Need to setup the node modules and compile the coffeescript to java script, I use a makefile to help out.

        cd github_finder
        docker-compose -f fig-make.yml up


Running Finder 
-------------

        docker-compse -f fig-custom.yml up


Building Crawler
--------

Need to setup the node modules and compile the coffeescript to java script, I use a makefile to help out.

        cd github_crawler
        docker-compose -f fig-make.yml up


Running Crawler
--------

        cd muse-crawlers
        sudo python startMUSEcrawlers.py --github default --out <path> --token <token>



Console Output will look something like this:

	Projects will be downloaded to:
	   .
	  Crawling Github Project:  synergy/synergy

	  Downloading code...

	Cloning into bare repository './synergy/bare_repo'...
	Cloning into './synergy/latest'...

	  code download done

	  Writing github info metadata to: 
	     ./synergy/github/info.json
	      received undefined results
	  Writing github contributors metadata to: 
	     ./synergy/github/contributors.json
	      received 14 results
	  Writing github languages metadata to: 
	     ./synergy/github/languages.json
	      received undefined results
	  Writing github forks metadata to: 
	     ./synergy/github/forks.json
	      received 30 results
	  Writing github tags metadata to: 
	     ./synergy/github/tags.json
	      received 30 results
	  Writing github releases metadata to: 
	     ./synergy/github/releases.json
	      received 0 results
	  Writing github branches metadata to: 
	     ./synergy/github/branches.json
	      page 1: 3 results
	  Writing github labels metadata to: 
	     ./synergy/github/labels.json
	      page 1: 7 results
	  Writing github milestones metadata to: 
	     ./synergy/github/milestones.json
	      page 1: 3 results
	  Writing github prs metadata to: 
	     ./synergy/github/prs.json
	      page 1: 7 results
	  Writing github issues metadata to: 
	     ./synergy/github/issues.json
	      page 1: 30 results
	      [...]
	      page 46: 23 results
	  Writing github commits metadata to: 
	     ./synergy/github/commits.json
	      page 1: 30 results
	      page 2: 30 results
	      [...]
	      page 57: 2 results
	  Writing github stargazers metadata to: 
	     ./synergy/github/stargazers.json
	      page 1: 30 results
	      page 2: 30 results
	      [...]
	      page 10: 25 results
	done



As each project is download, a uuid will be created and assigned to the file output and into a redis key:value pair.  The last downloaded project will also be stored so the crawler will resume where it left off.


The Project Download Format
---------------------------

The output from either the crawler or the downloader will be a folder with github content.  The top level directory structure looks like:

	bare_repo  # This is the git clone --bare' result which is a full repository clone but in repository form
	github     # This is the metadata folder
	latest     # This is the 'git clone --depth=1' result, source code for the project is here
	index.json # This is a meta-meta data file

For more information on bare repositories, like how to pull code from them, see: http://git-scm.com/book/en/v2/Git-on-the-Server-Getting-Git-on-a-Server

Index.json contains a few important pieces of information, like the project name, uuid (if pulled down via the crawler), date and time crawled in ISO 8601 format, and an array of github-metadata files collected (https://developer.github.com/v3/).

	{
	    "name": "synergy/synergy",
	    "site": "github",
	    "on_disk_ver": "1.1",
	    "crawled_date": "2014-11-20T17:27:02.008Z",
	    "uuid": null,
	    "site_specific_id": 25135037,
	    "code": "./latest",
	    "crawler_metadata": [
	        "./github/info.json",
	        "./github/contributors.json",
	        "./github/languages.json",
	        "./github/forks.json",
	        "./github/tags.json",
	        "./github/releases.json",
	        "./github/branches.json",
	        "./github/labels.json",
	        "./github/milestones.json",
	        "./github/prs.json",
	        "./github/issues.json",
	        "./github/commits.json"
	    ],
	    "git_bare_repo": "./bare_repo"
	}


Application developers could use this index.json file to load github-metadata without contending with browsing the directory structure.  The results have been de-paginated. For more detailed information on the contents, please refer to the Github API https://developer.github.com/v3/ and below...


Info
----

[https://developer.github.com/v3/repos/#get](https://developer.github.com/v3/repos/#get)

	{
	  "id": 1296269,
	  "owner": {
	    "login": "octocat",
	    "id": 1,
	    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	    "gravatar_id": "",
	    "url": "https://api.github.com/users/octocat",
	    "html_url": "https://github.com/octocat",
	    "followers_url": "https://api.github.com/users/octocat/followers",
	    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	    "organizations_url": "https://api.github.com/users/octocat/orgs",
	    "repos_url": "https://api.github.com/users/octocat/repos",
	    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	    "received_events_url": "https://api.github.com/users/octocat/received_events",
	    "type": "User",
	    "site_admin": false
	  },
	  "name": "Hello-World",
	  "full_name": "octocat/Hello-World",
	  "description": "This your first repo!",
	  "private": false,
	  "fork": false,
	  "url": "https://api.github.com/repos/octocat/Hello-World",
	  "html_url": "https://github.com/octocat/Hello-World",
	  "clone_url": "https://github.com/octocat/Hello-World.git",
	  "git_url": "git://github.com/octocat/Hello-World.git",
	  "ssh_url": "git@github.com:octocat/Hello-World.git",
	  "svn_url": "https://svn.github.com/octocat/Hello-World",
	  "mirror_url": "git://git.example.com/octocat/Hello-World",
	  "homepage": "https://github.com",
	  "language": null,
	  "forks_count": 9,
	  "stargazers_count": 80,
	  "watchers_count": 80,
	  "size": 108,
	  "default_branch": "master",
	  "open_issues_count": 0,
	  "has_issues": true,
	  "has_wiki": true,
	  "has_pages": false,
	  "has_downloads": true,
	  "pushed_at": "2011-01-26T19:06:43Z",
	  "created_at": "2011-01-26T19:01:12Z",
	  "updated_at": "2011-01-26T19:14:43Z",
	  "permissions": {
	    "admin": false,
	    "push": false,
	    "pull": true
	  },
	  "subscribers_count": 42,
	  "organization": {
	    "login": "octocat",
	    "id": 1,
	    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	    "gravatar_id": "",
	    "url": "https://api.github.com/users/octocat",
	    "html_url": "https://github.com/octocat",
	    "followers_url": "https://api.github.com/users/octocat/followers",
	    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	    "organizations_url": "https://api.github.com/users/octocat/orgs",
	    "repos_url": "https://api.github.com/users/octocat/repos",
	    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	    "received_events_url": "https://api.github.com/users/octocat/received_events",
	    "type": "Organization",
	    "site_admin": false
	  },
	  "parent": {
	    "id": 1296269,
	    "owner": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "name": "Hello-World",
	    "full_name": "octocat/Hello-World",
	    "description": "This your first repo!",
	    "private": false,
	    "fork": true,
	    "url": "https://api.github.com/repos/octocat/Hello-World",
	    "html_url": "https://github.com/octocat/Hello-World",
	    "clone_url": "https://github.com/octocat/Hello-World.git",
	    "git_url": "git://github.com/octocat/Hello-World.git",
	    "ssh_url": "git@github.com:octocat/Hello-World.git",
	    "svn_url": "https://svn.github.com/octocat/Hello-World",
	    "mirror_url": "git://git.example.com/octocat/Hello-World",
	    "homepage": "https://github.com",
	    "language": null,
	    "forks_count": 9,
	    "stargazers_count": 80,
	    "watchers_count": 80,
	    "size": 108,
	    "default_branch": "master",
	    "open_issues_count": 0,
	    "has_issues": true,
	    "has_wiki": true,
	    "has_pages": false,
	    "has_downloads": true,
	    "pushed_at": "2011-01-26T19:06:43Z",
	    "created_at": "2011-01-26T19:01:12Z",
	    "updated_at": "2011-01-26T19:14:43Z",
	    "permissions": {
	      "admin": false,
	      "push": false,
	      "pull": true
	    }
	  },
	  "source": {
	    "id": 1296269,
	    "owner": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "name": "Hello-World",
	    "full_name": "octocat/Hello-World",
	    "description": "This your first repo!",
	    "private": false,
	    "fork": true,
	    "url": "https://api.github.com/repos/octocat/Hello-World",
	    "html_url": "https://github.com/octocat/Hello-World",
	    "clone_url": "https://github.com/octocat/Hello-World.git",
	    "git_url": "git://github.com/octocat/Hello-World.git",
	    "ssh_url": "git@github.com:octocat/Hello-World.git",
	    "svn_url": "https://svn.github.com/octocat/Hello-World",
	    "mirror_url": "git://git.example.com/octocat/Hello-World",
	    "homepage": "https://github.com",
	    "language": null,
	    "forks_count": 9,
	    "stargazers_count": 80,
	    "watchers_count": 80,
	    "size": 108,
	    "default_branch": "master",
	    "open_issues_count": 0,
	    "has_issues": true,
	    "has_wiki": true,
	    "has_pages": false,
	    "has_downloads": true,
	    "pushed_at": "2011-01-26T19:06:43Z",
	    "created_at": "2011-01-26T19:01:12Z",
	    "updated_at": "2011-01-26T19:14:43Z",
	    "permissions": {
	      "admin": false,
	      "push": false,
	      "pull": true
	    }
	  }
	}

Contributors
------------

[https://developer.github.com/v3/repos/#list-contributors](https://developer.github.com/v3/repos/#list-contributors)

	[
	  {
	    "login": "octocat",
	    "id": 1,
	    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	    "gravatar_id": "",
	    "url": "https://api.github.com/users/octocat",
	    "html_url": "https://github.com/octocat",
	    "followers_url": "https://api.github.com/users/octocat/followers",
	    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	    "organizations_url": "https://api.github.com/users/octocat/orgs",
	    "repos_url": "https://api.github.com/users/octocat/repos",
	    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	    "received_events_url": "https://api.github.com/users/octocat/received_events",
	    "type": "User",
	    "site_admin": false,
	    "contributions": 32
	  }
	]



Languages
---------

[https://developer.github.com/v3/repos/#list-languages](https://developer.github.com/v3/repos/#list-languages)

	{
	  "C": 78769,
	  "Python": 7769
	}



Forks
-----

[https://developer.github.com/v3/repos/forks/](https://developer.github.com/v3/repos/forks/)

	[
	  {
	    "id": 1296269,
	    "owner": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "name": "Hello-World",
	    "full_name": "octocat/Hello-World",
	    "description": "This your first repo!",
	    "private": false,
	    "fork": true,
	    "url": "https://api.github.com/repos/octocat/Hello-World",
	    "html_url": "https://github.com/octocat/Hello-World",
	    "clone_url": "https://github.com/octocat/Hello-World.git",
	    "git_url": "git://github.com/octocat/Hello-World.git",
	    "ssh_url": "git@github.com:octocat/Hello-World.git",
	    "svn_url": "https://svn.github.com/octocat/Hello-World",
	    "mirror_url": "git://git.example.com/octocat/Hello-World",
	    "homepage": "https://github.com",
	    "language": null,
	    "forks_count": 9,
	    "stargazers_count": 80,
	    "watchers_count": 80,
	    "size": 108,
	    "default_branch": "master",
	    "open_issues_count": 0,
	    "has_issues": true,
	    "has_wiki": true,
	    "has_pages": false,
	    "has_downloads": true,
	    "pushed_at": "2011-01-26T19:06:43Z",
	    "created_at": "2011-01-26T19:01:12Z",
	    "updated_at": "2011-01-26T19:14:43Z",
	    "permissions": {
	      "admin": false,
	      "push": false,
	      "pull": true
	    }
	  }
	]



Tags
----

[https://developer.github.com/v3/git/tags/](https://developer.github.com/v3/git/tags/)

	{
	  "tag": "v0.0.1",
	  "sha": "940bd336248efae0f9ee5bc7b2d5c985887b16ac",
	  "url": "https://api.github.com/repos/octocat/Hello-World/git/tags/940bd336248efae0f9ee5bc7b2d5c985887b16ac",
	  "message": "initial version\n",
	  "tagger": {
	    "name": "Scott Chacon",
	    "email": "schacon@gmail.com",
	    "date": "2011-06-17T14:53:35-07:00"
	  },
	  "object": {
	    "type": "commit",
	    "sha": "c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c",
	    "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/c3d0be41ecbe669545ee3e94d31ed9a4bc91ee3c"
	  }
	}



Releases
--------

[https://developer.github.com/v3/repos/releases/](https://developer.github.com/v3/repos/releases/)

	[
	  {
	    "url": "https://api.github.com/repos/octocat/Hello-World/releases/1",
	    "html_url": "https://github.com/octocat/Hello-World/releases/v1.0.0",
	    "assets_url": "https://api.github.com/repos/octocat/Hello-World/releases/1/assets",
	    "upload_url": "https://uploads.github.com/repos/octocat/Hello-World/releases/1/assets{?name}",
	    "tarball_url": "https://api.github.com/repos/octocat/Hello-World/tarball/v1.0.0",
	    "zipball_url": "https://api.github.com/repos/octocat/Hello-World/zipball/v1.0.0",
	    "id": 1,
	    "tag_name": "v1.0.0",
	    "target_commitish": "master",
	    "name": "v1.0.0",
	    "body": "Description of the release",
	    "draft": false,
	    "prerelease": false,
	    "created_at": "2013-02-27T19:35:32Z",
	    "published_at": "2013-02-27T19:35:32Z",
	    "author": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "assets": [
	      {
	        "url": "https://api.github.com/repos/octocat/Hello-World/releases/assets/1",
	        "browser_download_url": "https://github.com/octocat/Hello-World/releases/download/v1.0.0/example.zip",
	        "id": 1,
	        "name": "example.zip",
	        "label": "short description",
	        "state": "uploaded",
	        "content_type": "application/zip",
	        "size": 1024,
	        "download_count": 42,
	        "created_at": "2013-02-27T19:35:32Z",
	        "updated_at": "2013-02-27T19:35:32Z",
	        "uploader": {
	          "login": "octocat",
	          "id": 1,
	          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	          "gravatar_id": "",
	          "url": "https://api.github.com/users/octocat",
	          "html_url": "https://github.com/octocat",
	          "followers_url": "https://api.github.com/users/octocat/followers",
	          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	          "organizations_url": "https://api.github.com/users/octocat/orgs",
	          "repos_url": "https://api.github.com/users/octocat/repos",
	          "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	          "received_events_url": "https://api.github.com/users/octocat/received_events",
	          "type": "User",
	          "site_admin": false
	        }
	      }
	    ]
	  }
	]



Branches
--------

[https://developer.github.com/v3/repos/#list-branches](https://developer.github.com/v3/repos/#list-branches)

	[
	  {
	    "name": "master",
	    "commit": {
	      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
	      "url": "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
	    }
	  }
	]



Labels
------

[https://developer.github.com/v3/issues/labels/](https://developer.github.com/v3/issues/labels/)

	[
	  {
	    "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
	    "name": "bug",
	    "color": "f29513"
	  }
	]



Milestones
----------

[https://developer.github.com/v3/issues/milestones/](https://developer.github.com/v3/issues/milestones/)

	[
	  {
	    "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
	    "number": 1,
	    "state": "open",
	    "title": "v1.0",
	    "description": "",
	    "creator": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "open_issues": 4,
	    "closed_issues": 8,
	    "created_at": "2011-04-10T20:09:31Z",
	    "updated_at": "2014-03-03T18:58:10Z",
	    "closed_at": "2013-02-12T13:22:01Z",
	    "due_on": null
	  }
	]



Pull Requests (pr)
------------------

[https://developer.github.com/v3/pulls/](https://developer.github.com/v3/pulls/)

	[
	  {
	    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1",
	    "html_url": "https://github.com/octocat/Hello-World/pull/1",
	    "diff_url": "https://github.com/octocat/Hello-World/pulls/1.diff",
	    "patch_url": "https://github.com/octocat/Hello-World/pulls/1.patch",
	    "issue_url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
	    "commits_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits",
	    "review_comments_url": "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments",
	    "review_comment_url": "https://api.github.com/repos/octocat/Hello-World/pulls/comments/{number}",
	    "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1/comments",
	    "statuses_url": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e",
	    "number": 1,
	    "state": "open",
	    "title": "new-feature",
	    "body": "Please pull these awesome changes",
	    "created_at": "2011-01-26T19:01:12Z",
	    "updated_at": "2011-01-26T19:01:12Z",
	    "closed_at": "2011-01-26T19:01:12Z",
	    "merged_at": "2011-01-26T19:01:12Z",
	    "head": {
	      "label": "new-topic",
	      "ref": "new-topic",
	      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
	      "user": {
	        "login": "octocat",
	        "id": 1,
	        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	        "gravatar_id": "",
	        "url": "https://api.github.com/users/octocat",
	        "html_url": "https://github.com/octocat",
	        "followers_url": "https://api.github.com/users/octocat/followers",
	        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	        "organizations_url": "https://api.github.com/users/octocat/orgs",
	        "repos_url": "https://api.github.com/users/octocat/repos",
	        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	        "received_events_url": "https://api.github.com/users/octocat/received_events",
	        "type": "User",
	        "site_admin": false
	      },
	      "repo": {
	        "id": 1296269,
	        "owner": {
	          "login": "octocat",
	          "id": 1,
	          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	          "gravatar_id": "",
	          "url": "https://api.github.com/users/octocat",
	          "html_url": "https://github.com/octocat",
	          "followers_url": "https://api.github.com/users/octocat/followers",
	          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	          "organizations_url": "https://api.github.com/users/octocat/orgs",
	          "repos_url": "https://api.github.com/users/octocat/repos",
	          "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	          "received_events_url": "https://api.github.com/users/octocat/received_events",
	          "type": "User",
	          "site_admin": false
	        },
	        "name": "Hello-World",
	        "full_name": "octocat/Hello-World",
	        "description": "This your first repo!",
	        "private": false,
	        "fork": false,
	        "url": "https://api.github.com/repos/octocat/Hello-World",
	        "html_url": "https://github.com/octocat/Hello-World",
	        "clone_url": "https://github.com/octocat/Hello-World.git",
	        "git_url": "git://github.com/octocat/Hello-World.git",
	        "ssh_url": "git@github.com:octocat/Hello-World.git",
	        "svn_url": "https://svn.github.com/octocat/Hello-World",
	        "mirror_url": "git://git.example.com/octocat/Hello-World",
	        "homepage": "https://github.com",
	        "language": null,
	        "forks_count": 9,
	        "stargazers_count": 80,
	        "watchers_count": 80,
	        "size": 108,
	        "default_branch": "master",
	        "open_issues_count": 0,
	        "has_issues": true,
	        "has_wiki": true,
	        "has_pages": false,
	        "has_downloads": true,
	        "pushed_at": "2011-01-26T19:06:43Z",
	        "created_at": "2011-01-26T19:01:12Z",
	        "updated_at": "2011-01-26T19:14:43Z",
	        "permissions": {
	          "admin": false,
	          "push": false,
	          "pull": true
	        }
	      }
	    },
	    "base": {
	      "label": "master",
	      "ref": "master",
	      "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
	      "user": {
	        "login": "octocat",
	        "id": 1,
	        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	        "gravatar_id": "",
	        "url": "https://api.github.com/users/octocat",
	        "html_url": "https://github.com/octocat",
	        "followers_url": "https://api.github.com/users/octocat/followers",
	        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	        "organizations_url": "https://api.github.com/users/octocat/orgs",
	        "repos_url": "https://api.github.com/users/octocat/repos",
	        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	        "received_events_url": "https://api.github.com/users/octocat/received_events",
	        "type": "User",
	        "site_admin": false
	      },
	      "repo": {
	        "id": 1296269,
	        "owner": {
	          "login": "octocat",
	          "id": 1,
	          "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	          "gravatar_id": "",
	          "url": "https://api.github.com/users/octocat",
	          "html_url": "https://github.com/octocat",
	          "followers_url": "https://api.github.com/users/octocat/followers",
	          "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	          "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	          "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	          "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	          "organizations_url": "https://api.github.com/users/octocat/orgs",
	          "repos_url": "https://api.github.com/users/octocat/repos",
	          "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	          "received_events_url": "https://api.github.com/users/octocat/received_events",
	          "type": "User",
	          "site_admin": false
	        },
	        "name": "Hello-World",
	        "full_name": "octocat/Hello-World",
	        "description": "This your first repo!",
	        "private": false,
	        "fork": false,
	        "url": "https://api.github.com/repos/octocat/Hello-World",
	        "html_url": "https://github.com/octocat/Hello-World",
	        "clone_url": "https://github.com/octocat/Hello-World.git",
	        "git_url": "git://github.com/octocat/Hello-World.git",
	        "ssh_url": "git@github.com:octocat/Hello-World.git",
	        "svn_url": "https://svn.github.com/octocat/Hello-World",
	        "mirror_url": "git://git.example.com/octocat/Hello-World",
	        "homepage": "https://github.com",
	        "language": null,
	        "forks_count": 9,
	        "stargazers_count": 80,
	        "watchers_count": 80,
	        "size": 108,
	        "default_branch": "master",
	        "open_issues_count": 0,
	        "has_issues": true,
	        "has_wiki": true,
	        "has_pages": false,
	        "has_downloads": true,
	        "pushed_at": "2011-01-26T19:06:43Z",
	        "created_at": "2011-01-26T19:01:12Z",
	        "updated_at": "2011-01-26T19:14:43Z",
	        "permissions": {
	          "admin": false,
	          "push": false,
	          "pull": true
	        }
	      }
	    },
	    "_links": {
	      "self": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1"
	      },
	      "html": {
	        "href": "https://github.com/octocat/Hello-World/pull/1"
	      },
	      "issue": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/issues/1"
	      },
	      "comments": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/issues/1/comments"
	      },
	      "review_comments": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1/comments"
	      },
	      "review_comment": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/pulls/comments/{number}"
	      },
	      "commits": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/pulls/1/commits"
	      },
	      "statuses": {
	        "href": "https://api.github.com/repos/octocat/Hello-World/statuses/6dcb09b5b57875f334f61aebed695e2e4193db5e"
	      }
	    },
	    "user": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    }
	  }
	]


Issues
------

[https://developer.github.com/v3/issues/](https://developer.github.com/v3/issues/)

	[
	  {
	    "url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
	    "html_url": "https://github.com/octocat/Hello-World/issues/1347",
	    "number": 1347,
	    "state": "open",
	    "title": "Found a bug",
	    "body": "I'm having a problem with this.",
	    "user": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "labels": [
	      {
	        "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
	        "name": "bug",
	        "color": "f29513"
	      }
	    ],
	    "assignee": {
	      "login": "octocat",
	      "id": 1,
	      "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	      "gravatar_id": "",
	      "url": "https://api.github.com/users/octocat",
	      "html_url": "https://github.com/octocat",
	      "followers_url": "https://api.github.com/users/octocat/followers",
	      "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	      "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	      "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	      "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	      "organizations_url": "https://api.github.com/users/octocat/orgs",
	      "repos_url": "https://api.github.com/users/octocat/repos",
	      "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	      "received_events_url": "https://api.github.com/users/octocat/received_events",
	      "type": "User",
	      "site_admin": false
	    },
	    "milestone": {
	      "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
	      "number": 1,
	      "state": "open",
	      "title": "v1.0",
	      "description": "",
	      "creator": {
	        "login": "octocat",
	        "id": 1,
	        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
	        "gravatar_id": "",
	        "url": "https://api.github.com/users/octocat",
	        "html_url": "https://github.com/octocat",
	        "followers_url": "https://api.github.com/users/octocat/followers",
	        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
	        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
	        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
	        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
	        "organizations_url": "https://api.github.com/users/octocat/orgs",
	        "repos_url": "https://api.github.com/users/octocat/repos",
	        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
	        "received_events_url": "https://api.github.com/users/octocat/received_events",
	        "type": "User",
	        "site_admin": false
	      },
	      "open_issues": 4,
	      "closed_issues": 8,
	      "created_at": "2011-04-10T20:09:31Z",
	      "updated_at": "2014-03-03T18:58:10Z",
	      "closed_at": "2013-02-12T13:22:01Z",
	      "due_on": null
	    },
	    "comments": 0,
	    "pull_request": {
	      "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
	      "html_url": "https://github.com/octocat/Hello-World/pull/1347",
	      "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
	      "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch"
	    },
	    "closed_at": null,
	    "created_at": "2011-04-22T13:33:48Z",
	    "updated_at": "2011-04-22T13:33:48Z"
	  }
	]


Commits
-------

[https://developer.github.com/v3/git/commits/](https://developer.github.com/v3/issues/)

	{
	  "sha": "7638417db6d59f3c431d3e1f261cc637155684cd",
	  "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/7638417db6d59f3c431d3e1f261cc637155684cd",
	  "author": {
	    "date": "2010-04-10T14:10:01-07:00",
	    "name": "Scott Chacon",
	    "email": "schacon@gmail.com"
	  },
	  "committer": {
	    "date": "2010-04-10T14:10:01-07:00",
	    "name": "Scott Chacon",
	    "email": "schacon@gmail.com"
	  },
	  "message": "added readme, because im a good github citizen\n",
	  "tree": {
	    "url": "https://api.github.com/repos/octocat/Hello-World/git/trees/691272480426f78a0138979dd3ce63b77f706feb",
	    "sha": "691272480426f78a0138979dd3ce63b77f706feb"
	  },
	  "parents": [
	    {
	      "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/1acc419d4d6a9ce985db7be48c6349a0475975b5",
	      "sha": "1acc419d4d6a9ce985db7be48c6349a0475975b5"
	    }
	  ]
	}




