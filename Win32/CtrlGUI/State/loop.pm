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
use Win32::CtrlGUI::State::seq_opt;

use strict;

package Win32::CtrlGUI::State::loop;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::State::seq_opt');

$VERSION='0.10';

sub _new {
  my $class = shift;
  my %data = @_;

  my $self = {
    body_block => undef,
    body_init => undef,
    exit_block => undef,
    timeout => $data{timeout},
    body_req => $data{body_req},
    state => 'init',
    active => undef,
  };

  bless $self, $class;

  ref $data{body_block} eq 'ARRAY' or die "loop demands an ARRAY ref for the body_block.\n";
  $self->{body_init} = $data{body_block};
  $self->_reset_body;

  if (exists $data{exit_block}) {
    if (ref $data{exit_block} eq 'ARRAY') {
        $self->{exit_block} = Win32::CtrlGUI::State->new(@{$data{exit_block}});
    } elsif (UNIVERSAL::isa($data{exit_block}, 'Win32::CtrlGUI::State')) {
        $self->{exit_block} = $data{exit_block};
    } else {
      die "loop demands ARRAY refs or Win32::CtrlGUI::State objects for the exit_block.\n";
    }
  }

  if (!$self->{exit_block} && !$self->{timeout}) {
    die "loop demands either an exit_block or a timeout.\n";
  }

  return $self;
}

sub _reset_body {
  my $self = shift;

  $self->{body_block} = Win32::CtrlGUI::State->new(@{$self->{body_init}});
  $self->{active} = undef;
  $self->{end_time} = 0;
}

sub _is_recognized {
  my $self = shift;

  $self->{active} and return 1;

  if (!$self->{end_time} && $self->{timeout}) {
    $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
  }

  if ($self->{body_block}->is_recognized) {
    $self->{state} = 'rcog';
    $self->{active} = 'body_block';
    $self->{body_req} = 0;
    return 1;
  }

  unless ($self->{body_req}) {
    if ($self->{exit_block}->is_recognized) {
      $self->{state} = 'rcog';
      $self->{active} = 'exit_block';
      return 1;
    }
  }

  if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
    $self->{state} = 'done';
    return 1;
  }
  return 0;
}

sub current_state {
  my $self = shift;
  return $self->{$self->{active}};
}

sub do_action_step {
  my $self = shift;

  $self->state eq 'rcog' and $self->{state} = 'actn';
  $self->state eq 'actn' or return 0;

  while (1) {
    if ($self->_is_recognized) {
      $self->{state} eq 'done' and return 0;
      my $current_state = $self->current_state;

      $current_state->do_action_step;

      if ($current_state->state =~ /^done|fail$/) {
        if ($self->{active} eq 'body_block') {
          $self->_reset_body;
        } elsif ($self->{active} eq 'exit_block') {
          $self->{state} = 'done';
          return 0;
        }
      } else {
        return 1;
      }
    }
  }
  return 0;
}

1;
