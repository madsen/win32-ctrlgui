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

$VERSION='0.11';

sub _new {
  my $class = shift;

  my $self = $class->SUPER::_new(@_);

  if (ref ($self->{criteria}) eq 'ARRAY') {
    $self->{criteria} = Win32::CtrlGUI::Criteria->new(@{$self->{criteria}});
  }

  return $self;
}

sub is_recognized {
  my $self = shift;

  if ($self->state =~ /^init|srch$/) {
    if ($self->state eq 'init') {
      $self->{state} = 'srch';
      $self->{timeout} and $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
    }
    my $rcog = $self->{criteria}->is_recognized;
    if ($rcog) {
      ref $rcog and $self->{rcog_win} = $rcog;
      $self->{state} = 'rcog';
      $self->{rcog_time} = Win32::GetTickCount();
      $self->debug_print(1, "Criteria $self->{criteria} met.");
    } else {
      if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
        $self->debug_print(1, "Criteria $self->{criteria} was timed out.");
        $self->{state} = 'fail';
        return 1;
      }
      return 0;
    }
  } else {
    return 1;
  }
}

sub do_action_step {
  my $self = shift;

  if ($self->state eq 'rcog') {
    $self->{state} = 'actn';
    my $wait_time = $self->{rcog_time}/1000 + $self->action_delay - Win32::GetTickCount()/1000;
    $wait_time > 0 and $self->debug_print(1, "Looping for $wait_time seconds before executing action.");
  }
  $self->state eq 'actn' or return;

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
  }
}

sub wait_action {
  my $self = shift;

  $self->state =~ /^actn|rcog$/ or return 0;

  my $wait_time = $self->{rcog_time} + $self->action_delay * 1000 - Win32::GetTickCount();
  if ($wait_time > 0) {
    $self->debug_print(1, "Sleeping for ".($wait_time/1000)." seconds before executing action.");
    Win32::Sleep($wait_time);
  }

  return $self->SUPER::wait_action();
}

sub reset {
  my $self = shift;

  $self->SUPER::reset;

  delete($self->{rcog_time});
  delete($self->{rcog_win});
  delete($self->{end_time});
}

1;
