###########################################################################
#
# Win32::CtrlGUI::State - an abstract parent class for implementing States
#
# Author: Toby Everett
# Revision: 0.22
# Last Change:
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

$VERSION='0.22';

&init;

=head1 NAME

Win32::CtrlGUI::State - an OO system for controlling Win32 GUI windows through a state machine

=head1 SYNOPSIS

  use Win32::CtrlGUI::State;

  Win32::CtrlGUI::State->newdo(
    seq => [
      atom => [criteria => [pos => qr/Notepad/],
               action => "!fo"],

      seq_opt => [
        seq => [
          atom => [criteria => [pos => 'Notepad', qr/^The text in the .* file has changed/i],
                   action => "!y"],

          dialog => [criteria => [pos => 'Save As'],
                     action => "!nC:\\TEMP\\Saved.txt{1}{ENTER}",
                     timeout => 5,
                     cnfm_criteria => [pos => 'Save As', qr/already exists/i],
                     cnfm_action => "!y"],
        ],

        dialog => [criteria => [pos => 'Open', 'Cancel'],
                   action => "!n{1}".Win32::GetCwd()."\\test.pl{1}{HOME}{2}{ENTER}"],
      ],

      dialog => [criteria => [pos => qr/Notepad/],
                 action => "!fx"],
    ]
  );

=head1 DESCRIPTION

C<Win32::CtrlGUI::State> is used to define a set of state, the desired response to those state,
and how those states fit together so as to make it easier to control Win32 GUI windows.  Think of
it as intelligent flow-control for Win32 GUI control.  Also, it lets you use a Tk debugger to
observe your scripts as they execute.

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

=item multi

This is an abstract parent class intended to support such classes as C<seq>, C<seq_opt>, C<fork>,
and C<loop>.  The preferred syntax for passing states to C<multi> subclasses is:

  multi => [
    parameter => value,
    state1_class => [ state1 parameters ],
    state2_class => [ state2 parameters ],
  ],

Alternate legal syntaxes include:

  multi => [
    [state1_class => state1 parameters],
    Win32::CtrlGUI::State:state2_class->new(state2 parameters),
  ]

That is to say, C<multi> class objects expect their parameter array to consist of a sequence of
these four "entities" (which can be alternated as desired):

=over 4

=item *

I<parameter> => I<value> pairs

=item *

I<state_class> => I<array ref to state parameters> pairs

=item *

I<array ref to state1_class, state parameters>

=item *

I<Win32::Ctrl::GUI::State class object>

=back

=item seq

The passed states will be waited for one-by-one and the actions executed.  No state is allowed to
be skipped.

=item seq_opt

This state is similar to C<seq>, except that any state may be skipped except for the last one.
That is to say, execution will "jump" to whichever state shows up first.  Once a state has been
jumped to, the previous states will not be executed. The last state in the list is sometimes
referred to as the exit criteria.

=item fork

The first state to be met will be executed and none of the others will.  Think of it as a
select-case statement.  Of course, C<seq> and C<seq_opt> states can be passed to the C<fork>
state.

=item loop

Lets you do loops:)  Loops take two optional parameters - C<timeout> and C<body_req> and either
one or two states.  The first state is the "body" state and the second the "exit" state.  I
strongly encourage the use of the C<dialog> state when building loops (this is B<especially>
critical for loops where the body only has one state - otherwise, simple atoms may trigger
multiple times off of the same window).

=item dialog

The C<dialog> state was created to deal with a common problem, that is to say waiting for a window
to pop up, sending it text, and then waiting for it to disappear.  In addition, the C<dialog>
state takes an optional set of parameters for a "confirmation" window.  If the confirmation window
shows up before the original window disappears, the confirmation action will be executed.  The
C<dialog> state is implemented using a C<seq> state and, if there is a confirmation specification,
a C<seq_opt> state.  Note that waiting for the window to disappear is based on the window handle,
not on the criteria, which makes this safe to use in loops.

=back

