use Win32::CtrlGUI;
use Win32::CtrlGUI::State;

use Tk;
use Tk::Dialog;
use Tk::HList;
use Tk::ROText;
use Win32::API;

use strict;

package Win32::CtrlGUI::State::DebugTk;
use vars qw($VERSION $mw $root_bookkeeper $hlist $hlist_stuff $font $statusarea $paused $pausebutton $resumebutton $debugmode);

&init;

=head1 Rudimentary Instructions

If you want to try a cool demo, simply close all open Notepad windows and then open a single,
empty Notepad window.  Then run demotk.pl.  Resize the Tk window that pops up so you can see
stuff.  Then do the same thing, but first open demotk.pl in Notepad and add a single carriage
return to the end of the file.  Then play with fresh Notepad windows that have random text in them
(the contents will get save to C:\Temp\saved.txt, so if you have a file by that name in existence,
be careful:).

The color scheme is:
  Red and bold: active state
  Black and bold: possible next state
  Black and not-bold: possible future state (but not possible next state)
  Black and crossed out: state will never be reached
  Dark red: state has been executed

Also notice that you can pause and resume scripts.  You have to hit exit to terminate the script,
but if you don't set C<$Win32::CtrlGUI::State::DebugTk::debugmode> to 1, it will terminate as soon
as the Win32::CtrlGUI::State stuff is finished, making it ideal for using with production scripts.

Also, try opening the Notepad window, waiting for the script to recognize it (state goes red), but
then close it before it sends the text.  Notice that it halts the script and alerts you.

=cut


sub newdo {
  my $class = shift;

  $root_bookkeeper = Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new(@_));

  $Win32::CtrlGUI::State::atom::action_error_handler = sub {
    my($errormsg) = @_;
    &update_status(1);
    $mw->deiconify;
    $mw->update;
    my $dialog = $mw->Dialog(-text => "The following exception was thrown:\n$errormsg",
                             -bitmap => 'error', -title => 'Action Error',
                             -default_button => 'OK', -buttons => [qw/OK/]
                            );
    $dialog->Show();
  };

  my $old_debug_print = \&Win32::CtrlGUI::State::debug_print;
  *Win32::CtrlGUI::State::debug_print = sub {
      my $self = shift;
      my($debug_level, $text) = @_;

      &append_to_status_area($text);
    };

  foreach my $widget ($mw->children) {
    $widget->destroy;
  }

  $hlist = $mw->Scrolled('HList', -scrollbars => 'se', -drawbranch => 1, -separator => '/',
             -indent => 15)->pack(-side => 'top', -expand => 1, -fill => 'both');

  my $exit_trigger = 0;
  $mw->protocol(WM_DELETE_WINDOW => sub {$exit_trigger = 1});

  $statusarea = $mw->Scrolled('ROText', -scrollbars => 'se', -width => 140, -height => 9)->pack(-side => 'top', -fill => 'both');
  $mw->Button(-text => 'Exit', -command => sub {$exit_trigger = 1})->pack(-side => 'right', -padx => 5, -pady => 5);
  $resumebutton = $mw->Button(-text => 'Resume', -command => sub {&update_status('running')})->pack(-side => 'right', -padx => 5, -pady => 5);
  $pausebutton = $mw->Button(-text => 'Pause', -command => sub {&update_status('paused')})->pack(-side => 'right', -padx => 5, -pady => 5);
  &update_status('running');

  $mw->iconify;
  $mw->title("Win32::CtrlGUI::State Debugger - $0");
  $mw->update;
  Win32::API->new("user32","SetWindowPos",[qw(N N N N N N N)],'N')->Call(hex($mw->frame()),-1,0,0,0,0,3);
  $debugmode and $mw->deiconify;


  &add_state('root', $root_bookkeeper);

  my $last_sweep = Win32::GetTickCount();
  my $intvl = $root_bookkeeper->{state}->wait_intvl;
  while (1) {
    if ($last_sweep + $intvl < Win32::GetTickCount()) {
      unless ($paused) {
        if ($root_bookkeeper->bk_status eq 'pfs') {
          $root_bookkeeper->bk_set_status('pcs');
        }
        if ($root_bookkeeper->bk_status eq 'pcs') {
          $root_bookkeeper->is_recognized and $root_bookkeeper->bk_set_status('active');
        }
        if ($root_bookkeeper->bk_status eq 'active') {
          $root_bookkeeper->do_action_step;
        }
        if ($root_bookkeeper->state =~ /^done|fail$/) {
          $root_bookkeeper->{executed}++;
          $root_bookkeeper->bk_set_status('never');
          &update_status('finished');
          $debugmode or $exit_trigger = 1;
        }
        &refresh_states('root', 'active');
      }
      $last_sweep = Win32::GetTickCount();
    }

    $mw->update;
    $exit_trigger and last;
    Win32::Sleep(100);
  }

  $Win32::CtrlGUI::State::atom::action_error_handler = undef;
  *Win32::CtrlGUI::State::debug_print = $old_debug_print;
}

