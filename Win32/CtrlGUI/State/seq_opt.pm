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
use Win32::CtrlGUI::State::seq;

use strict;

package Win32::CtrlGUI::State::seq_opt;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State::seq');

$VERSION='0.10';

sub is_recognized {
  my $self = shift;

  my $state = $self->state;
  if ($state eq 'init' or $state eq 'srch') {
    if ($state eq 'init') {
      $self->{state} = 'srch';
    }
    return $self->_is_recognized;
  } else {
    return 1;
  }
}

sub _is_recognized {
  my $self = shift;

  foreach my $i (0..$#{$self->{states}}) {
    if ($self->{states}->[$i]->is_recognized) {
      $self->{state} = 'rcog';
      $self->{states} = [ @{$self->{states}}[$i..$#{$self->{states}}] ];
      return 1;
    }
  }
  return 0;
}

sub do_action_step {
  my $self = shift;

  $self->state eq 'rcog' and $self->{state} = 'actn';
  $self->state eq 'actn' or return 0;

  while (1) {
    my $current_state = $self->current_state;
    unless ($current_state) {
      $self->{state} = 'done';
      return 0;
    }

    if ($self->_is_recognized) {
      my $current_state = $self->current_state;

      $current_state->do_action_step;

      if ($current_state->state =~ /^done|fail$/) {
        shift @{$self->{states}};
      } else {
        return 1;
      }
    }
  }
  return 0;
}

sub wait_action {
  my $self = shift;

  my $state = $self->state;
  $state eq 'actn' or $state eq 'rcog' or return 0;

  while ($self->do_action_step) {
    Win32::Sleep($self->wait_intvl);
  }
  return 1;
}

sub do_state {
  my $self = shift;

  $self->wait_recognized;
  $self->wait_action;
}

1;
