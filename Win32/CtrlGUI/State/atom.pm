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
use vars qw($VERSION @ISA $action_error_handler);

@ISA = ('Win32::CtrlGUI::State');

$VERSION='0.21';

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
      if (ref $rcog) {
        $self->{rcog_win} = $rcog;
        $self->{name} and $Win32::CtrlGUI::Window::named_windows{$self->{name}} = $rcog;
      }

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
    $wait_time > 0 and $self->debug_print(1, sprintf("Looping for %0.3f seconds before executing action.", $wait_time));
  }
  $self->state eq 'actn' or return;

  if ($self->{rcog_time} + $self->action_delay * 1000 <= Win32::GetTickCount()) {
    my $coderef;
    if (ref $self->{action} eq 'CODE') {
      $self->debug_print(1, "Executing code action.");
      $coderef = $self->{action};
    } elsif ($self->{action}) {
      $self->debug_print(1, "Sending keys '$self->{action}'.");
      $coderef = sub { $_[0]->{rcog_win}->send_keys($_[0]->{action}); };
    } else {
      $self->debug_print(1, "No action.");
      $coderef = sub {};
    }

    eval {$coderef->($self);};
    if ($@) {
      $self->action_error_handler->($@);
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
  UNIVERSAL::isa($self->{criteria}, 'Win32::CtrlGUI::Criteria') and $self->{criteria}->reset;
}

sub action_error_handler {
  my $self = shift;

  ref($self->{action_error_handler}) eq 'CODE' and return $self->{action_error_handler};
  ref($action_error_handler) eq 'CODE' and return $action_error_handler;
  return sub { die $_[0]; };
}

sub stringify {
  my $self = shift;

  return join("\n", map {"$_ =>$self->{$_}"} grep {exists $self->{$_}} qw(criteria action name timeout));
}

sub tagged_stringify {
  my $self = shift;

  my @retval;

  push(@retval, ["criteria:\t", 'default']);
  push(@retval, $self->{criteria}->tagged_stringify);
  push(@retval, ["\n", 'default']);

  foreach my $i (qw(action name)) {
    exists $self->{$i} or next;
    push(@retval, ["$i:\t$self->{$i}\n", 'default']);
  }

  if ($self->{timeout}) {
    my $timeout;
    if ($self->{end_time}) {
      $timeout = ($self->{end_time}-Win32::GetTickCount())/1000;
      $timeout < 0 and $timeout = 0;
      $timeout = sprintf("%0.3f", $timeout);
    } else {
      $timeout = 'wait';
    }
    push(@retval, ["timeout => $timeout\n", 'default']);
  }

  chomp($retval[$#retval]->[0]);

  return @retval;
}

1;
