#use strict;
use Module::Build;


my $build = Module::Build->new
    (
     module_name => 'types',
     license => 'perl',
     dynamic_config => 1,
     requires =>
     {
      'perl'        => '5.008',
      'optimize'    => '0.03',
      'B::Generate' => '1.36',
      'optimizer'   => '0.05',
      'B::Hooks::EndOfScope' => '0.09',
      'B::Utils'    => '0',
     }
     );
$build->create_build_script();
