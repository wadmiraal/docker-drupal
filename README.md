Drupal development with Docker
==============================

Quick and easy to use Docker container for your local Drupal development. It contains a LAMP stack and an SSH server, along with an up to date version of Drush.

Installation
------------

### Github

Clone the repository locally. Build the `Dockerfile` by `cd`-ing into the folder and calling:

	docker build -t yourname/drupal .

### Docker repository

Get the image:

	docker pull wadmiraal/drupal

Running it
----------

For optimum usage, map some local directories to the container for easier development. I personally create at least a `modules/` directory which will contain my custom modules. You can do the same for your themes.

The container exposes its `80` port (Apache), its `3306` port (MySQL) and its `22` port (SSH). Make good use of this by forwarding your local ports. You should at least forward to port `80` (using `-p local_port:80`, like `-p 8080:80`). A good idea is to also forward port `22`, so you can use Drush from your local machine using aliases, and directly execute commands inside the container, without attaching to it.

Here's an example just running the container and forwarding `http://localhost:8080` to the container:

	docker run -i -d -p 8080:80 -t wadmiraal/docker

### Writing code locally

Here's an example running the container, forwarding port `8080` like before, but also mounting Drupal's `sites/all/modules/custom/` folder to my local `modules/` folder. I can then start writing code on my local machine, directly in this folder, and it will be available inside the container:

	docker run -i -d -p 8080:80 -v `pwd`/modules:/var/www/sites/all/modules/custom -t wadmiraal/drupal

### Using Drush

Using Drush aliases, I can directly execute Drush commands locally and have them be executed inside the container. Create a new aliases file in your home directory and add the following:

	# ~/.drush/docker.aliases.drushrc.php
	<?php
	$aliases['wadmiraal_drupal'] = array(
	  'root' => '/var/www',
	  'remote-user' => 'root',
	  'remote-host' => 'localhost',
	  'ssh-options' => '-p 8022', // Or any other port you specify when running the container
	);

Next, copy the content of your local SSH public key (usually `~/.ssh/id_rsa.pub`; read [here](https://help.github.com/articles/generating-ssh-keys/) on how to generate one if you don't have it). SSH into the running container:

	# If you forwarded another port than 8022, change accordingly.
	# Password is "root".
	ssh root@localhost -p 8022

Once you're logged in, add the contents of your `id_rsa.pub` file to `/root/.ssh/authorized_keys`. Exit.

You should now be able to call:

	drush @docker.wadmiraal_drupal cc all

This will clear the cache of your Drupal site. ALl other commands will function as well.

