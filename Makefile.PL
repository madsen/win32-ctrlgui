use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Win32::CtrlGUI',
  'VERSION_FROM' => 'Win32/CtrlGUI.pm', # finds $VERSION
  'PM' => {
    'Win32/CtrlGUI.pm' =>                    '$(INST_LIBDIR)/CtrlGUI.pm',
    'Win32/CtrlGUI/Criteria.pm' =>           '$(INST_LIBDIR)/CtrlGUI/Criteria.pm',
    'Win32/CtrlGUI/State.pm' =>              '$(INST_LIBDIR)/CtrlGUI/State.pm',
    'Win32/CtrlGUI/Window.pm' =>             '$(INST_LIBDIR)/CtrlGUI/Window.pm',
    'Win32/CtrlGUI/Criteria/arbitrary.pm' => '$(INST_LIBDIR)/CtrlGUI/Criteria/arbitrary.pm',
    'Win32/CtrlGUI/Criteria/neg.pm' =>       '$(INST_LIBDIR)/CtrlGUI/Criteria/neg.pm',
    'Win32/CtrlGUI/Criteria/pos.pm' =>       '$(INST_LIBDIR)/CtrlGUI/Criteria/pos.pm',
    'Win32/CtrlGUI/State/atom.pm' =>         '$(INST_LIBDIR)/CtrlGUI/State/atom.pm',
    'Win32/CtrlGUI/State/dialog.pm' =>       '$(INST_LIBDIR)/CtrlGUI/State/dialog.pm',
    'Win32/CtrlGUI/State/fork.pm' =>         '$(INST_LIBDIR)/CtrlGUI/State/fork.pm',
    'Win32/CtrlGUI/State/loop.pm' =>         '$(INST_LIBDIR)/CtrlGUI/State/loop.pm',
    'Win32/CtrlGUI/State/seq.pm' =>          '$(INST_LIBDIR)/CtrlGUI/State/seq.pm',
    'Win32/CtrlGUI/State/seq_opt.pm' =>      '$(INST_LIBDIR)/CtrlGUI/State/seq_opt.pm',
  },
  'AUTHOR' => 'Toby Everett',
  'ABSTRACT' => 'Object-oriented wrapper for Win32::Setupsup',
);



