###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################
use Win32::CtrlGUI;

use strict;

package Win32::CtrlGUI::Criteria;
use vars qw($VERSION);

use overload
	'""'  => sub {$_[0]->stringify};

$VERSION='0.31';

=head1 NAME

Win32::CtrlGUI::Criteria - an OO interface for expressing state criteria

=head1 SYNOPSIS

  use Win32::CtrlGUI::Criteria

  my $criteria = Win32::CtrlGUI::Criteria->new(pos => qr/Notepad/);


  use Win32::CtrlGUI::State

  my $state = Win32::CtrlGUI::State->new(atom => criteria => [pos => qr/Notepad/], action => "!fo");

=head1 DESCRIPTION

C<Win32::CtrlGUI::Criteria> objects represent state criteria, and are used by
the C<Win32::CtrlGUI::State> system to determine when a state has been entered.
There are three main subclasses - C<Win32::CtrlGUI::Criteria::pos>,
C<Win32::CtrlGUI::Criteria::neg>, and C<Win32::CtrlGUI::Criteria::arbitrary>.
These will be discussed in the documentation for C<Win32::CtrlGUI::Criteria>,
rather than in the implementation classes.

=head1 METHODS

=head2 new

The first parameter to the C<new> method is the subclass to create - C<pos>,
C<neg>, or C<arbitrary>. The remaining parameters are passed to the C<new>
method for that class.  Thus, C<Win32::CtrlGUI::Criteria-E<gt>new(pos =>
qr/Notepad/)> is the same as
C<Win32::CtrlGUI::Criteria::pos-E<gt>new(qr/Notepad/)>.

The passed parameters for the C<pos> and C<neg> subclasses are the window
criteria and childcriteria, with the same options available as for
C<Win32::CtrlGUI::wait_for_window>.  The C<pos> subclass will return true (i.e.
the criteria are met) when a window matching those criteria exists.  The C<neg>
subclass will return true when no windows matching the passed criteria exist.
The C<pos> subclass will return a C<Win32::CtrlGUI::Window> object for the
matching window when it returns true.

The C<arbitrary> subclass takes a code reference and a list of hash parameters.
The hash parameters will be added to the C<Win32::CtrlGUI::Criteria::arbitrary>
object, and the code reference will be passed a reference to the
C<Win32::CtrlGUI::Criteria::arbitrary> object at run-time.  This enables the
code reference to use the C<Win32::CtrlGUI::Criteria::arbitrary> to store
state.  The code reference should return true when evaluated if the state
criteria have been met.

=cut

sub new {
	my $class = shift;
	my $type = shift;

	$class = "Win32::CtrlGUI::Criteria::".$type;
	return $class->new(@_);
}

=head2 stringify

The C<stringify> method is called by the overloaded stringification operator
and should return a printable string suitable for debug work.

=cut

sub stringify {
	my $self = shift;

	my $subclass = ref $self;
	$subclass =~ s/^.*:://;
	my $retval = "$subclass:[";

	if (ref $self->{criteria} eq 'Regexp') {
		$retval .= "/".$self->{criteria}."/";
	} elsif (ref $self->{criteria} eq 'CODE') {
		$retval .= 'CODE';
	} elsif (ref $self->{criteria} eq 'SCALAR') {
		$retval .= "\\'".${$self->{criteria}}."'";
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

	$retval .= "]";
	return $retval;
}

sub tagged_stringify {
	my $self = shift;

	return [$self->stringify, 'default'];
}

=head2 is_recognized

The C<is_recognized> method is called to determine if the criteria are
currently being met.

=cut

sub is_recognized {
	my $self = shift;

	die "Win32::CtrlGUI::Criteria::is_recognized is an abstract method and needs to be overriden.\n";
}

sub reset {
	my $self = shift;

}



###########################################################################
# Win32::CtrlGUI::Criteria::arbitrary
###########################################################################

package Win32::CtrlGUI::Criteria::arbitrary;
@Win32::CtrlGUI::Criteria::arbitrary::ISA = 'Win32::CtrlGUI::Criteria';

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


###########################################################################
# Win32::CtrlGUI::Criteria::neg
###########################################################################

package Win32::CtrlGUI::Criteria::neg;
@Win32::CtrlGUI::Criteria::neg::ISA = 'Win32::CtrlGUI::Criteria';

sub new {
	my $class = shift;

	my $self = {
		criteria => $_[0],
		childcriteria => $_[1]
	};

	bless $self, $class;
	return $self;
}

sub is_recognized {
	my $self = shift;

	return scalar(Win32::CtrlGUI::get_windows($self->{criteria}, $self->{childcriteria}, 1)) ? 0 : 1;
}


###########################################################################
# Win32::CtrlGUI::Criteria::pos
###########################################################################

package Win32::CtrlGUI::Criteria::pos;
@Win32::CtrlGUI::Criteria::pos::ISA = 'Win32::CtrlGUI::Criteria';

sub new {
	my $class = shift;

	my $self = {
		criteria => $_[0],
		childcriteria => $_[1]
	};

	bless $self, $class;
	return $self;
}

sub is_recognized {
	my $self = shift;

	return Win32::CtrlGUI::get_windows($self->{criteria}, $self->{childcriteria}, 1);
}




###########################################################################
# Win32::CtrlGUI::Criteria::multi
###########################################################################

package Win32::CtrlGUI::Criteria::multi;
use vars qw($VERSION @ISA);

@ISA = ('Win32::CtrlGUI::Criteria');

$VERSION='0.31';

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

###########################################################################
# Win32::CtrlGUI::Criteria::and
###########################################################################

package Win32::CtrlGUI::Criteria::and;
@Win32::CtrlGUI::Criteria::and::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	scalar( grep {!$_} @{$self->{criteria_status}} ) and return 0;
	return $self->{criteria_status}->[0];
}

###########################################################################
# Win32::CtrlGUI::Criteria::nand
###########################################################################

package Win32::CtrlGUI::Criteria::nand;
@Win32::CtrlGUI::Criteria::nand::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	return scalar( grep {$_} @{$self->{criteria_status}} ) ? 0 : 1;
}

###########################################################################
# Win32::CtrlGUI::Criteria::or
###########################################################################

package Win32::CtrlGUI::Criteria::or;
@Win32::CtrlGUI::Criteria::or::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	foreach my $status (@{$self->{criteria}}) {
		$status and return $status;
	}
	return 0;
}

###########################################################################
# Win32::CtrlGUI::Criteria::xor
###########################################################################

package Win32::CtrlGUI::Criteria::xor;
@Win32::CtrlGUI::Criteria::xor::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	my $retval;
	my $state;
	foreach my $status (@{$self->{criteria_status}}) {
		$status and $state = !$state;
		defined $retval or $retval = $status;
	}
	$state and return $retval;
	return 0;
}



1;
