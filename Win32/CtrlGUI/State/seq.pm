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

package Win32::CtrlGUI::State::seq;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State::multi');

$VERSION='0.11';

sub _is_recognized {
  my $self = shift;

  if ($self->current_state->is_recognized) {
    $self->state eq 'srch' and $self->{state} = 'rcog';
    return 1;
  }
  return 0;
}

sub wait_action {
  my $self = shift;

  $self->state =~ /^actn|rcog$/ or return 0;

  while (my $current_state = shift @{$self->{states}}) {
    $current_state->do_state;
  }
  return 1;
}

1;
