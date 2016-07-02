#!/usr/bin/env perl

## check-latency.pl - Description of module
# Created by: Charlie Garrison
#       Orig: 13/06/2016
#-----------------------------------------------------------------------
#    Purpose: Check latency to specific list of hosts and submit 
#             results to data server.
#-----------------------------------------------------------------------

use v5.16;

our $VERSION = 0.1;

use FindBin;
use lib "$FindBin::Bin/lib";

use Data::Latency::Gather::Script;


## Initialize and script/app
my $ret = Data::Latency::Gather::Script->new_with_options()->run;

exit($ret);


1;

