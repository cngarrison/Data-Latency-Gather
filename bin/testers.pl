#!/usr/bin/env perl
# PODNAME: testers.pl

## testers.pl - Description of module
# Created by: Charlie Garrison
#       Orig: 13/06/2016
#-----------------------------------------------------------------------
#    Purpose: Manage testing servers for gathering latency stats. 
#-----------------------------------------------------------------------

use v5.16;

our $VERSION = 0.1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Latency::Gather::Script::Testers;


## Initialize and script/app
my $ret = Data::Latency::Gather::Script::Testers->new_with_options()->run;

exit($ret);


1;

