package POOF::Example::SyntaxError;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub SomeProperty : Property Public
{
    {
        'type' => 'integer',
        'default' => 0,
    }
}

#-------------------------------------------------------------------------------
# methods

sub SomeMethod : Method Public
{
    my $obj = shift;
    asdf
}


1;