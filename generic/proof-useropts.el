;;; proof-useropts.el --- Global user options for Proof General

;; This file is part of Proof General.

;; Portions © Copyright 1994-2012  David Aspinall and University of Edinburgh
;; Portions © Copyright 2003-2021  Free Software Foundation, Inc.
;; Portions © Copyright 2001-2017  Pierre Courtieu
;; Portions © Copyright 2010, 2016  Erik Martin-Dorel
;; Portions © Copyright 2011-2013, 2016-2017  Hendrik Tews
;; Portions © Copyright 2015-2017  Clément Pit-Claudel

;; Author:      David Aspinall <David.Aspinall@ed.ac.uk> and others

;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;;
;; User options for Proof General.
;;
;; The following variables are user options for Proof General.
;;
;; They appear in the 'proof-user-options' customize group and should
;; *not* normally be touched by prover specific code.
;;

;;; Code:

(defgroup proof-user-options nil
  "User options for Proof General."
  :group 'proof-general
  :prefix "proof-")

;;
;; Take action when dynamically adjusting customize values
;;
(defun proof-set-value (sym value)
  "Set a customize variable using `set-default' and a function.
We first call `set-default' to set SYM to VALUE.
Then if there is a function SYM (i.e. with the same name as the
variable SYM), it is called to take some dynamic action for the new
setting.

If there is no function SYM, we try stripping
`proof-assistant-symbol' and adding \"proof-\" instead to get
a function name.  This extends proof-set-value to work with
generic individual settings.

The dynamic action call only happens when values *change*: as an
approximation we test whether proof-config is fully-loaded yet."
  (set-default sym value)
  (when (and
	 (not noninteractive)
	 (not (bound-and-true-p byte-compile-current-file)) ;FIXME: Yuck!
	 (featurep 'pg-custom)
	 (featurep 'proof-config))
      (if (fboundp sym)
	  (funcall sym)
	(if (boundp 'proof-assistant-symbol)
	    (if (> (length (symbol-name sym))
		   (+ 3 (length (symbol-name proof-assistant-symbol))))
		(let ((generic
		       (intern
			(concat "proof"
				(substring (symbol-name sym)
					   (length (symbol-name
						    proof-assistant-symbol)))))))
		  (if (fboundp generic)
		      (funcall generic))))))))

(defcustom proof-electric-terminator-enable nil
  "*If non-nil, use electric terminator mode.
If electric terminator mode is enabled, pressing a terminator will
automatically issue `proof-assert-next-command' for convenience,
to send the command straight to the proof process.  If the command
you want to send already has a terminator character, you don't
need to delete the terminator character first.  Just press the
terminator somewhere nearby.  Electric!"
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-next-command-insert-space t
  "*If non-nil, PG will use heuristics to insert newlines or spaces in scripts.
In particular, if electric terminator is switched on, spaces or newlines will
be inserted as the user types commands to the prover."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-toolbar-enable t
  "*If non-nil, display Proof General toolbar for script buffers."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-imenu-enable nil
  "*If non-nil, display Imenu menu of items for script buffers."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-omit-proofs-option nil
  "Set to t to omit complete opaque proofs for speed reasons.
When t, complete opaque proofs in the asserted region are not
sent to the proof assistant (and thus not checked).  For files
with big proofs this can drastically reduce the processing time
for the asserted region at the cost of not checking the proofs.
For partial and non-opaque proofs in the asserted region all
proof commands are sent to the proof assistant.

Using a prefix argument for `proof-goto-point' (\\[proof-goto-point])
or `proof-process-buffer' (\\[proof-process-buffer]) temporarily
disables omitting proofs."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-check-annotate-position 'theorem
  "Line for annotating proofs with \"PASS\" or \"FAIL\" comments.
This option determines the line where `proof-check-annotate' puts
comments with \"PASS\" and \"FAIL\". Value `'theoren' uses the
first line of the second last statement before the start of the
opaque proof, which corresponds to the line containing a Theorem
keyword for Coq. Value `'proof-using' uses the first line of the
last statement before the opaque proof, which corresponds to the
Proof using line for Coq."
  :type
  '(radio
    (const :tag "line of theorem statement" theorem)
    (const :tag "line before the proof (Proof using for Coq)" proof-using))
  :safe (lambda (v) (or (eq v 'theorem) (eq v 'proof-using))))

(defcustom proof-check-annotate-right-margin nil
  "Right margin for \"PASS\" and \"FAIL\" comments.
This option determines the right margin to which
`proof-check-annotate' right-aligns the comments with \"PASS\"
and \"FAIL\". If nil, the value of `fill-column' is used."
  :type
  '(choice
    (const :tag "use value of `fill-column'" nil)
    (integer :tag "right margin"))
  :safe (lambda (v) (or (eq v nil) (integerp v))))

(defcustom pg-show-hints t
  "*Whether to display keyboard hints in the minibuffer."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-shell-quiet-errors t
  "If non-nil, be quiet about errors from the prover.
Normally error messages cause a beep.  Set this to t to prevent that."
  :type 'boolean
  :group 'proof-user-options)

;; FIXME: next one could be integer value for catchup delay
(defcustom proof-trace-output-slow-catchup t
  "*If non-nil, try to redisplay less often during frequent trace output.
Proof General will try to configure itself to update the display
of tracing output infrequently when the prover is producing rapid,
perhaps voluminous, output.  This counteracts the situation that
otherwise Emacs may consume more CPU than the proof assistant,
trying to fontify and refresh the display as fast as output appears."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-strict-state-preserving t
  "*Whether Proof General is strict about the state preserving test.
Proof General lets the user send arbitrary commands to the proof
engine with `proof-minibuffer-cmd'.  To attempt to preserve
synchronization, there may be a test `proof-state-preserving-p'
configured which prevents the user issuing certain commands
directly (instead, they may only be entered as part of the script).

Clever or arrogant users may want to avoid this test, which is
done if this `proof-strict-state-preserving' is turned off (nil)."
  :type  'boolean
  :group 'proof-user-options)

(defcustom proof-strict-read-only 'retract
  "*Whether Proof General is strict about the read-only region in buffers.
If non-nil, an error is given when an attempt is made to edit the
read-only region, except for the special value 'retract which means
undo first.  If nil, Proof General is more relaxed (but may give
you a reprimand!)."
  :type  '(choice
	   (const :tag "Do not allow edits" t)
	   (const :tag "Allow edits but automatically retract first" retract)
	   (const :tag "Allow edits without restriction" nil))
  :set   'proof-set-value
  :group 'proof-user-options)

(defcustom proof-three-window-enable t
  "*Whether response and goals buffers have dedicated windows.
If non-nil, Emacs windows displaying messages from the prover will not
be switchable to display other windows.

This option can help manage your display.

Setting this option triggers a three-buffer mode of interaction where
the goals buffer and response buffer are both displayed, rather than
the two-buffer mode where they are switched between.  It also prevents
Emacs automatically resizing windows between proof steps.

If you use several frames (the same Emacs in several windows on the
screen), you can force a frame to stick to showing the goals or
response buffer.

This option only takes effect if the frame height is bigger than
4 times `window-min-height' (i.e., bigger than 16 with default
values) because there must be enough space to create 3 windows."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-multiple-frames-enable nil
  "*Whether response and goals buffers have separate frames.
If non-nil, Emacs will make separate frames (screen windows) for
the goals and response buffers, by altering the Emacs variable
`special-display-regexps'."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

; Pierre: I really don't think this option is useful. remove?
(defcustom proof-layout-windows-on-visit-file nil
  "*Whether to eagerly create auxiliary buffers and display windows.
If non-nil, the output buffers are created and (re-)displayed as soon
as a proof script file is visited.  Otherwise, the buffers are created
and displayed lazily.  See `proof-layout-windows'."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-three-window-mode-policy 'smart
  "*Window splitting policy for three window mode.
- If 'vertical then never split horizontally.
- If 'horizontal then always have scripting buffer on the right
  and goal and response buffers on the left (one above the
  other).
- If 'smart or anything else: 'horizontal when the window
  is wide enough and 'vertical otherwise.  The width threshold
  is given by `split-width-threshold'.

  See `proof-layout-windows'."
  :type '(choice
	  (const :tag "Adapt to current frame width" smart)
	  (const :tag "Horizontal (three columns)" horizontal)
	  (const :tag "Horizontal (two columns)" hybrid)
	  (const :tag "Vertical" vertical))
  :group 'proof-user-options)


(defcustom proof-delete-empty-windows nil
  "*If non-nil, automatically remove windows when they are cleaned.
For example, at the end of a proof the goals buffer window will
be cleared; if this flag is set it will automatically be removed.
If you want to fix the sizes of your windows you may want to set this
variable to 'nil' to avoid windows being deleted automatically.
If you use multiple frames, only the windows in the currently
selected frame will be automatically deleted."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-shell-kill-function-also-kills-associated-buffers t
  "*If non-nil, when `proof-shell-kill-function' is called, clean up buffers.
For example, `proof-shell-kill-function' is called when buffers
are retracted when switching between proof script files.  It may
make sense to set this to nil when
`proof-multiple-frames-enable' is set to prevent proof general
from killing frames that you want to be managed by a window
manager instead of within Emacs."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-shrink-windows-tofit nil
  "*If non-nil, automatically shrink output windows to fit contents.
In single-frame mode, this option will reduce the size of the
goals and response windows to fit their contents."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-auto-raise-buffers t
  "*If non-nil, automatically raise buffers to display latest output.
If this is not set, buffers and windows will not be managed by
Proof General."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-colour-locked t
  "*If non-nil, colour the locked region with `proof-locked-face'.
If this is not set, buffers will have no special face set
on locked regions."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-sticky-errors nil
  "*If non-nil, add highlighting to regions which gave errors.
Intended to complement `proof-colour-locked'."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-query-file-save-when-activating-scripting
  t
"*If non-nil, query user to save files when activating scripting.

Often, activating scripting or executing the first scripting command
of a proof script will cause the proof assistant to load some files
needed by the current proof script.  If this option is non-nil, the
user will be prompted to save some unsaved buffers in case any of
them corresponds to a file which may be loaded by the proof assistant.

You can turn this option off if the save queries are annoying, but
be warned that with some proof assistants this may risk processing
files which are out of date with respect to the loaded buffers!"
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-prog-name-ask
  nil
  "*If non-nil, query user which program to run for the inferior process."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-prog-name-guess
  nil
  "*If non-nil, use `proof-guess-command-line' to guess `proof-prog-name'.
This option is compatible with `proof-prog-name-ask'.
No effect if `proof-guess-command-line' is nil."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-tidy-response
  t
  "*Non-nil indicates that the response buffer should be cleared often.
The response buffer can be set either to accumulate output, or to
clear frequently.

With this variable non-nil, the response buffer is kept tidy by
clearing it often, typically between successive commands (just like the
goals buffer).

Otherwise the response buffer will accumulate output from the prover."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-keep-response-history
  nil
  "*Whether to keep a browsable history of responses.
With this feature enabled, the buffers used for prover responses will have a
history that can be browsed without processing/undoing in the prover.
\(Changes to this variable take effect after restarting the prover)."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom pg-input-ring-size 32
  "*Size of history ring of previous successfully processed commands."
  :type 'integer
  :group 'proof-user-options)

(defcustom proof-general-debug nil
  "*Non-nil to run Proof General in debug mode.
This changes some behaviour (e.g. markup stripping) and displays
debugging messages in the response buffer.  To avoid erasing
messages shortly after they're printed, set `proof-tidy-response' to nil.
This is only useful for PG developers."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-use-parser-cache t
  "*Non-nil to use a simple parsing cache.
This can be helpful when editing and reprocessing large files.
This variable exists to disable the cache in case of problems."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-follow-mode 'locked
  "*Choice of how point moves with script processing commands.
One of the symbols: 'locked, 'follow, 'followdown, 'ignore.

If 'locked, point sticks to the end of the locked region.
If 'follow, point moves just when needed to display the locked region end.
If 'followdown, point if necessary to stay in writable region
If 'ignore, point is never moved after movement commands or on errors.

If you choose 'ignore, you can find the end of the locked using
\\[proof-goto-end-of-locked]"
  :type '(choice
	  (const :tag "Follow locked region" locked)
	  (const :tag "Follow locked region down" followdown)
	  (const :tag "Keep locked region displayed" follow)
	  (const :tag "Never move" ignore))
  :group 'proof-user-options)

;; Note: the auto action might be improved a bit: for example, when
;; scripting is turned off because another buffer is being retracted,
;; we almost certainly want to retract the currently edited buffer as
;; well (use case is somebody realising a change has to made in an
;; ancestor file).  And in that case (supposing file being unlocked is
;; an ancestor), it seems unlikely that we need to query for saves.
(defcustom proof-auto-action-when-deactivating-scripting nil
  "*If 'retract or 'process, do that when deactivating scripting.

With this option set to 'retract or 'process, when scripting
is turned off in a partly processed buffer, the buffer will be
retracted or processed automatically.

With this option unset (nil), the user is questioned instead.

Proof General insists that only one script buffer can be partly
processed: all others have to be completely processed or completely
unprocessed.  This is to make sure that handling of multiple files
makes sense within the proof assistant.

NB: A buffer is completely processed when all non-whitespace is
locked (coloured blue); a buffer is completely unprocessed when there
is no locked region.

For some proof assistants (such as Coq) fully processed buffers make
no sense.  Setting this option to 'process has then the same effect
as leaving it unset (nil).  (This behaviour is controlled by
`proof-no-fully-processed-buffer'.)"
  :type '(choice
	  (const :tag "No automatic action; query user" nil)
	  (const :tag "Automatically retract" retract)
	  (const :tag "Automatically process" process))
  :group 'proof-user-options)

(defcustom proof-rsh-command nil
  "*Shell command prefix to run a command on a remote host.
For example,

   ssh bigjobs

Would cause Proof General to issue the command `ssh bigjobs coqtop'
to start Coq remotely on our large compute server called `bigjobs'.

The protocol used should be configured so that no user interaction
\(passwords, or whatever) is required to get going.  For proper
behaviour with interrupts, the program should also communicate
signals to the remote host."
  :type '(choice string (const nil))
  :group 'proof-user-options)

(defcustom proof-disappearing-proofs nil
  "*Non-nil causes Proof General to hide proofs as they are completed."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-full-annotation nil
  "*Non-nil causes Proof General to record output for all proof commands.
Proof output is recorded as it occurs interactively; normally if
many steps are taken at once, this output is suppressed.  If this
setting is used to enable it, the proof script can be annotated
with full details.  See also `proof-output-tooltips' to enable
automatic display of output on mouse hovers."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-output-tooltips t
  "*Non-nil causes Proof General to add tooltips for prover output.
Hovers will be added when this option is non-nil.  Prover outputs
can be displayed when the mouse hovers over the region that
produced it and output is available (see `proof-full-annotation').
If output is not available, the type of the output region is displayed.
Changes of this option will not be reflected in already-processed
regions of the script."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-minibuffer-messages nil
  "*Non-nil causes Proof General to issue minibuffer messages.
Minibuffer messages are issued when urgent messages are seen
from the prover.  You can disable the display of these if they
are distracting or too frequent."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-autosend-enable nil
  "*Non-nil causes Proof General to automatically process the script."
  :type 'boolean
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-autosend-delay 0.8
  "*Delay before autosend starts sending commands."
  :type 'float
  :set 'proof-set-value
  :group 'proof-user-options)

(defcustom proof-autosend-all nil
  "*If non-nil, auto send will process whole buffer; otherwise just the next command."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-fast-process-buffer
  (or (featurep 'ns) ; Mac OS X
      ; or Windows (speed up TBC, see Trac #308)
      (memq system-type '(windows-nt ms-dos cygwin)))
  "*If non-nil, `proof-process-buffer' will use a busy wait to process.
This results in faster processing, but disables simultaneous user interaction.
This setting gives a big speed-up on certain platforms/Emacs ports, for example
Mac OS X."
  :type 'boolean
  :group 'proof-user-options)

(defcustom proof-splash-enable t
  "*If non-nil, display a splash screen when Proof General is loaded.
See `proof-splash-time' for configuring the time that the splash
screen is shown."
  :type 'boolean
  :group 'proof-user-options)



(provide 'proof-useropts)

;;; proof-useropts.el ends here
