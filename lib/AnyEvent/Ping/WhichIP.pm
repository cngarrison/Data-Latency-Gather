package AnyEvent::Ping::WhichIP;

 
use strict;
use warnings;

use parent qw(AnyEvent::Ping);

use IO::Socket::INET qw/sockaddr_in inet_aton inet_ntoa unpack_sockaddr_in/;
use Time::HiRes 'time';


sub ping {
    my ($self, $host, $times, $cb) = @_;
 
    my $socket = $self->{_socket};
 
    my $ip = inet_aton($host);
 
    my $request = {
        host        => $host,
        times       => $times,
        results     => [],
        cb          => $cb,
		# include IP address in result
        ip          => inet_ntoa($ip),
        identifier  => int(rand 0x10000),
        destination => scalar sockaddr_in(0, $ip),
    };
 
    push @{$self->{_tasks}}, $request;
 
    push @{$self->{_tasks_out}}, $request;
 
    $self->_add_write_poll;
 
    return $self;
}


sub _store_result {
    my ($self, $request, $result) = @_;
 
    my $results = $request->{results};
 
    # Clear request specific data
    delete $self->{_timers}->{$request};
 
 	# include IP address in result
    push @$results, [$result, time - $request->{start}, $request->{ip}];
 
    if (@$results == $request->{times} || $result eq 'ERROR') {
 
        # Cleanup
        my $tasks = $self->{_tasks};
        for my $i (0 .. scalar @$tasks) {
            if ($tasks->[$i] == $request) {
                splice @$tasks, $i, 1;
                last;
            }
        }
 
        # Testing done
        $request->{cb}->($results);
 
        undef $request;
    }
 
    # Perform another check
    else {
 
        # Setup interval timer before next request
        $self->{_timers}{$request} = AnyEvent->timer(
            after => $self->interval,
            cb    => sub {
                delete $self->{_timers}{$request};
                push @{$self->{_tasks_out}}, $request;
                $self->_add_write_poll;
            }
        );
    }
}


1;
