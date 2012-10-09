use strict;

BEGIN {
  die "The Win32::CtrlGUI module works only on Windows NT\nOS unsupported\n"
      unless eval { Win32::IsWinNT() };
}

use Module::Build 0.25;

my $class = Module::Build->subclass(
  class => 'Module::Build::Win32CtrlGUI',
  code => q{
    sub ppm_name {
      my $self = shift;
      mkdir('MSWin32-x86-multi-thread');
      return 'MSWin32-x86-multi-thread/' . $self->dist_dir;
    }

    sub ACTION_ppmzip {
      my $self = shift;

      $self->depends_on('ppmdist');
      my $ppmzip = $self->dist_dir().'.ppm.zip';
      my $ppm_name = $self->ppm_name();
      unlink($ppmzip);
      system("zip -9 $ppmzip *.ppd $ppm_name.tar.gz");
    }

  },
);

my $build = $class->new(
  module_name  => 'Win32::CtrlGUI',
  dist_name    => 'Win32-CtrlGUI',
  dist_version => ##{ "'$version'" ##},
##{ $plugin->get_prereqs ##}
);

$build->create_build_script;
