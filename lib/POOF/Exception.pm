package POOF::Exception;

use base qw(POOF);
use strict;
use warnings;
use Carp qw(confess croak);

use Data::Dumper;

#-------------------------------------------------------------------------------
# Properties: Core

sub code : Property Public Virtual
{
    {
        'type' => 'integer',
        'min' => 1,
        'groups' => [qw(Init)],
    }
}

sub description : Property Public Virtual
{
    {
        'type' => 'string',
        'regex' => qr/\b[^ ]+\b/,
        'groups' => [qw(Init)],
    }
}

sub value : Property Public Virtual
{
    {
        'type' => 'scalar',
        'default' => undef,
        'null' => 1,
        'groups' => [qw(Init)],
    }
}

#-------------------------------------------------------------------------------
# Methods: initialization

sub _init
{
    my $obj = shift;
    my %args = $obj->SUPER::_init( @_ );

    # poplulate known form properties passed to the constructor if they are defined
    @{$obj}{ $obj->Group('Init') } = @args{ $obj->Group('Init') };

    return (%args);
}


1;

__END__