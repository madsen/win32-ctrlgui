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

package Win32::CtrlGUI::State::seq;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.10';

sub _new {
  my $class = shift;

  my $self = {
    states => [],
    state => 'init',
  };

  foreach my $i (@_) {
    if (ref $i eq 'ARRAY') {
      push(@{$self->{states}}, Win32::CtrlGUI::State->new(@{$i}));
    } elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::State')) {
      push(@{$self->{states}}, $i);
    } else {
      die "seq demands ARRAY refs or Win32::CtrlGUI::State objects.\n";
    }
  }

  bless $self, $class;
}

sub current_state {
  my $self = shift;
  return $self->{states}->[0];
}

sub is_recognized {
  my $self = shift;

  my $state = $self->state;
  if ($state eq 'init' or $state eq 'srch') {
    if ($state eq 'init') {
      $self->{state} = 'srch';
    }
    if ($self->current_state->is_recognized) {
      $self->{state} = 'rcog';
    } else {
      return 0;
    }
  }
  return 1;
}

sub wait_recognized {
  my $self = shift;

  until ($self->is_recognized) {
    Win32::Sleep($self->wait_intvl);
  }
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

    if ($current_state->state =~ /^init|srch$/) {
      $current_state->is_recognized;
    }

    if ($current_state->state =~ /^rcog|actn$/) {
      $current_state->do_action_step;
    }

    if ($current_state->state =~ /^done|fail$/) {
      shift @{$self->{states}};
    } else {
      return 1;
    }
  }
}

sub wait_action {
  my $self = shift;

  my $state = $self->state;
  $state eq 'actn' or $state eq 'rcog' or return 0;

  while (my $current_state = shift @{$self->{states}}) {
    $current_state->do_state;
  }

  return 1;
}

sub do_state {
  my $self = shift;

  $self->wait_recognized;
  $self->wait_action;
}

1;
