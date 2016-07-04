# NAME

Data::Latency::Gather - Gather latency data for host(s)

# DESCRIPTION

DLG is used to measure the latency between hosts (_testers_ and
_servers_). There are two components (_collector_ and _testers_) used to
generate and gather the latency data. Docker (`docker-machine`) is used
to ease deployment of testers. Currently only AWS (EC2 containers) have
been tested, but any cloud provider with driver for `docker-machine`
should work just as easily. Latency is tested (from _tester_) with ICMP
pings using `AnyEvent::Ping`. Latency data is sent via HTTP POST to the
_collector_, which stores the results in a Postgres database. Any host
which responds to ICMP pings can be used as a _server_.

# INSTALLATION

Use `docker-machine` to deploy _testers_. This assumes you have already
[configured docker-machine with your AWS account
credentials](http://docs.docker.com.s3-website-us-east-1.amazonaws.com/
engine/installation/cloud/cloud-ex-aws/). 

	docker-machine create --driver amazonec2 --amazonec2-region ap-southeast-2 aws-dlg2
	eval $(docker-machine env aws-dlg2)
	docker build -f Dockerfile-tester -t data-latency-gather .
	docker run -it --rm --name check-latency data-latency-gather

After the _tester_ is no longer needed, it can be removed using `docker-machine`.

	docker-machine rm aws-dlg2

The `dlg.pl` config file needs correct values for local installation. 

The _collector_ can be run on any public host. It needs a Postgres
database and Perl modules for running a simple `plack` (PSGI) webapp.
Create the database using `create-db.sql`.

	createdb dlg
	psql -f share/sql/create-db.sql -d dlg

Run the webapp directly from the project directory.

	plackup --port 9090 ./dlg.psgi

# TODO

* Pass arguments via Docker to _tester_ script to:
  * identify itself to collector,
  * check specific host(s) or via hostname DNS lookup,
  * run once or XX times with XX internval.
* Basic Auth for POSTs to webapp _collector_.
* Report queries to show slow regions.
* Create `docker-compose` config to deploy both Postgres database and webapp _collector_.  [NICE TO HAVE]
* Automatic _tester_ deployment based on config in `testers` table. [NICE TO HAVE]

# AUTHOR

Charlie Garrison &lt;garrison@zeta.org.au>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
