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
use Win32::CtrlGUI::Criteria;

use strict;

package Win32::CtrlGUI::Criteria::multi;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::Criteria');

$VERSION='0.30';

sub new {
  my $class = shift;

  $class eq 'Win32::CtrlGUI::Criteria::multi' and die "$class is an abstract parent class.\n";

  my $self = {
    criteria => [],
    criteria_status => [],
  };

  bless $self, $class;

  while (my $i = shift) {
    if (ref $i eq 'ARRAY') {
      push(@{$self->{criteria}}, Win32::CtrlGUI::Criteria->new(@{$i}));
    } elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::Criteria')) {
      push(@{$self->{criteria}}, $i);
    } else {
      my $value = shift;
      if (grep {$_ eq $i} $self->_options) {
        $self->{$i} = $value;
      } else {
        ref $value eq 'ARRAY' or
            die "$class demands ARRAY refs, Win32::CtrlGUI::Criteria objects, or class => [] pairs.\n";
        push(@{$self->{criteria}},  Win32::CtrlGUI::Criteria->new($i, $value));
      }
    }
  }

  scalar(@{$self->{criteria}}) or die "$class demands at least one sub-criteria.\n";

  $self->init;

  return $self;
}

#### _options is a class method that returns a list of known "options" that the
#### class accepts - options are considered to be paired with their value.

sub _options {
  return qw(timeout);
}

#### init gets called when a multi is initialized (i.e. by new) and when it is
#### reset.  It should set the subclass statuses appropriately.

sub init {
  my $self = shift;

  delete($self->{end_time});
}

sub stringify {
  my $self = shift;

  (my $subclass = ref($self)) =~ s/^.*:://;
  return "$subclass(".join(", ", grep(/\S/, $self->{timeout} ? "timeout => $self->{timeout}" : undef), map {$_->stringify} @{$self->{criteria}}).")";
}

sub tagged_stringify {
  my $self = shift;

  (my $subclass = ref($self)) =~ s/^.*:://;
  my $tag = $self->_is_recognized ? 'active' : 'default';

  my(@retval);
  push(@retval, ["$subclass(", $tag]);

  if ($self->{timeout}) {
    my $timeout;
    if ($self->{end_time}) {
      $timeout = ($self->{end_time}-Win32::GetTickCount())/1000;
      $timeout < 0 and $timeout = 0;
      $timeout = sprintf("%0.3f", $timeout);
    } else {
      $timeout = 'wait';
    }
    push(@retval, ["timeout => $timeout", $tag]);
    push(@retval, [", ", $tag]);
  }

  foreach my $i (0..$#{$self->{criteria}}) {
    if (UNIVERSAL::isa($self->{criteria}->[$i], 'Win32::CtrlGUI::Criteria::multi')) {
      push(@retval, $self->{criteria}->[$i]->tagged_stringify);
    } else {
      push(@retval, [$self->{criteria}->[$i]->stringify, $self->{criteria_status}->[$i] ? 'active' : 'default']);
    }
    push(@retval, [", ", $tag]);
  }
  $retval[$#retval]->[0] eq ", " and pop(@retval);

  push(@retval, [")", $tag]);

  return @retval;
}

sub is_recognized {
  my $self = shift;

  $self->_update_criteria_status;

  if ($self->{timeout}) {
    my $rcog = $self->_is_recognized;
    if (ref $rcog || $rcog) {
      if ($self->{end_time}) {
        Win32::GetTickCount() >= $self->{end_time} and return $rcog;
      } else {
        $self->{end_time} = Win32::GetTickCount() + $self->{timeout} * 1000;
      }
    } else {
      delete($self->{end_time});
    }
  } else {
    return $self->_is_recognized;
  }
  return;
}

#### _is_recognized returns whether the state is actively recognized,
#### independent of the timeout. It should be overriden by the subclasses.

sub _is_recognized {
  my $self = shift;

  die "Win32::CtrlGUI::Criteria::multi::_is_recognized is an abstract method and needs to be overriden.\n";
}

sub _update_criteria_status {
  my $self = shift;

  foreach my $i (0..$#{$self->{criteria}}) {
    $self->{criteria_status}->[$i] = $self->{criteria}->[$i]->is_recognized;
  }
}

sub reset {
  my $self = shift;

  $self->SUPER::reset;

  foreach my $crit (@{$self->{criteria}}) {
    $crit->reset;
  }

  $self->init;
}

1;