Of note, if you pass a C<multi> state to another C<multi> state, remember that the "child" state
has to finish executing before the parent can continue.  For instance, in the following code, if
the window "Foo" is seen, seeing the window "Done" will not cause the loop to exit until the
window "Bar" has been seen.

  Win32::CtrlGUI::State->newdo(
    loop => [
      seq => [
          dialog => [criteria => [pos => 'Foo'], action => '{ENTER}'],
          dialog => [criteria => [pos => 'Bar'], action => '{ENTER}'],
      ],
      seq => [
          atom => [criteria => [pos => 'Done'], action => '{ENTER}'],
      ],
    ]
  );


=head1 STATES

It is important to note that Win32::CtrlGUI::State objects can be in one of six different states.
They are:

=over 4

=item init

This is the state before the object has had any methods invoked on it.

=item srch

This is the state the object enters after C<is_recognized> is first called on it, but before the
desired state has been recognized.  Distinguishing between <init> and <srch> allows time outs to
be implemented.

=item rcog

This is the state the object enters after its criteria are first recognized.

=item actn

This is the state the object enters when C<do_action_step> is first called.

=item done

This is the state the object enters after the action is fully completed.

=item fail

This is the state the object enters when a time out has occurred (this doesn't apply to C<loop>
states, but does apply to C<atom> states).

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
  if (scalar(@_) == 1 && ref $_[0] eq 'ARRAY') {
    return $class->_new(@{$_[0]});
  } else {
    return $class->_new(@_);
  }
}

=head2 _new

The default C<_new> method takes a list of hash entries, places the object in the C<init> state,
and returns the object.

=cut

sub _new {
  my $class = shift;

  my $self = {
    @_,
    state => 'init',
  };

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

=head2 is_recognized

This is a generic method and has to be overriden by the subclass.  When C<is_recognized> is
called, it should return true if this state is currently or has ever been recognized (once a path
is followed, the path needs to be followed until the end.)

=cut

sub is_recognized {
  my $self = shift;

  die "Win32::CtrlGUI::State::is_recognized is an abstract method and needs to be overriden.\n";
}

=head2 wait_recognized

This will wait until a given state has been recognized.

=cut

sub wait_recognized {
  my $self = shift;

  $self->{state} ne 'rcog' and $self->debug_print(1, "Waiting for criteria $self->{criteria}.");
  until ($self->is_recognized) {
    Win32::Sleep($self->wait_intvl);
  }
}

=head2 do_action_step

Because the whole system is capable of being driven in an asynchronous manner from the very top
(which makes it possible to run the C<Win32::CtrlGUI::State> system from within Tk, for instance),
actions need to be executable in a non-blocking fashion.  The method call C<do_action_step> is
crucial to that.  Remember that there is an action "delay", so C<do_action_step> will keep
returning, but not setting the state to C<done>, until that delay is used up and the action can
actually be executed.  The system does not yet allow for multi-part actions in and of themselves
(for instance, it will still block if a sendkeys action involves internal delays).

=cut

sub do_action_step {
  my $self = shift;

  die "Win32::CtrlGUI::State::do_action_step is an abstract method and needs to be overriden.\n";
}

=head2 wait_action

This will wait until the action for a given state has been completed.  It should only be called
after C<is_recognized> returns true.

=cut

sub wait_action {
  my $self = shift;

  $self->state =~ /^actn|rcog$/ or return 0;

  while (1) {
    $self->do_action_step;
    $self->state =~ /^done|fail$/ and last;
    Win32::Sleep($self->wait_intvl);
  }
  return 1;
}

=head2 do_state

This will wait until the state is recognized (by calling C<wait_recognized>) and then execute the
action (by calling C<wait_action>).

=cut

sub do_state {
  my $self = shift;

  $self->wait_recognized;
  $self->wait_action;
}

=head2 reset

The reset method automagically resets the state as if nothing had ever happened.

=cut

sub reset {
  my $self = shift;

  $self->{state} = 'init';
}


#### Accessor methods

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

sub criteria {
  my $self = shift;
  return $self->{criteria};
}

#### Generic Debug Code

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

#### Class Methods

sub init {
  $wait_intvl = 100;
  $action_delay = 5;
  $debug = 0;
}

1;
