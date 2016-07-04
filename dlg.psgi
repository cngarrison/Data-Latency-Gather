use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
# use Plack::Middleware::Debug;

use Data::Printer;
use Try::Tiny;
use DateTime::Format::HTTP;

use FindBin;
use lib "$FindBin::Bin/lib";

use Data::Latency::Gather::DBI;

my $app = sub {
	my $env = shift;    # PSGI env

	my $req = Plack::Request->new($env);

	my $dbi = try {
		Data::Latency::Gather::DBI->new;
	}
	catch {
		warn sprintf( "error: failed to connect to db: %s\n", $_ );
		my $res = $req->new_response(501);    # new Plack::Response
		$res->content_type('text/plain');
		$res->body("SERVER ERROR");
		$res->finalize;
		return;
	};


	my $path_info = $req->path_info;
	my $params    = $req->parameters;
	my $ip_addr   = $params->{server_contacted};
	my $tester_id = $params->{tester_id} || '54C9C73C-C85C-420F-A1B3-BA10A85A590C'; #just for testing - remove hard-coded tester_id

# 	p($tester_id);
# 	p($ip_addr);

	my $tester = $dbi->get_tester_by_id($tester_id);

	if ( !$tester ) {
		my $res = $req->new_response(501);    # new Plack::Response
		$res->content_type('text/plain');
		$res->body("SERVER ERROR: Invalid tester: $tester_id");
		$res->finalize;
		return;
	}

	my $server = $dbi->get_server($ip_addr);
	$server = $dbi->add_server($ip_addr, $params->{server_requested}) unless $server;

	my $p_result = $dbi->add_ping_result(
		tester_id        => $tester_id,
		server_requested => $params->{server_requested},
		server_contacted => $ip_addr,
		(
			$params->{ping_timestamp}
			? ( ping_timestamp => DateTime::Format::HTTP->parse_datetime( $params->{ping_timestamp} ) )
			: ()
		),
		ping_count => $params->{ping_count} || 0,
		ping_nack  => $params->{ping_nack}  || 0,
		ping_time  => $params->{ping_time}  || 0,
		raw        => $params->{raw}        || '',
	);

	$dbi->dbh->disconnect;

	my $res = $req->new_response(200);    # new Plack::Response
	$res->content_type('text/plain');
#     $res->body("POSTED: ".np($p_result));
	$res->body("POSTED: ");
	$res->finalize;
};



builder {
	mount '/' => $app;

};
