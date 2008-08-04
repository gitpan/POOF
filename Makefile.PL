use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POOF',
    VERSION_FROM      => 'lib/POOF.pm', # finds $VERSION
    PREREQ_PM         =>
    {
        Attribute::Handlers => 0,
        Scalar::Util => 0,
        Data::Dumper => 0,
        Carp => 0,
        Digest::MD5 => 0,
        Class::ISA => 0,
        Test::More => 0,
    },
    (
        $] >= 5.005
            ? ( ABSTRACT_FROM  => 'lib/POOF.pm', # retrieve abstract from module
                AUTHOR         => 'Benny Millares <benny@millaresdesign.com>' )
            : ( )
    ),
);

