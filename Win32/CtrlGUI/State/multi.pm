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
use Win32::CtrlGUI::State::bookkeeper;

use strict;

package Win32::CtrlGUI::State::multi;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.21';

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
      push(@{$self->{states}}, Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new(@{$i})));
    } elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::State')) {
      push(@{$self->{states}},  Win32::CtrlGUI::State::bookkeeper->new($i));
    } else {
      my $value = shift;
      if (grep {$_ eq $i} $self->_options) {
        $self->{$i} = $value;
      } else {
        ref $value eq 'ARRAY' or
            die "$class demands ARRAY refs, Win32::CtrlGUI::State objects, or class => [] pairs.\n";
        push(@{$self->{states}},  Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new($i, $value)));
      }
    }
  }

  $self->{criteria} = $class;

  $self->init;

  return $self;
}

#### _options is a class method that returns a list of known "options" that the
#### class accepts - options are considered to be paired with their value.

sub _options {
  return qw();
}

#### init gets called when a multi is initialized (i.e. by new) and when it is
#### reset.  It should set the subclass statuses appropriately.

sub init {
  my $self = shift;

  die "Win32::CtrlGUI::State::multi::init is an abstract method.";
}

#### state_recognized gets called when a substate is recognized for the first
#### time.  The state will be marked as active prior to the call, which is how
#### state_recognized can find it.

sub state_recognized {
  my $self = shift;

  die "Win32::CtrlGUI::State::multi::state_recognized is an abstract method.";
}

#### state_completed gets called when a substate is recognized for the first
#### time.  The state will be marked as active prior to the call, which is how
#### state_completed can find it.

sub state_completed {
  my $self = shift;

  die "Win32::CtrlGUI::State::multi::state_completed is an abstract method.";
}

sub get_states {
  my $self = shift;
  my($status) = @_;

  if ($status) {
    my(@retstates);
    if (ref $status eq 'Regexp') {
      @retstates = grep {$_->bk_status =~ /$status/} @{$self->{states}};
    } else {
      @retstates = grep {$_->bk_status eq $status} @{$self->{states}};
    }
    if ($status eq 'active') {
      scalar(@retstates) > 1 and die "Win32::CtrlGUI::State::multi::get_active_state error: more than one state is currently active.";
      return $retstates[0];
    }
    return @retstates;
  } else {
    return @{$self->{states}};
  }
}

sub is_recognized {
  my $self = shift;

  if ($self->state =~ /^init|srch$/) {
    $self->state eq 'init' and $self->{state} = 'srch';
    my $temp = $self->_is_recognized;
    if ($temp && $self->state eq 'srch') {
      $self->{state} = 'rcog';
    }
    return $temp;
  } else {
    return 1;
  }
}

#### _is_recognized tells you whether the current state (which could be one of
#### many) is recognized

sub _is_recognized {
  my $self = shift;

  scalar($self->get_states('active')) and return 1;
  my(@pcs_states) = $self->get_states('pcs');
  if (scalar(@pcs_states)) {
    foreach my $i (@pcs_states) {
      if ($i->is_recognized) {
        $i->bk_set_status('active');
        $self->state_recognized;
        return 1;
      }
    }
    return 0;
  } else {
    if (scalar($self->get_states('pfs'))) {
      die "Win32::CtrlGUI::State::multi::_is_recognized error: there should be no pfs states if there are no pcs states.";
    } else {
      $self->{state} = 'done';
      return 0;
    }
  }
}

sub do_action_step {
  my $self = shift;

  $self->state eq 'rcog' and $self->{state} = 'actn';

  while (1) {
    $self->state eq 'actn' or return 0;

    if ($self->_is_recognized) {
      $self->get_states('active')->do_action_step;
      if ($self->get_states('active')->state =~ /^done|fail$/) {
        $self->get_states('active')->{executed}++;
        $self->get_states('active')->bk_set_status('comp');
        $self->state_completed;
        next;
      }
    }

    last;
  }
}

sub reset {
  my $self = shift;

  $self->SUPER::reset;

  foreach my $state (@{$self->{states}}) {
    $state->reset;
  }

  $self->init;
}

1;
