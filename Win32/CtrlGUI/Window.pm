###########################################################################
#
# Win32::CtrlGUI::Window - an OO interface for controlling Win32 GUI windows
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
use Win32::Setupsup;

use strict;

package Win32::CtrlGUI::Window;
use vars qw($VERSION %atom_map $sendkey_activate $sendkey_intvl);

$VERSION='0.22';

use overload
  '""'  => \&text,
  '0+'  => \&handle,
  fallback => 1;

&init;

=head1 NAME

Win32::CtrlGUI::Window - an OO interface for controlling Win32 GUI windows

=head1 SYNOPSIS

  use Win32::CtrlGUI

  my $window = Win32::CtrlGUI::wait_for_window(qr/Notepad/);
  $window->send_keys("!fx");

=head1 DESCRIPTION

C<Win32::CtrlGUI::Window> objects represent GUI windows, and are used to interact with those
windows.

=head1 GLOBALS

=head2 $Win32::CtrlGUI::Window::sendkey_activate

I couldn't think of any reason that anyone would B<not> want to activate the window before sending
it keys (especially given the way this OO front-end works), but if you do find yourself in that
situation, change this to 0.

=head2 $Win32::CtrlGUI::Window::sendkey_intvl

This global parameter specifies the I<default> interval between keystrokes when executing a
C<send_keys>.  The value is specified in milliseconds.  The C<send_keys> method also takes an
optional parameter that will override this value.  The default value is 0.

=head1 METHODS

=head2 _new

This method is titled C<_new> because it would rarely get called by user-level code.  It takes a
passed window handle and returns a C<Win32::CtrlGUI::Window> object.

=cut

sub _new {
  my $class = shift;

  my $self = {
    handle => $_[0]
  };
  bless $self, $class;
  return $self;
}

=head2 handle

This method returns the window's handle.  Rarely used because the numification operator for
C<Win32::CtrlGUI::Window> is overloaded to call it.

=cut

sub handle {
  my $self = shift;

  return $self->{handle};
}

=head2 text

This method returns the window's text.  Rarely used because the stringification operator for
C<Win32::CtrlGUI::Window> is overloaded to call it.  Thus, instead of writing C<print
$window-E<gt>text,"\n";>, one can simply write C<print $window,"\n";>  If you want to print out the
handle number, write C<print $window-E<gt>handle,"\n"> or C<print int($window),"\n">.

If the window no longer exists, the method will return undef;

=cut

sub text {
  my $self = shift;

  $self->exists or return undef;
  Win32::Setupsup::GetWindowText($self->handle, \my $retval) or return undef;
  return $retval;
}

=head2 exists

Calls C<Win32::Setupsup::WaitForWindowClose> with a timeout of 1ms to determine whether the window
still exists or not.  Returns true if the C<Win32::CtrlGUI::Window> object still refers to an
existing window, returns false if it does not.

=cut

sub exists {
  my $self = shift;

  Win32::Setupsup::WaitForWindowClose($self->handle, 1);
  my $error = Win32::Setupsup::GetLastError();
  $error == 536870926 and return 1;
  $error == 0 and return 0;
  die "Win32::Setupsup::GetLastError returned unknown error code in Win32::CtrlGUI::Window::exists.\n";
}

=head2 send_keys

The C<send_keys> method sends keystrokes to the window.  The first parameter is the text to send.
The second parameter is optional and specifies the interval between sending keystrokes, in
milliseconds.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::send_keys called on non-existent window handle I<handle>."

I found the C<SendKeys> syntax used by C<Win32::Setupsup> to be rather unwieldy.  I missed the
syntax used in WinBatch, so I implemented a conversion routine.  At the same time, I extended the
syntax a little.  I think you'll like the result.

The meta-characters are:

=over 4

=item !

Holds the Alt key down for the next character

=item ^

Holds the Ctrl key down for the next character

=item +

Holds the Shift key down for the next character

=item { and }

Used to send special characters, sequences, or for sleeping

=back

The C<!>, C<^>, and C<+> characters can be combined.  For instance, to send a Ctrl-Shift-F7, one uses the sequence C<^+{F7}>.

