package Data::Latency::Gather::DBI;
# ABSTRACT: DBI handling for Data::Latency::Gather

use v5.16;
use Moo;
# use MooX::ClassAttribute;
use Types::Standard qw(Bool ArrayRef HashRef Str Int Num);
use namespace::autoclean;
use Method::Signatures;

use DateTime;
use DateTime::Format::Pg;
use Data::Printer;
use JSON::MaybeXS;
use Try::Tiny;

use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);
use SQL::Abstract;
use Hash::Merge::Simple qw(merge);
# use List::Util qw(uniqstr);

use Data::Latency::Gather;

# VERSION: generated by DZP::OurPkgVersion


has "dbh_conn_details" => (
	is      => "rw",
	isa     => HashRef,
	default => sub { merge(
			{
				'db'     => 'latency',
				'user'   => '',
				'passwd' => '',
				'host'   => '127.0.0.1',
				'port'   => '5432',

			},
			Data::Latency::Gather->config->{dbh_conn_details}
		);
	},
);

has 'dbh' => (
	is      => 'ro',
	isa     => sub {
	  die "$_[0] is not a DBI::db!" unless $_[0]->isa('DBI::db')
	},
	lazy    => 1,
	builder => '_build_dbh',
);

sub _build_dbh {
	my $self = shift;

	my $dbh = try {
		DBI->connect(
			sprintf("DBI:Pg:database=%s;port=%s;host=%s", 
				$self->dbh_conn_details->{'db'},
				$self->dbh_conn_details->{'port'},
				$self->dbh_conn_details->{'host'}
			),
			$self->dbh_conn_details->{'user'}, 
			$self->dbh_conn_details->{'passwd'}, 
			{AutoCommit => 1, PrintError => 0, RaiseError => 1}
		);
	} catch {
		Data::Latency::Gather->logger->log(sprintf("error: failed to connect to db: %s", $_)); #scalar($DBI::errstr), ## RaiseError includes $DBI::errstr
		return; # need to return undef for $dbh
	};
	# foreach (@{ $DBI::EXPORT_TAGS{sql_types} }) {
	#   printf "%s\n", $_;
	# }
	return $dbh;

} ## end sub _build_dbh

has 'sqla' => (
	is      => 'rw',
	isa     => sub {
	  die "$_[0] is not a SQL::Abstract!" unless $_[0]->isa('SQL::Abstract')
	},
	lazy    => 1,
	builder => '_build_sqla',
);

sub _build_sqla {
	my $self = shift;
	
	my $sqla = try {
		SQL::Abstract->new();
# 		SQL::Abstract->new( bindtype => 'columns' );
	} catch {
		Data::Latency::Gather->logger->log(sprintf("error: failed to create sqla: %s", $_)); #scalar($DBI::errstr), ## RaiseError includes $DBI::errstr
		return;
	};
	return $sqla;

} ## end sub _build_sqla

has 'json' => (
	is      => 'rw',
# 	isa     => JSON::MaybeXS::JSON(),
	isa     => sub {
	  die "$_[0] is not a JSON::MaybeXS!" unless $_[0]->isa('JSON::MaybeXS')
	},
	lazy    => 1,
	builder => '_build_json',
);

sub _build_json {
	my $self = shift;
	
	my $json = try {
		JSON->new->space_after->utf8(1);	# make compatible with postgres json stuff
	} catch {
		Data::Latency::Gather->logger->log(sprintf("error: failed to create json obj: %s", $_));
		return;
	};
	return $json;

} ## end sub _build_json


method get_sql(Str $filename!) {

	my $sql_file = Data::Latency::Gather->share_dir('sql',"$filename.sql");
	Data::Latency::Gather->logger->debug(np($sql_file));
	
	my $sql = $sql_file->slurp;
	Data::Latency::Gather->logger->debug(np($sql));

	return $sql;
}

method get_servers() {
	
	my ( $stmt, @bind ) = $self->sqla->select(
		'servers',
		'*', {
# 			id => { -in => [uniqstr map { $_->{server_id} } @$camels] },
		}
	);

	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv      = $sth->execute(@bind);
	my $servers = $sth->fetchall_arrayref;
	$sth->finish;

# 	push @{$server_data}, @{$self->process_server($servers)};
	return $servers;
}

method get_testers() {
	my ( $stmt, @bind ) = $self->sqla->select('testers','*');
	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv      = $sth->execute(@bind);
	my $testers = $sth->fetchall_arrayref;
	$sth->finish;
	return $testers;
}

method get_tester_by_id(Str $id!) {
	my ( $stmt, @bind ) = $self->sqla->select('testers','*',{
		id => $id,
	});
	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv      = $sth->execute(@bind);
	my $tester = $sth->fetchrow_arrayref;
	$sth->finish;
	return $tester;
}
method get_tester(Str $location!) {
	my ( $stmt, @bind ) = $self->sqla->select('testers','*',{
		location => $location,
	});
	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv      = $sth->execute(@bind);
	my $tester = $sth->fetchrow_arrayref;
	$sth->finish;
	return $tester;
}

method add_tester(Str $location!) {
	my %data = (
		name         => $location,
		location     => $location,
		vps_provider => 'aws',
# 		date_entered => \[ "to_date(?,'MM/DD/YYYY')", "03/02/2003" ],
	);

	my ( $stmt, @bind ) = $self->sqla->insert( 'testers', \%data );

	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv = $sth->execute(@bind);
	$sth->finish;
	return $self->get_tester($location);
}

method get_server(Str $ip_addr!) {
	my ( $stmt, @bind ) = $self->sqla->select('servers','*',{
		ip_addr => $ip_addr,
	});
	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv      = $sth->execute(@bind);
	my $server = $sth->fetchrow_arrayref;
	$sth->finish;
	return $server;
}

method add_server( Str $ip_addr!, Str $name!) {  # , Str $location
	my %data = (
		ip_addr  => $ip_addr,
# 		location => $location,
		name     => $name,
	);

	my ( $stmt, @bind ) = $self->sqla->insert( 'servers', \%data );

	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv = $sth->execute(@bind);
	$sth->finish;
	return $self->get_server($ip_addr);
}

method add_ping_result( 
	Str :$tester_id!, 
	Str :$server_requested = '', 
	Str :$server_contacted!,
	Str :$ping_timestamp = DateTime::Format::Pg->format_datetime( DateTime->now ),
	Int :$ping_count = 0,
	Int :$ping_nack = 0,
	Num :$ping_time = 0,
	Str :$raw = '',
) {
	my %data = (
		tester_id        => $tester_id,
		server_requested => $server_requested,
		server_contacted => $server_contacted,
		ping_timestamp   => $ping_timestamp,
		ping_count       => $ping_count,
		ping_nack        => $ping_nack,
		ping_time        => $ping_time,
		raw              => $raw,
	);

	Data::Latency::Gather->logger->debug("data:\n".np(%data));

	my ( $stmt, @bind ) = $self->sqla->insert( 'ping_results', \%data );

	my $sth = $self->dbh->prepare($stmt) or die $self->dbh->errstr;
	my $rv = $sth->execute(@bind);
	$sth->finish;
	return; # $self->get_server($ip_addr);
}


=head1 NAME

Data::Latency::Gather::DBI

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::Latency::Gather::DBI;

    my $foo = Data::Latency::Gather::DBI->new();
    ...

=head1 FUNCTIONS

=head2 function1

=cut



__PACKAGE__->meta->make_immutable; #(inline_constructor => 0);


1;
