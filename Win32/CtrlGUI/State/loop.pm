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

$VERSION='0.22';

sub _options {
  return qw(timeout body_req);
}

sub init {
  my $self = shift;

  my $state_count = scalar($self->get_states);

  if ($state_count != 1 && $state_count != 2) {
    die "Win32::CtrlGUI::State::loop demands a body state and, optionally, an exit state.";
  }

  if ($state_count == 1 && !$self->{timeout}) {
    die "Win32::CtrlGUI::State::loop demands either an exit state or a timeout.\n";
  }

  $self->_body->bk_set_status('pcs');
  if ($state_count == 2) {
    $self->_exit->bk_set_status($self->{body_req} ? 'pfs' : 'pcs');
  }
}

sub state_recognized {
  my $self = shift;
  if ($self->_body->bk_status eq 'active') {
  } else {
    $self->_body->bk_set_status('never');
  }
}

sub state_completed {
  my $self = shift;

  if ($self->_body->bk_status eq 'comp') {
    $self->_body->bk_set_status('pcs');
    $self->_body->reset;
    $self->_exit and $self->_exit->bk_set_status('pcs');
    $self->_set_end_time(1);
  } else {
    $self->_exit->bk_set_status('never');
  }
}

sub _body {
  my $self = shift;

  return $self->{states}->[0];
}

sub _exit {
  my $self = shift;

  return $self->{states}->[1];
}

sub _set_end_time {
  my $self = shift;
  my($force) = @_;

  if ((!$self->{end_time} || $force) && $self->{timeout}) {
    $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
  }
}

sub _is_recognized {
  my $self = shift;

  $self->_set_end_time(0);

  my $retval = $self->SUPER::_is_recognized;
  $retval and return $retval;

  if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
    $self->{state} = 'done';
    $self->debug_print(1, "Loop exiting due to timing out after $self->{timeout} seconds.");
    return 1;
  }
  return 0;
}

1;
