package POOF::MockObj;

use strict;
use warnings;

use base qw(POOF);

#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub Mock : Property Public
{
    {
        'type' => 'enum',
        'options' => [qw(one two three four)],
        'default' => 'five',
    }
}

#-------------------------------------------------------------------------------
# methods

1;