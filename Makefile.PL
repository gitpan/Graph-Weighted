use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Graph::Weighted',
    'VERSION_FROM' => 'Weighted.pm',
    'PREREQ_PM'    => {
        'Carp' => 0,
        'Test::More' => 0,
        'Graph' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'Weighted.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
