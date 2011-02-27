
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
      'optimize'    => '0.02',
      'B::Generate' => '1.34',
      'Hook::Scope' => '0.04',
      'optimizer'   => '0.05',
     }
     );
$build->create_build_script();