The special characters sendable using the curly braces are:

  Alt         {ALT}
  Backspace   {BACKSPACE} or {BS} or {BACK}
  Clear       {CLEAR}
  Delete      {DELETE} or {DEL}
  Down Arrow  {DOWN} or {DN}
  End         {END}
  Enter       {ENTER} or {RET}
  Escape      {ESCAPE} or {ESC}
  F1->F12     {F1}->{F12}
  Help        {HELP}
  Home        {HOME} or {BEG}
  Insert      {INSERT} or {INS}
  Left Arrow  {LEFT}
  NumKey 0->9 {NUM0}->{NUM9}
  NumKey /*-+ {NUM/} or {NUM*} or {NUM-} or {NUM+}
  Page Down   {PGDN}
  Page Up     {PGUP}
  Right Arrow {RIGHT}
  Space       {SPACE} or {SP}
  Tab         {TAB}
  Up Arrow    {UP}

  !           {!}
  ^           {^}
  +           {+}
  }           {}}
  {           {{}

If the character name is followed by a space and an integer, the key will be repeated that many
times.  For instance, to send 15 down arrows keystrokes, use C<{DOWN 15}>.  To send 5 asterisks,
use C<{* 5}>.  This doesn't work for sending multiple number keys (unless you use NUM0 or some
such).

Finally, if the contents of the {} block are a number - either integer or floating point, a pause
will be inserted at the point.  For instance,
C<$window-E<gt>send_keys("!n{2.5}C:\\Foo.txt{1}{ENTER}")> is equivalent to:

  $window->send_keys("!n");
  Win32::Sleep(2500);
  $window->send_keys("C:\\Foo.txt");
  Win32::Sleep(1000);
  $window->send_keys("{ENTER}");

Hope you like the work.

=cut

sub send_keys {
  my $self = shift;
  my($keys, $intvl) = @_;

  foreach my $i (&_convert_send_keys($keys)) {
    if (ref $i eq 'SCALAR') {
      Win32::Sleep($$i*1000);
    } else {
      $self->_send_keys($i, $intvl);
    }
  }
}

=head2 enum_child_windows

Returns a list of the window's child windows.  They are, of course, C<Win32::CtrlGUI::Window>
objects.

If the window no longer exists, the method will return undef;

=cut

sub enum_child_windows {
  my $self = shift;

  $self->exists or return undef;
  Win32::Setupsup::EnumChildWindows($self->handle, \my @children) or return undef;
  return (map {(ref $self)->_new($_)} @children);
}

=head2 has_child

Checks to see whether the window has a child window matching the passed criteria.  Same criteria
options as found in C<Win32::CtrlGUI::wait_for_window>.  Returns 0 or 1.

If the window no longer exists, the method will return undef;

=cut

sub has_child {
  my $self = shift;
  my($criteria) = @_;

  $self->exists or return undef;
  Win32::Setupsup::EnumChildWindows($self->handle, \my @children) or return undef;

  foreach my $i (@children) {
    Win32::Setupsup::GetWindowText($i, \my $temp);
    if (ref $criteria eq 'CODE') {
      $_ = Win32::CtrlGUI::Window->_new($i);
      &$criteria and return 1;
    } elsif (ref $criteria eq 'Regexp') {
      $temp =~ /$criteria/ and return 1;
    } else {
      lc($temp) eq lc($criteria) and return 1;
    }
  }
  return 0;
}

=head2 set_focus

Calls C<Win32::Setupsup::SetFocus> on the window.  See the C<Win32::Setupsup::SetFocus>
documentation for caveats concerning this method.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::set_focus called on non-existent window handle I<handle>."

=cut

sub set_focus {
  my $self = shift;

  $self->exists or die 'Win32::CtrlGUI::Window::set_focus called on non-existent window handle '.$self->handle.".\n";
  Win32::Setupsup::SetFocus($self->handle);
}

=head2 get_properties

Calls C<Win32::Setupsup::GetWindowProperties> on the window.  Passes the list of requested
properties and returns the list of returned values in the same order.

If the window no longer exists, the method will return undef;

=cut

sub get_properties {
  my $self = shift;
  my(@properties) = @_;

  $self->exists or return undef;
  Win32::Setupsup::GetWindowProperties($self->handle, \@properties, \my %properties) or return undef;
  return (map {$properties{$_}} @properties);
}

=head2 set_properties

Calls C<Win32::Setupsup::SetWindowProperties> on the window.

If the window no longer exists, this method will die with the error
"Win32::CtrlGUI::Window::set_properties called on non-existent window handle I<handle>."

=cut

sub set_properties {
  my $self = shift;
  my(%properties) = @_;

  $self->exists or die 'Win32::CtrlGUI::Window::set_properties called on non-existent window handle '.$self->handle.".\n";
  return Win32::Setupsup::SetWindowProperties($self->handle, \%properties);
}



sub _send_keys {
  my $self = shift;
  my($keys, $intvl) = @_;

  $self->exists or die 'Win32::CtrlGUI::Window::send_keys called on non-existent window handle '.$self->handle.".\n";
  Win32::Setupsup::SendKeys($self->handle, $keys, $sendkey_activate, defined $intvl ? $intvl : $sendkey_intvl);
}

sub _convert_send_keys {
  my($input) = @_;

  #Turn backslashes into doubled backslashes
  $input =~ s/\\/\\\\/g;

  #Match qualifier sequences
  while ($input =~ /^(.*?)(?<!\{)([+!^]+)(\{[{}]\}|\{[^}]*\}|\\\\|[^{])(.*)$/) {
    my($begin, $qualifiers, $atom, $end) = ($1, $2, $3, $4);
    $qualifiers =~ /(.)\1/ and die "SendKey conversion error: The qualifiers string \"$qualifiers\" contains a repeat.\n";
    my($startq, $endq);
    foreach my $q (reverse split(//, $qualifiers)) {
      $q = {'+' => 'SHIFT', '^' => 'CTRL', '!' => 'ALT'}->{$q};
      $atom = "\\$q\\$atom\\$q-\\";
    }
    $input = "$begin$atom$end";
  }

  #Match atoms and evaluate
  while ($input =~ /^(.*?)\{([^{}0-9][^{}]*)\}(.*)$/) {
    my($begin, $atom, $end) = ($1, $2, $3);
    $atom =~ /^(\S+)( \d+)?$/ or die "SendKey conversion error: The curly string \"$atom\" is illegal.\n";
    $atom = $1;
    my $repeat = int($2 ? $2 : 1);
    if (exists($atom_map{$atom})) {
      $input = $begin.($atom_map{$atom} x $repeat).$end;
    } elsif ($repeat > 1 and length($atom) == 1) {
      $input = $begin.($atom x $repeat).$end;
    } else {
      die "Unknown atom \"$atom\".\n";
    }
  }

  #Unmatched curly braces checking - first we get rid of {{}, {}}, and {4.5} type stuff
  (my $input_test = $input) =~ s/\{[{}]\}//g;
  $input_test =~ s/\{[0-9][0-9]*(\.[0-9]+)?\}//g;
  $input_test =~ /[{}]/ and die "SendKey conversion error: There are unmatched curly braces in \"$input\".\n";

  #Convert {{} to { and {}} to }
  $input =~ s/\{([{}])\}/$1/g;

  #Add +'s to modifier key down strokes
  $input =~ s/\\(ALT|CTRL|SHIFT)\\/\\$1+\\/g;

  #Deal with pause (i.e. {4.5}) commands
  my(@retval);
  while ($input =~ /(.*?)\{([0-9][0-9]*(\.[0-9]+)?)\}(.*)/) {
    my($begin, $sleep, $end) = ($1, $2, $4);
    push(@retval, $begin, \$sleep);
    $input = $end;
  }
  push(@retval, $input);

  return @retval;
}

sub init {
  &init_atom_map;
  $sendkey_activate = 1;
  $sendkey_intvl = 0;
}

sub init_atom_map {
  %atom_map = ('!' => '!', '^' => '^', '+' => '+', 'ALT' => "\\ALT+\\\\ALT-\\", 'SPACE' => ' ', 'SP' => ' ');
  $atom_map{BACKSPACE} = "\\BACK\\";

  foreach my $i (qw(BACK BEG DEL DN END ESC HELP INS LEFT PGDN PGUP RET RIGHT TAB UP)) {
    $atom_map{$i} = "\\$i\\";
  }

  foreach my $i (1..12) {
    $atom_map{"F$i"} = "\\F$i\\";
  }

  foreach my $i (0..9, '*', '+', '-', '/') {
    $atom_map{"NUM$i"} = "\\NUM$i\\";
  }

  $atom_map{BACKSPACE} = "\\BACK\\";
  $atom_map{BS} =        "\\BACK\\";
  $atom_map{DELETE} =    "\\DEL\\";
  $atom_map{DOWN} =      "\\DN\\";
  $atom_map{ENTER} =     "\\RET\\";
  $atom_map{ESCAPE} =    "\\ESC\\";
  $atom_map{HOME} =      "\\BEG\\";
  $atom_map{INSERT} =    "\\INS\\";
}

1;
