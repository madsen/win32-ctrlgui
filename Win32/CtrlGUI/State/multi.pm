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

package Win32::CtrlGUI::State::multi;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.11';

sub _new {
  my $class = shift;

  $class eq 'Win32::CtrlGUI::State::multi' and die "$class is an abstract parent class.\n";

  my $self = {
    states => [],
    state => 'init',
  };

  bless $self, $class;

  while (my $i = shift) {
    if (ref $i eq 'ARRAY') {
      push(@{$self->{states}}, Win32::CtrlGUI::State->new(@{$i}));
    } elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::State')) {
      push(@{$self->{states}}, $i);
    } else {
      my $value = shift;
      if (grep {$_ eq $i} $self->_options) {
        $self->{$i} = $value;
      } else {
        ref $value eq 'ARRAY' or
            die "$class demands ARRAY refs, Win32::CtrlGUI::State objects, or class => [] pairs.\n";
        push(@{$self->{states}}, Win32::CtrlGUI::State->new($i, $value));
      }
    }
  }

  $self->{old_states} = [@{$self->{states}}];
  $self->{criteria} = $class;

  return $self;
}

#### _options is a class object that returns a list of known "options" that the class accepts -
#### options are considered to be paired with their value.

sub _options {
  return qw();
}

sub current_state {
  my $self = shift;
  return $self->{states}->[0];
}

sub is_recognized {
  my $self = shift;

  if ($self->state =~ /^init|srch$/) {
    $self->state eq 'init' and $self->{state} = 'srch';
    return $self->_is_recognized;
  } else {
    return 1;
  }
}

#### _is_recognized tells you whether the current state (which could be one of many) is recognized

sub _is_recognized {
  my $self = shift;

  die "Win32::CtrlGUI::State::multi::_is_recognized is an abstract method.\n";
}

sub do_action_step {
  my $self = shift;

  $self->state eq 'rcog' and $self->{state} = 'actn';
  $self->state eq 'actn' or return 0;

  while (1) {
    unless ($self->current_state) {
      $self->{state} = 'done';
      last;
    }

    if ($self->_is_recognized) {
      $self->current_state->do_action_step;
    }

    if ($self->current_state->state =~ /^done|fail$/) {
      shift @{$self->{states}};
      next;
    }

    last;
  }
}

sub reset {
  my $self = shift;

  $self->SUPER::reset;

  $self->{states} = [@{$self->{old_states}}];
  foreach my $state (@{$self->{states}}) {
    $state->reset;
  }
}

1;
