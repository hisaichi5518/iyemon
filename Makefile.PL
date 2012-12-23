use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Iyemon',
    VERSION_FROM  => 'lib/Iyemon.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.13',
        'MongoDB' => '0.45',
        'Config::ENV' => '0',
        'DataTime::Format::HTTP' => '0',
    },
    MIN_PERL_VERSION => '5.008001'
);

