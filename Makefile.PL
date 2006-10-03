use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Object::Inheritable',
    VERSION_FROM    => 'lib/Object/Inheritable.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Carp'          => 0,
                            'Test::More'    => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Object Inheritance via Mixins'
);             
