package POOF::Example::Key;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my $args = $obj->SUPER::_init( @_ );
    
    $obj->{'uniquePattern'} = '1234';
    
    return $args;    
}

#-------------------------------------------------------------------------------
# properties

sub uniquePattern : Property Private
{
    {
        'type' => 'string',
        'default' => '',
    }
}

#-------------------------------------------------------------------------------
# methods

sub UniquePattern : Method Public
{
    my $obj = shift;
    return $obj->{'uniquePattern'};
}

1;
