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
use Win32::CtrlGUI::Criteria::multi;

use strict;

package Win32::CtrlGUI::Criteria::and;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::Criteria::multi');

$VERSION='0.22';

sub _is_recognized {
  my $self = shift;

  scalar( grep {!$_} @{$self->{criteria_status}} ) and return 0;
  return $self->{criteria_status}->[0];
}

1;
