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

package Win32::CtrlGUI::Criteria;
use vars qw($VERSION);

use overload
  '""'  => sub {$_[0]->stringify};

$VERSION='0.11';

=head1 NAME

Win32::CtrlGUI::Criteria - an OO interface for expressing state criteria

=head1 SYNOPSIS

  use Win32::CtrlGUI::Criteria

  my $criteria = Win32::CtrlGUI::Criteria->new(pos => qr/Notepad/);


  use Win32::CtrlGUI::State

  my $state = Win32::CtrlGUI::State->new(atom => criteria => [pos => qr/Notepad/], action => "!fo");

=head1 DESCRIPTION

C<Win32::CtrlGUI::Criteria> objects represent state criteria, and are used by the
C<Win32::CtrlGUI::State> system to determine when a state has been entered.  There are three main
subclasses - C<Win32::CtrlGUI::Criteria::pos>, C<Win32::CtrlGUI::Criteria::neg>, and
C<Win32::CtrlGUI::Criteria::arbitrary>.  These will be discussed in the documentation for
C<Win32::CtrlGUI::Criteria>, rather than in the implementation classes.

=head1 METHODS

=head2 new

The first parameter to the C<new> method is the subclass to create - C<pos>, C<neg>, or
C<arbitrary>. The remaining parameters are passed to the C<new> method for that class.  Thus,
C<Win32::CtrlGUI::Criteria-E<gt>new(pos => qr/Notepad/)> is the same as
C<Win32::CtrlGUI::Criteria::pos-E<gt>new(qr/Notepad/)>.

The passed parameters for the C<pos> and C<neg> subclasses are the window criteria and
childcriteria, with the same options available as for C<Win32::CtrlGUI::wait_for_window>.  The
C<pos> subclass will return true (i.e. the criteria are met) when a window matching those criteria
exists.  The C<neg> subclass will return true when no windows matching the passed criteria exist.
The C<pos> subclass will return a C<Win32::CtrlGUI::Window> object for the matching window when it
returns true.

The C<arbitrary> subclass takes a code reference and a list of hash parameters.  The hash
parameters will be added to the C<Win32::CtrlGUI::Criteria::arbitrary> object, and the code
reference will be passed a reference to the C<Win32::CtrlGUI::Criteria::arbitrary> object at
run-time.  This enables the code reference to use the C<Win32::CtrlGUI::Criteria::arbitrary> to
store state.  The code reference should return true when evaluated if the state criteria have been
met.

=cut

sub new {
  my $class = shift;
  my $type = shift;

  $class = "Win32::CtrlGUI::Criteria::".$type;
  (my $temp = "$class.pm") =~ s/::/\//g;
  require $temp;
  return $class->new(@_);
}

=head stringify

The C<stringify> method is called by the overloaded stringification operator and should return a
printable string suitable for debug work.

=cut

sub stringify {
  my $self = shift;

  my $subclass = ref $self;
  $subclass =~ s/^.*:://;
  my $retval = "$subclass: ";

  if (ref $self->{criteria} eq 'Regexp') {
    $retval .= "/".$self->{criteria}."/";
  } elsif (ref $self->{criteria} eq 'CODE') {
    $retval .= 'CODE';
  } else {
    $retval .= "'$self->{criteria}'";
  }

  if (defined $self->{childcriteria}) {
    if (ref $self->{childcriteria} eq 'Regexp') {
      $retval .= ", /".$self->{childcriteria}."/";
    } elsif (ref $self->{childcriteria} eq 'CODE') {
      $retval .= ', CODE';
    } else {
      $retval .= ", '$self->{childcriteria}'";
    }
  }

  return $retval;
}

=head is_recognized

The C<is_recognized> method is called to determine if the criteria are currently being met.

=cut

1;
