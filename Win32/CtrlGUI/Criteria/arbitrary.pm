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

package Win32::CtrlGUI::Criteria::arbitrary;
use vars qw($VERSION @ISA);

@ISA = 'Win32::CtrlGUI::Criteria';

$VERSION='0.10';

sub new {
  my $class = shift;

  my $self = {
    code => shift,
    @_
  };

  bless $self, $class;
  return $self;
}

sub is_recognized {
  my $self = shift;

  return $self->{code}->($self);
}

sub stringify {
  my $self = shift;

  return 'arbitrary';
}

1;
