use ExtUtils::MakeMaker;
require 5.008;

WriteMakefile
  (
   NAME	           => "types",
   VERSION_FROM    => "lib/types.pm",
   PREREQ_PM => {'B::Generate' => '1.36',
                 'optimize'    => '0.03',
		 'B::Hooks::EndOfScope' => '0.09',
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
