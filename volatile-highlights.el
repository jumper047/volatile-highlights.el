;; volatile-highlights.el -- Minor mode for visual feedback on some operations.

;; Copyright (C) 2001, 2010 K-taro Miyazaki, all rights reserved.

;; Author: K-talo Miyazaki <Keitaro dot Miyazaki at gmail dot com>
;; Created: 03 October 2001. (as utility functions in my `.emacs' file.)
;;          14 March   2010. (re-written as library `volatile-highlights.el')
;; Keywords: emulations convenience wp
;; Revision: $Id$
;; URL: http://www.emacswiki.org/emacs/download/volatile-highlights.e
;; GitHub: http://github.com/k-talo/volatile-highlights.el

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Overview
;; ========
;; This library provides minor mode `volatile-highlight-mode', which
;; brings visual feedback to some operations by highlighting portions
;; relating to the operations.
;;
;; All of highlights made by this library will be removed
;; when any new command is executed.
;;
;;
;; INSTALLING
;; ==========
;; To install this library, save this file to a directory in your
;; `load-path' (you can view the current `load-path' using "C-h v
;; load-path" within Emacs), then add the following line to your
;; .emacs start up file:
;;
;;    (require 'volatile-highlights)
;;    (volatile-highlights-mode t)
;;
;; USING
;; =====
;; To toggle volatile highlighting, type `M-x volatile-highlights-mode RET'.
;;
;; Currently, operations listed below will be highlighted While the minor mode
;; `volatile-highlights-mode' is on:
;;
;;    - `undo':
;;      Volatile highlights will be put on the text inserted by `undo'.
;;
;;    - `yank' and `yank-pop':
;;      Volatile highlights will be put on the text inserted by `yank'
;;      or `yank-pop'.
;;
;;    - `find-tag':
;;      Volatile highlights will be put on the tag name which was found
;;      by `find-tag'.
;;
;;    - `occur-mode-goto-occurrence' and `occur-mode-display-occurrence':
;;      Volatile highlights will be put on the occurrence which is selected
;;      by `occur-mode-goto-occurrence' or `occur-mode-display-occurrence'.
;;
;; Highlighting support for each commands can be turned on/off individually
;; via customization. Also check out the customization group
;;
;;   `M-x customize-group RET volatile-highlights RET'

;;; Change Log:

;;; Code:

(defconst vhl/version "1.0")

(eval-when-compile
  (require 'cl)
  (require 'easy-mmode))

(provide 'volatile-highlights)


;;;============================================================================
;;;
;;;  Faces.
;;;
;;;============================================================================

(defgroup volatile-highlights nil
  "Visual feedback on operations."
  :group 'editing)

(defface vhl/default-face
  '((t
     :inherit secondary-selection
     ))
  "Face used for volatile highlights."
  :group 'volatile-highlights)


;;;============================================================================
;;;
;;;  Minor Mode Definition.
;;;
;;;============================================================================
(easy-mmode-define-minor-mode
 volatile-highlights-mode "Minor mode for visual feedback on some operations."
 :global t
 :init-value nil
 :lighter " VHl"
 (if (or (not (boundp 'smooth-scroll-mode))
         smooth-scroll-mode)
     (vhl/load-extensions)
   (vhl/unload-extensions)))


;;;============================================================================
;;;
;;;  Public Functions/Commands.
;;;
;;;============================================================================

;;-----------------------------------------------------------------------------
;; (vhl/add BEG END &OPTIONAL BUF FACE) => VOID
;;-----------------------------------------------------------------------------
(defun vhl/add (beg end &optional buf face)
  "Add a volatile highlight to the buffer `BUF' at the position
specified by `BEG' and `END' using the face `FACE'.

When the buffer `BUF' is not specified or its value is `nil',
volatile highlight will be added to current buffer.

When the face `FACE' is not specified or its value is `nil',
the default face `vhl/default-face' will
be used as the value."
  (let* ((face (or face 'vhl/default-face))
		 (hl (vhl/.make-hl beg end buf face)))
	(setq vhl/.hl-lst
		  (cons hl vhl/.hl-lst))
	(add-hook 'pre-command-hook 'vhl/clear-all)))

;;-----------------------------------------------------------------------------
;; (vhl/clear-all) => VOID
;;-----------------------------------------------------------------------------
(defun vhl/clear-all ()
  "Clear all volatile highlights."
  (interactive)
  (while vhl/.hl-lst
	(vhl/.clear-hl (car vhl/.hl-lst))
	(setq vhl/.hl-lst
		  (cdr vhl/.hl-lst)))
	  (remove-hook 'pre-command-hook 'vhl/clear-all))

;;-----------------------------------------------------------------------------
;; (vhl/force-clear-all) => VOID
;;-----------------------------------------------------------------------------
(defun vhl/force-clear-all ()
  "Force clear all volatile highlights in current buffer."
  (interactive)
  (vhl/force-clear-all-hl))


;;;============================================================================
;;;
;;;  Private Variables.
;;;
;;;============================================================================

(defconst vhl/.xemacsp (string-match "XEmacs" emacs-version)
  "A flag if the emacs is xemacs or not.")

(defconst vhl/.hl-lst nil
  "List of volatile highlights.")


;;;============================================================================
;;;
;;;  Private Functions.
;;;
;;;============================================================================

;;-----------------------------------------------------------------------------
;; (vhl/.make-hl BEG END BUF FACE) => HIGHLIGHT
;;-----------------------------------------------------------------------------
(defun vhl/.make-hl (beg end buf face)
  "Make a volatile highlight at the position specified by `BEG' and `END'."
  (let (hl)
	(cond
	 (vhl/.xemacsp
	  ;; XEmacs
	  (setq hl (make-extent beg end buf))
	  (set-extent-face hl face)
	  (highlight-extent hl t)
	  (set-extent-property 'volatile-highlights t))
	 (t
	  ;; GNU Emacs
	  (setq hl (make-overlay beg end buf))
	  (overlay-put hl 'face face)
	  (overlay-put hl 'priority 1)
	  (overlay-put hl 'volatile-highlights t)))
	 hl))

;;-----------------------------------------------------------------------------
;; (vhl/.clear-hl HIGHLIGHT) => VOID
;;-----------------------------------------------------------------------------
(defun vhl/.clear-hl (hl)
  "Clear one highlight."
  (cond
   ;; XEmacs (not tested!)
   (vhl/.xemacsp
	(and (extentp hl)
		 (delete-extent hl)))
   ;; GNU Emacs
   (t
	(and (overlayp hl)
		 (delete-overlay hl)))))

;;-----------------------------------------------------------------------------
;; (vhl/.force-clear-all-hl) => VOID
;;-----------------------------------------------------------------------------
(defun vhl/.force-clear-all-hl ()
  "Force clear all volatile highlights in current buffer."
  (cond
   ;; XEmacs (not tested!)
   ((fboundp 'map-extents)
      (map-extents (lambda (hl maparg)
                     (and (extent-property hl 'volatile-highlights)
						  (vhl/.clear-hl hl)))))
   ;; GNU Emacs
   ((fboundp 'overlays-in)
	(save-restriction
	  (widen)
	  (mapcar (lambda (hl)
				(and (overlay-get hl 'volatile-highlights)
					 (vhl/.clear-hl hl)))
			  (overlays-in (point-min) (point-max)))))))


;;;============================================================================
;;;
;;;  Functions to manage extensions.
;;;
;;;============================================================================
(defvar vhl/.installed-extensions nil)

(defun vhl/install-extension (sym)
  (let ((fn-on  (intern (format "vhl/ext/%s/on" sym)))
        (fn-off (intern (format "vhl/ext/%s/off" sym)))
        (cust-name (intern (format "vhl/use-%s-extension-p" sym))))
    (pushnew sym vhl/.installed-extensions)
    (eval `(defcustom ,cust-name t
             ,(format "A flag if highlighting support for `%s' is on or not." sym)
             :type 'boolean
             :group 'volatile-highlights
             :set (lambda (sym-to-set val)
                    (set-default sym-to-set val)
                    (if val
                        (when volatile-highlights-mode
                          (vhl/load-extension sym-to-set))
                      (vhl/unload-extension sym-to-set)))))))

(defun vhl/load-extension (sym)
  (let ((fn-on  (intern (format "vhl/ext/%s/on" sym)))
        (cust-name (intern (format "vhl/use-%s-extension-p" sym))))
    (if (functionp fn-on)
        (when (and (boundp cust-name)
                   (eval cust-name))
          (apply fn-on nil))
      (message "[vhl] No load function for extension  `%s'" sym))))

(defun vhl/unload-extension (sym)
  (let ((fn-off (intern (format "vhl/ext/%s/off" sym))))
    (if (and (boundp cust-name)
             (functionp fn-off))
        (apply fn-off nil)
      (message "[vhl] No unload function for extension  `%s'" sym))))

(defun vhl/load-extensions ()
  (dolist (sym vhl/.installed-extensions)
    (vhl/load-extension sym)))

(defun vhl/unload-extensions ()
  (dolist (sym vhl/.installed-extensions)
    (vhl/unload-extension sym)))


;;;============================================================================
;;;
;;;  Utility functions/macros for extensions.
;;;
;;;============================================================================
(defun vhl/advice-defined-p (fn-name class ad-name)
  (and (ad-is-advised fn-name)
       (assq ad-name
             (ad-get-advice-info-field fn-name class))))

(defun vhl/disable-advice-if-defined (fn-name class ad-name)
  (when (vhl/advice-defined-p fn-name class ad-name)
	(ad-disable-advice fn-name class ad-name)
	(ad-activate fn-name)))

(defun vhl/.make-vhl-on-change (beg end len-removed)
  (let ((insert-p (zerop len-removed)))
    (when insert-p
      (vhl/add beg end))))

(defmacro vhl/give-advise-to-make-vhl-on-changes (fn-name)
  (let* ((ad-name (intern (concat "vhl/make-vhl-on-"
                                 (format "%s" fn-name)))))
    (or (symbolp fn-name)
        (error "vhl/give-advise-to-make-vhl-on-changes: `%s' is not type of symbol." fn-name))
    `(progn
       (defadvice ,fn-name (around
                              ,ad-name
                              (&rest args))
         (add-hook 'after-change-functions
                   'vhl/.make-vhl-on-change)
         (unwind-protect
             ad-do-it
           (remove-hook 'after-change-functions
                        'vhl/.make-vhl-on-change)))
       ;; Enable advice.
       (ad-enable-advice (quote ,fn-name) 'around (quote ,ad-name))
       (ad-activate (quote ,fn-name)))))

(defmacro vhl/cancel-advise-to-make-vhl-on-changes (fn-name)
  (let ((ad-name (intern (concat "vhl/make-vhl-on-"
                                 (format "%s" fn-name)))))
    `(vhl/disable-advice-if-defined (quote ,fn-name) 'around (quote ,ad-name))))


;;;============================================================================
;;;
;;;  Extensions.
;;;
;;;============================================================================

;;-----------------------------------------------------------------------------
;; Extension for supporting undo.
;;   -- Put volatile highlights on the text inserted by `undo'.
;;      (and may be `redo'...)
;;-----------------------------------------------------------------------------
(defun vhl/ext/undo/on ()
  "Turn on volatile highlighting for `undo'."
  (interactive)
  
  (vhl/give-advise-to-make-vhl-on-changes primitive-undo))

(defun vhl/ext/undo/off ()
  "Turn off volatile highlighting for `undo'."
  (interactive)

  (vhl/cancel-advise-to-make-vhl-on-changes primitive-undo))

(vhl/install-extension 'undo)


;;-----------------------------------------------------------------------------
;; Extension for supporting yank/yank-pop.
;;   -- Put volatile highlights on the text inserted by `yank' or `yank-pop'.
;;-----------------------------------------------------------------------------
(defun vhl/ext/yank/on ()
  "Turn on volatile highlighting for `yank' and `yank-pop'."
  (interactive)

  (vhl/give-advise-to-make-vhl-on-changes yank)
  (vhl/give-advise-to-make-vhl-on-changes yank-pop))

(defun vhl/ext/yank/off ()
  "Turn off volatile highlighting for `yank' and `yank-pop'."
  (interactive)

  (vhl/cancel-advise-to-make-vhl-on-changes yank)
  (vhl/cancel-advise-to-make-vhl-on-changes yank-pop))

(vhl/install-extension 'yank)


;;-----------------------------------------------------------------------------
;; Extension for supporting etags.
;;   -- Put volatile highlights on the tag name which was found by `find-tag'.
;;-----------------------------------------------------------------------------
(defun vhl/ext/etags/on ()
  "Turn on volatile highlighting for `etags'."
  (interactive)
  (require 'etags)

  (defadvice find-tag (after vhl/ext/etags/make-vhl-after-find-tag (tagname &optional next-p regexp-p))
    (let ((pos (point))
          (len (length tagname)))
      (save-excursion
        (search-forward tagname)
        (vhl/add (- (point) len) (point)))))
  (ad-activate 'find-tag))

(defun vhl/ext/etags/off ()
  "Turn off volatile highlighting for `etags'."
  (interactive)
  (vhl/disable-advice-if-defined
   'find-tag 'after 'vhl/ext/etags/make-vhl-after-find-tag))

(vhl/install-extension 'etags)


;;-----------------------------------------------------------------------------
;; Extension for supporting occur.
;;   -- Put volatile highlights on occurrence which is selected by
;;      `occur-mode-goto-occurrence' or `occur-mode-display-occurrence'.
;;-----------------------------------------------------------------------------
(defun vhl/ext/occur/on ()
  "Turn on volatile highlighting for `occur'."
  (interactive)
  
  (lexical-let ((*occur-str* nil))
    (defun vhl/ext/occur/.pre-hook-fn ()
      (save-excursion
        (let* ((bol (progn (beginning-of-line) (point)))
               (eol (progn (end-of-line) (point)))
               (bos (text-property-any bol eol 'occur-match t))
               (eos (next-single-property-change bos 'occur-match)))
          (setq *occur-str* (and bos eos
                                 (buffer-substring bos eos))))))

    (defun vhl/ext/occur/.post-hook-fn ()
      (let ((marker (and *occur-str*
                         (get-text-property 0 'occur-target *occur-str*))))
        (when marker
          (with-current-buffer (marker-buffer marker)
            (let* ((bos (marker-position marker))
                   (eos (+ bos (length *occur-str*))))
              (mapcar (lambda (ov)
                        (when (overlay-get ov 'invisible)
                          (save-excursion
                            (goto-char (overlay-start ov))
                            (beginning-of-line)
                            (setq bos (min bos (point)))
                            (goto-char (overlay-end ov))
                            (end-of-line)
                            (setq eos (max eos (point)))
                            )))
                      (overlays-at bos))
              (vhl/add bos eos))))))
    
      
    (defadvice occur-mode-goto-occurrence (before vhl/ext/occur/pre-hook (&optional event))
      (vhl/ext/occur/.pre-hook-fn))
    (defadvice occur-mode-goto-occurrence (after vhl/ext/occur/post-hook (&optional event))
      (vhl/ext/occur/.post-hook-fn))

    (defadvice occur-mode-display-occurrence (before vhl/ext/occur/pre-hook ())
      (vhl/ext/occur/.pre-hook-fn))
    (defadvice occur-mode-display-occurrence (after vhl/ext/occur/post-hook ())
      (vhl/ext/occur/.post-hook-fn))

    (defadvice occur-mode-goto-occurrence-other-window (before vhl/ext/occur/pre-hook ())
      (vhl/ext/occur/.pre-hook-fn))
    (defadvice occur-mode-goto-occurrence-other-window (after vhl/ext/occur/post-hook ())
      (vhl/ext/occur/.post-hook-fn))
  
    (ad-activate 'occur-mode-goto-occurrence)
    (ad-activate 'occur-mode-display-occurrence)
    (ad-activate 'occur-mode-goto-occurrence-other-window)))

(defun vhl/ext/occur/off ()
  "Turn off volatile highlighting for `occur'."
  (interactive)

  (vhl/disable-advice-if-defined
   'occur-mode-goto-occurrence 'before 'vhl/ext/occur/pre-hook)
  (vhl/disable-advice-if-defined
   'occur-mode-goto-occurrence 'after 'vhl/ext/occur/post-hook)

  (vhl/disable-advice-if-defined
   'occur-mode-display-occurrence 'before 'vhl/ext/occur/pre-hook)
  (vhl/disable-advice-if-defined
   'occur-mode-display-occurrence 'after 'vhl/ext/occur/post-hook)

  (vhl/disable-advice-if-defined
   'occur-mode-goto-occurrence-other-window 'before 'vhl/ext/occur/pre-hook)
  (vhl/disable-advice-if-defined
   'occur-mode-goto-occurrence-other-window 'after 'vhl/ext/occur/post-hook))

(vhl/install-extension 'occur)

;;; volatile-highlights.el ends here
