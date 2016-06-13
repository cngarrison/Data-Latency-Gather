#!perl -wT

use strict;
use warnings;

use Test::More tests => 1;

use_ok( 'Data::Latency::Gather' );

diag( 'Testing Data::Latency::Gather '
            . $Data::Latency::Gather::VERSION );
