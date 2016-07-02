package Data::Latency::Gather::Script;

use v5.16;
use Moose;

with 'MooseX::Getopt::Usage',
     'MooseX::Getopt::Usage::Role::Man';

# use Moose::Util::TypeConstraints;
# use MooseX::Types::Path::Tiny qw/File Dir Path/;    # Path Paths AbsPath
# MooseX::Getopt::OptionTypeMap->add_option_type_to_map( File, '=s' );
# MooseX::Getopt::OptionTypeMap->add_option_type_to_map( Dir,  '=s' );

use Data::Printer;
use Log::Dispatchouli;
# use Log::Contextual::WarnLogger::Fancy;
use Try::Tiny;

use Data::Latency::Gather;

has 'verbose' => (
	traits => ['Getopt', 'Bool'], ##, 'ENV' # causes `default` as well as our own `builder`
	is     => 'ro',
	isa    => 'Bool',
	cmd_aliases   => [qw/ v /],
	documentation => qq{Make me chatty}
);

has 'logger' => (
	traits  => ['NoGetopt'],          # do not attempt to capture this param
	is      => 'ro',
	isa     => 'Log::Dispatchouli',
# 	isa     => 'Log::Contextual::WarnLogger::Fancy',
	lazy    => 1,
	builder => '_build_logger',
);

sub _build_logger {
	my $self = shift;
	return Log::Dispatchouli->new( {
			ident     => 'DomainSpamRating',
			to_stdout => 1, ##to_stderr => 1,
			debug     => $self->verbose,
		}
	);
# 	return Log::Contextual::WarnLogger::Fancy->new(
# 		env_prefix       => 'Data::Latency::Gather::Script',   # control this level only
# 		group_env_prefix => 'Data::Latency::Gather',           # shared control for all components
# 		default_upto     => 'info',
# 		levels => [ ($self->verbose ? 'debug' : ()), qw( info notice warning error critical alert emergency) ],
# 	);
} ## end sub _build_logger


sub run {
	my ($self) = @_;
	my ( $argv, @extra_argv ) = @{ $self->extra_argv };

	$self->logger->log_debug('Running script');
# 	$self->logger->debug('Running script');

# 	$self->init_script;

	foreach my $cmd ( $argv, @extra_argv ) {
		next unless $cmd;
		if ( $self->can("cmd_${cmd}") ) {
			try {
				$self->${ \"cmd_${cmd}" };    # "} bbedit fix
			}
			catch {
				$self->logger->log_fatal( ["ERROR running command '%s': %s", $cmd, $_] );
# 				$self->logger->fatal( ["ERROR running command '%s': %s", $cmd, $_] );
			};
		} else {
			$self->logger->log_fatal("No such command ${cmd}");
# 			$self->logger->fatal("No such command ${cmd}");
		}
	} ## end foreach my $cmd ( $argv, @extra_argv )

	return 0;                                 # exit code for script

} ## end sub run


sub cmd_print_data {
	my $self = shift;

	$self->logger->info("\n---------------------\nResults Data\n---------------------");

	Data::Latency::Gather->do_ping;

	return;
} ## end sub cmd_print_results_data

# sub run_if_script {
#   my $class = shift;
#   caller(1) ? $class : $class->new_with_options(@_)->run;
# }


__PACKAGE__->meta->make_immutable;
# __PACKAGE__->run_if_script;


1;



__END__

=encoding utf8

=head1 NAME

check-latency.pl - Gather latency data for host(s)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    ./check-latency.pl print_data

    ./check-latency.pl print_data -v

    ./check-latency.pl --man
    
    docker-machine create --driver amazonec2 --amazonec2-region ap-southeast-2 aws-ddg
    eval $(docker-machine env aws-ddg)
    docker build -t data-latency-gather .
    docker run -it --rm --name check-latency data-latency-gather


=head1 DESCRIPTION

Gather ping/latency statistics for supplied hosts. The script requires a
command in order to do anything useful. Look under FUNCTIONS for list of
available commands. Don't include `cmd_` when passing commands to the
script.

=head1 FUNCTIONS - SCRIPT COMMANDS

=head2 cmd_print_data

Run generic ping command.


=head1 AUTHOR

Charlie Garrison L<garrison@zeta.org.au>

=cut



