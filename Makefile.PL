use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Graph::Weighted',
    'VERSION_FROM' => 'lib/Weighted.pm',
    'PREREQ_PM'    => {
        'Carp'       => 0,
        'Test::More' => 0,
        'Graph'      => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Weighted.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
