###########################################################################
#
# Win32::CtrlGUI::State - an abstract parent class for implementing States
#
# Author: Toby Everett
# Revision: 0.10
# Last Change: Developed
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

use strict;

package Win32::CtrlGUI::State;
use vars qw($VERSION $wait_intvl $action_delay $debug);

$VERSION='0.10';

&init;

=head1 NAME

Win32::CtrlGUI::State - an OO system for controlling Win32 GUI windows through a state machine

=head1 SYNOPSIS

  use Win32::CtrlGUI::State

  Win32::CtrlGUI::State->newdo(
    seq =>
    [atom => criteria => [pos => qr/Notepad/],
      action => "!fo"],

    [ seq_opt =>
      [ seq =>
        [atom => criteria => [pos => 'Notepad', qr/^The text in the .* file has changed/i],
          action => "!y"],

        [dialog =>
          criteria => [pos => 'Save As'], action => "!nC:\\TEMP\\Saved.txt{ENTER}",
          cnfm_criteria => [pos => 'Save As', qr/already exists/i], cnfm_action => "!y"],
      ],

      [dialog => criteria => [pos => 'Open', 'Cancel'],
        action => "!n{1}".Win32::GetCwd()."\\demo.pl{1}{HOME}{2}{ENTER}"],
    ],

    [dialog => criteria => [pos => qr/Notepad/],
      action => "!fx"],
  );

=head1 DESCRIPTION

C<Win32::CtrlGUI::State> is used to define a set of state, the desired response to those state,
and how those states fit together so as to make it easier to control Win32 GUI windows.  Think of
it as intelligent flow-control for Win32 GUI control.

The system itself is object-oriented - there are a number of types of states, most of which accept
a list of other states as parameters.  If you think about it, code-blocks are objects.  So are
if-then statements.  So, rather than write my own language and parser for doing flow-control of
GUI windows, I made an OO system within Perl.  Much easier than writing a parser.

The basic state subclasses are:

=over 4

=item atom

These are used to specify single "events" in the system.  Passed to the constructor are a set of
criteria and the action to take when those criteria are met.  If that atom is currently active and
the criteria become met, the action will be executed.  It also takes on optional timeout
parameter.

=item seq

This state takes a list of other states as a parameter.  Those states will be waited for
one-by-one and the actions executed.  No state is allowed to be skipped.

=item seq_opt

This state is similar to C<seq>, except that any state may be skipped except for the last one.
The last state in the list is sometimes referred to as the exit criteria.

=item fork

This state takes a list of other states as a parameter.  The first state to be met will be
executed and none of the others will.  Think of it as a select-case statement.  Of course, C<seq>
and C<seq_opt> states can be passed to the C<fork> state.

=item dialog

The C<dialog> state was created to deal with a common problem, that is to say waiting for a window
to pop up, sending it text, and then waiting for it to disappear.  In addition, the C<dialog>
state takes an optional set of parameters for a "confirmation" window.  If the confirmation window
shows up before the original window disappears, the confirmation action will be executed.  The
C<dialog> state is implemented using a C<seq> state and, if there is a confirmation specification,
a C<seq_opt> state.

=back

=head1 METHODS

=head2 new

The first parameter to the C<new> method is the subclass to create - C<atom>, C<seq>, C<seq_opt>,
etc.  The C<_new> method for that class is then called and the remaining parameters passed.

=cut

sub new {
  my $class = shift;
  my $type = shift;

  $class = "Win32::CtrlGUI::State::".$type;
  (my $temp = "$class.pm") =~ s/::/\//g;
  require $temp;
  return $class->_new(@_);
}

=head2 _new

The default C<_new> method takes a list of hash entries, places the object in the C<init> state,
and returns the object.  Also, if it finds an array reference in C<$self-E<GT>{criteria}>, it
creates a new C<Win32::CtrlGUI::Criteria> object based on it.

=cut

sub _new {
  my $class = shift;

  my $self = {
    @_,
    state => 'init',
  };

  if (ref ($self->{criteria}) eq 'ARRAY') {
    $self->{criteria} = Win32::CtrlGUI::Criteria->new(@{$self->{criteria}});
  }
  bless $self, $class;
}

=head2 newdo

This calls C<new> and then C<do_state>.  It returns the C<Win32::CtrlGUI::State> object after it
has finished executing.

=cut

sub newdo {
  my $class = shift;

  my $self = $class->new(@_);
  $self->do_state;
  return $self;
}

sub state {
  my $self = shift;
  return $self->{state};
}

sub wait_intvl {
  my $self = shift;
  return defined $self->{wait_intvl} ? $self->{wait_intvl} : $wait_intvl;
}

sub action_delay {
  my $self = shift;
  return defined $self->{action_delay} ? $self->{action_delay} : $action_delay;
}

sub debug {
  my $self = shift;
  return defined $self->{debug} ? $self->{debug} : $debug;
}

sub debug_print {
  my $self = shift;
  my($debug_level, $text) = @_;

  if ($debug_level & $self->debug) {
    print $text,"\n";
  }
}

sub init {
  $wait_intvl = 100;
  $action_delay = 5;
  $debug = 0;
}

1;
