#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Graph::Weighted',
    VERSION_FROM => 'lib/Graph/Weighted.pm',
    PREREQ_PM => {},
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Graph/Weighted.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