sub update_status {
  my($status) = @_;

  $status =~ /^running|paused|finished$/ or die "Illegal status value '$status' passed.\n";
  $paused = $status eq 'running' ? 0 : 1;
  $pausebutton->configure(-state => $status eq 'running' ? 'normal' : 'disabled');
  $resumebutton->configure(-state => $status eq 'paused' ? 'normal' : 'disabled');
  &append_to_status_area("Script $status");
}

sub append_to_status_area {
  my($text) = @_;

  $statusarea->insert('end', $text ? (split(/\s+/,localtime(time)))[3]." $text\n" : "\n");
  $statusarea->see('end');
}

sub add_state {
  my($path, $bookkeeper) = @_;

  my $text;
  if (UNIVERSAL::isa($bookkeeper->{state}, 'Win32::CtrlGUI::State::multi')) {
    ($text = ref($bookkeeper->{state})) =~ s/^Win32::CtrlGUI::State:://;
  } else {
    $text = "criteria => $bookkeeper->{state}->{criteria}\naction => $bookkeeper->{state}->{action}";
  }
  my $widget = $hlist->Label(-text => $text, -anchor => 'w', -font => $font, -justify => 'left');
  $hlist->add($path, -itemtype => 'window', -widget => $widget);
  $hlist_stuff->{$path} = {widget => $widget, bookkeeper => $bookkeeper};
  if (UNIVERSAL::isa($bookkeeper->{state}, 'Win32::CtrlGUI::State::multi')) {
    my $i = 0;
    foreach my $substate ($bookkeeper->{state}->get_states) {
      &add_state("$path/".$i++, $substate);
    }
  }
}

sub refresh_states {
  my($path, $pstatus) = @_;

  my $stuff = $hlist_stuff->{$path};
  my $status = $stuff->{bookkeeper}->bk_status_given($pstatus);
  if ($status ne $stuff->{old_status}) {
    if ($status eq 'active') {
      $stuff->{widget}->configure(-foreground => 'red', -font => [@{$font}, 'bold']);
      $hlist->yview($path);
    } elsif ($status eq 'pcs') {
      $stuff->{widget}->configure(-foreground => 'black', -font => [@{$font}, 'bold']);
    } elsif ($status eq 'pfs') {
      $stuff->{widget}->configure(-foreground => 'black', -font => [@{$font}]);
    } elsif ($status eq 'never') {
      if ($stuff->{bookkeeper}->{executed}) {
        $stuff->{widget}->configure(-foreground => 'dark red', -font => [@{$font}]);
      } else {
        $stuff->{widget}->configure(-foreground => 'black', -font => [@{$font}, 'overstrike']);
      }
    } else {
      die "ARGH!";
    }
    $stuff->{old_status} = $status;
  }


  my(@children) = $hlist->info('children', $path);

  if ($status eq 'active' && scalar(grep {$hlist_stuff->{$_}->{bookkeeper}->bk_status eq 'active'} @children)) {
    $status = 'pfs';
  }

  foreach my $subpath (@children) {
    &refresh_states($subpath, $status);
  }
}

sub init {
  $mw = MainWindow->new;
  $mw->withdraw();
  $font = [qw(Arial 8)];
  $mw->geometry("700x500");
  $debugmode = 0;
}

1;
