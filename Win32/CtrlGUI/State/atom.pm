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

use strict;

package Win32::CtrlGUI::State::atom;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.10';

sub is_recognized {
  my $self = shift;

  my $state = $self->state;
  if ($state eq 'init' or $state eq 'srch') {
    if ($state eq 'init') {
      $self->{state} = 'srch';
      if ($self->{timeout}) {
        $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
      }
    }
    my $rcog = $self->{criteria}->is_recognized;
    if ($rcog) {
      ref $rcog and $self->{rcog_win} = $rcog;
      $self->{state} = 'rcog';
      $self->{rcog_time} = Win32::GetTickCount();
      $self->debug_print(1, "Criteria $self->{criteria} met.");
    } else {
      if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
        $self->{state} = 'fail';
        return 1;
      }
      return 0;
    }
  } else {
    return 1;
  }
}

sub wait_recognized {
  my $self = shift;

  $self->{state} ne 'rcog' and $self->debug_print(1, "Waiting for criteria $self->{criteria}.");
  until ($self->is_recognized) {
    Win32::Sleep($self->wait_intvl);
  }
}

sub do_action_step {
  my $self = shift;

  if ($self->state eq 'rcog') {
    $self->{state} = 'actn';
    my $wait_time = $self->{rcog_time} + $self->action_delay * 1000 -Win32::GetTickCount();
    $wait_time > 0 and $self->debug_print(1, "Looping for ".($wait_time/1000)." seconds before executing action.");
  }
  $self->state eq 'actn' or return 0;

  if ($self->{rcog_time} + $self->action_delay * 1000 <= Win32::GetTickCount()) {
    if (ref $self->{action} eq 'CODE') {
      $self->debug_print(1, "Executing code action.");
      $self->{action}->($self);
    } elsif ($self->{action}) {
      $self->debug_print(1, "Sending keys '$self->{action}'.");
      $self->{rcog_win}->send_keys($self->{action});
    }
    $self->debug_print(1, "");
    $self->{state} = 'done';
    return 0;
  }
  return 1;
}

sub wait_action {
  my $self = shift;

  my $state = $self->state;
  $state eq 'actn' or $state eq 'rcog' or return 0;
  my $wait_time = $self->{rcog_time} + $self->action_delay * 1000 - Win32::GetTickCount();
  if ($wait_time > 0) {
    $self->debug_print(1, "Sleeping for ".($wait_time/1000)." seconds before executing action.");
    Win32::Sleep($wait_time);
  }
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
