What is it?
===========

A little script to quickly add vhosts to your local apache configuration for development purposes.

Given a name like "example.local" and a path to the files for the site, it will make the site appear at http://example.local.

See example of usage below.

Usage
=====

1. Create folder for your domain in your *Sites* dir (`$HOME/Sites`), for instance: *example* (for real, it doesn't matter how you'll name it)

		mkdir $HOME/Sites/example

2. Next open Terminal and do like this to add `example.local` (it's what you will type in your browser):

		vhostman add example.local $HOME/Sites/example

That’s it! You can view your site in browser: http://example.local.

Installation
============

Make a directory to contain all the generated vhost config files:

	sudo mkdir /etc/apache2/extra/vhosts

Add this line to your /etc/apache2/httpd.conf file:

```apache
Include /private/etc/apache2/extra/vhosts/*.conf
```

Place the `vhostman.rb` to somewhere, for instance, somewhere in your home dir and add alias for this into your `.bash_profile`, like:

	alias vhostman="$HOME/somewhere/vhostman.rb"

Ensure it's executable:

	chmod 0777 $HOME/somewhere/vhostman.rb

That's it, now you can start to use it.
