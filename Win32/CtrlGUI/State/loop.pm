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

package Win32::CtrlGUI::State::loop;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State::multi');

$VERSION='0.11';

sub _new {
  my $class = shift;

  my $self = $class->SUPER::_new(@_);

  if (scalar(@{$self->{states}}) < 1 || scalar(@{$self->{states}}) > 2) {
    die "$class demands a body state and, optionally, an exit_state.";
  }

  if (scalar(@{$self->{states}}) != 2 && !$self->{timeout}) {
    die "$class demands either an exit_state or a timeout.\n";
  }

  $self->{body_state} = $self->{states}->[0];
  scalar(@{$self->{states}}) == 2 and $self->{exit_state} = $self->{states}->[1];

  return $self;
}

sub _options {
  return qw(timeout body_req);
}

sub current_state {
  my $self = shift;
  return $self->{$self->{active_state}};
}

sub _is_recognized {
  my $self = shift;

  $self->{active_state} and return 1;

  if (!$self->{end_time} && $self->{timeout}) {
    $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
  }

  if ($self->{body_state}->is_recognized) {
    $self->{state} = 'rcog';
    $self->{active_state} = 'body_state';
    $self->{body_req} = 0;
    return 1;
  }

  if (!$self->{body_req} && $self->{exit_state}->is_recognized) {
    $self->{state} = 'rcog';
    $self->{active_state} = 'exit_state';
    return 1;
  }

  if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
    $self->{state} = 'done';
    $self->debug_print(1, "Loop exiting due to timing out after $self->{timeout} seconds.");
    return 1;
  }
  return 0;
}

sub do_action_step {
  my $self = shift;

  $self->state eq 'rcog' and $self->{state} = 'actn';
  $self->state eq 'actn' or return 0;

  while (1) {
    if ($self->_is_recognized) {
      $self->{state} eq 'done' and last;

      $self->current_state->do_action_step;

      if ($self->current_state->state =~ /^done|fail$/) {
        if ($self->{active_state} eq 'body_state') {
          $self->{body_state}->reset;
          $self->{active_state} = undef;
          $self->{end_time} = 0;
          next;
        } elsif ($self->{active_state} eq 'exit_state') {
          $self->{state} = 'done';
        }
      }
    }

    last;
  }
}

1;
