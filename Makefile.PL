use ExtUtils::MakeMaker;
require 5.008;

WriteMakefile
  (
   NAME	           => "types",
   VERSION_FROM    => "lib/types.pm",
   PREREQ_PM => {'B::Generate' => '1.34',
                 'optimize'    => '0.02',
                 'Hook::Scope' => '0.04',
                 'optimizer'   => '0.05',
                 'B::Utils'    => '0',
                },
   ($] >= 5.005 ?
    ('AUTHOR' => 'Artur Bergman <abergman@cpan.org>, Reini Urban <rurban@cpan.org>',
     'ABSTRACT' => 'type declaration and checking') : ()),
   ($ExtUtils::MakeMaker::VERSION gt '6.30' ?
    ('LICENSE'                => 'perl', ) : ()),
   (($ExtUtils::MakeMaker::VERSION gt '6.31' and $ExtUtils::MakeMaker::VERSION lt '6.46') ?
    ('EXTRA_META'  => "recommends:\n" .
     "    B::C:                      1.30\n"
    ) : ()),
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  => {"recommends" => {
                       "B::C" => "1.30"}}
    ) : ()),
  );
