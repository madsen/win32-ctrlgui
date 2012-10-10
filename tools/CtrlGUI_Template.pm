#---------------------------------------------------------------------
package tools::CtrlGUI_Template;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 08 Oct 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Pod::Loom template for Win32::CtrlGUI
#---------------------------------------------------------------------

our $VERSION = '0.31';

use 5.008;
use Moose;
extends 'Pod::Loom::Template::Default';
with 'Pod::Loom::Role::Extender';

#---------------------------------------------------------------------
sub section_AUTHOR
{
  my $self = shift;

  my $pod = $self->SUPER::section_AUTHOR(@_);

  my $add = "\nWin32::CtrlGUI is now maintained by\n";

  $pod =~ s/^(?=Christopher)/$add/m or die;

  $pod;
} # end section_AUTHOR

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;
