###########################################################################
# Copyright 2000, 2001 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
##########################################################################
use Win32::CtrlGUI;

use strict;

package Win32::CtrlGUI::State::dialog;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.10';

sub _new {
  my $class = shift;
  my %data = @_;

  $data{criteria}->[0] ne 'neg' or die "Dialogs can't have negative criteria.\n";

  my $pos_atom = Win32::CtrlGUI::State->new('atom',
      criteria => $data{criteria}, action => $data{action});

  my $neg_atom = Win32::CtrlGUI::State->new('atom',
      criteria => [neg => sub {$_ == $pos_atom->{rcog_win}}], action_delay => 0);

  if ($data{cnfm_criteria}) {
    my $cnfm_atom = Win32::CtrlGUI::State->new('atom',
        criteria => $data{cnfm_criteria}, action => $data{cnfm_action});
    return Win32::CtrlGUI::State->new('seq', $pos_atom, ['seq_opt', $cnfm_atom, $neg_atom]);
  } else {
    return Win32::CtrlGUI::State->new('seq', $pos_atom, $neg_atom);
  }
}

1;
