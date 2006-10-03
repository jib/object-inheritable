use Test::More 'no_plan';
use strict;
use Data::Dumper;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib' };

my $Class      = 'Object::Inheritable';

use_ok( $Class );
