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
use Win32::CtrlGUI::State;
use Win32::CtrlGUI::State::multi;

use strict;

package Win32::CtrlGUI::State::seq_opt;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State::multi');

$VERSION='0.30';

sub init {
  my $self = shift;

  foreach my $i ($self->get_states) {
    $i->bk_set_status('pcs');
  }
}

sub state_recognized {
  my $self = shift;

  foreach my $i ($self->get_states) {
    $i->bk_status eq 'active' and last;
    $i->bk_set_status('never');
  }
}

sub state_completed {
  my $self = shift;

  foreach my $i ($self->get_states) {
    if ($i->bk_status eq 'comp') {
      $i->bk_set_status('never');
      last;
    }
    $i->bk_set_status('never');
  }
}

1;
