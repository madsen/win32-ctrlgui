use Win32::CtrlGUI;
use Win32::CtrlGUI::State::DebugTk;

$Win32::CtrlGUI::State::action_delay = 5;

$Win32::CtrlGUI::State::DebugTk::debugmode = 1;
Win32::CtrlGUI::State::DebugTk->newdo(
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
                  action => "!n{1}".Win32::GetCwd()."\\demotk.pl{1}{HOME}{2}{ENTER}"],
    ],

    dialog => [criteria => [pos => qr/Notepad/],
                action => "!fx"],
  ]
);
