package Data::Latency::Gather::Script::Roles::DBI;

use v5.16;
use Moo::Role;
use strictures 2;
# use Types::Standard qw(Bool ArrayRef Str Int);

use Try::Tiny;
use Data::Printer;

use Data::Latency::Gather::DBI;

# VERSION: generated by DZP::OurPkgVersion

has 'dbi' => (
	is      => 'ro',
	isa     => sub {
	  die "$_[0] is not a Data::Latency::Gather::DBI!" unless $_[0]->isa('Data::Latency::Gather::DBI')
	},
	lazy    => 1,
	builder => '_build_dbi',
);

sub _build_dbi {
	my $self = shift;
	
	my $dbi = try {
		Data::Latency::Gather::DBI->new;
	} catch {
		warn sprintf("error: failed to connect to db: %s\n", $_);
		return;
	};
	$self->logger->debug("DBI:\n".np($dbi));
	return $dbi;

} ## end sub _build_dbi

has "dbh" => (
	is  => 'rw',
	isa     => sub {
	  die "$_[0] is not a DBI::db!" unless $_[0]->isa('DBI::db')
	},
);


before 'run' => sub {
	my $self = shift;

	$self->dbh($self->dbi->dbh);
	$self->logger->debug("DBH:\n".np($self->dbh));
	#return; # ignored
};

after 'run' => sub {
	my $self = shift;
# 	$self->dbh->commit;
	$self->dbi->dbh->disconnect;
	#return; # ignored
};


1;