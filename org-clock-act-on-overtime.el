;;; org-clock-act-on-overtime.el --- Do things when org-clock is overtime. -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 Cash Prokop-Weaver
;;
;; Author: Cash Prokop-Weaver <cashbweaver@gmail.com>
;; Maintainer: Cash Prokop-Weaver <cashbweaver@gmail.com>
;; Created: May 01, 2025
;; Modified: May 01, 2025
;; Version: 0.0.1
;; Keywords: Symbol’s value as variable is void: finder-known-keywords
;; Homepage: https://github.com/cashpw/org-clock-act-on-overtime
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Invoke custom functions every minute while org-clock is overtime.
;;
;;; Code:

(defgroup org-clock-act-on-overtime nil
  "Options related to org-clock act on overtime."
  :tag "Org-clock act on overtime"
  :group 'org)

(defcustom org-clock-act-on-overtime-hook '()
  "List of functions to invoke when org-clock time exceeds the planned duration."
  :type '(repeat function)
  :group 'org-clock-act-on-overtime)

(defun org-clock-act-on-overtime--timestamp-range-duration-in-minutes (timestamp)
  "Return TIMESTAMP range in minutes.

Reference: https://emacs.stackexchange.com/a/79590"
  (if (member (org-element-property :type timestamp) '(active-range inactive-range))
      (/ (time-subtract
          (org-timestamp-to-time ts 'end) (org-timestamp-to-time ts))
         60)
    nil))

(defun org-clock-act-on-overtime--scheduled-duration-minutes-at-point ()
  "Return scheduled duration, in minutes, for heading at point."
  (let ((element (org-element-at-point)))
    (if (org-element-type-p element 'headline)
        (org-clock-act-on-overtime--timestamp-range-duration-in-minutes
         (org-element-property :scheduled (org-element-at-point)))
      0)))

(defun org-clock-act-on-overtime--effort-minutes-at-point ()
  "Return effort, in minutes, for heading at point."
  (org-duration-to-minutes
   (or (org-with-point-at org-clock-hd-marker (org-entry-get (point) "Effort"))
       "")))

(defvar org-clock-act-on-overtime--timer nil)

(defun org-clock-act-on-overtime--time-seconds (time)
  "Return seconds from TIME."
  (cl-destructuring-bind (seconds
                          _minutes
                          _hours
                          _days
                          _months
                          _years
                          _day-of-week
                          _daylight-savings-time-p
                          _utc-offset)
      (decode-time time)
    seconds))

(defun org-clock-act-on-overtime--install-timer ()
  "Install timer to run at every minute at XX:XX:01."
  (setq org-clock-act-on-overtime--timer
        (run-at-time
         (time-add
          nil (1+ (org-clock-act-on-overtime--time-seconds (current-time))))
         'repeat #'org-clock-act-on-overtime--maybe-act)))

(defun org-clock-act-on-overtime--uninstall-timer ()
  "Cancel act-on-overtime timer."
  (cancel-timer org-clock-act-on-overtime--timer))

(defvar org-clock-act-on-overtime-mode nil)

(defun org-clock-act-on-overtime-mode (&optional arg)
  (interactive (list 'toggle 'enable 'disable))
  (setq org-clock-act-on-overtime-mode
        (cond
         ((eq arg 'toggle)
          (not org-clock-act-on-overtime-mode))
         ((eq arg 'enable)
          t)
         ((eq arg 'disable)
          nil)
         (_
          (> arg 0))))
  (if org-clock-act-on-overtime-mode
      (org-clock-act-on-overtime-mode--enable)
    (org-clock-act-on-overtime-mode--disable)))

(defun org-clock-act-on-overtime-mode--enable ()
  "Enable act-on-overtime functionality."
  (org-clock-act-on-overtime--install-timer))

(defun org-clock-act-on-overtime-mode--disable ()
  "Disable act-on-overtime functionality."
  (org-clock-act-on-overtime--uninstall-timer))

(defun org-clock-act-on-overtime--overtime-p ()
  "Return non-nil if org-clock is overtime."
  (when-let* ((clocked-time-in-minutes (org-clock-get-clocked-time))
              (planned-duration-in-minutes
               (org-with-point-at
                   org-clock-hd-marker
                 (or (org-clock-act-on-overtime--scheduled-duration-minutes-at-point)
                     (org-clock-act-on-overtime--effort-minutes-at-point)))))
    (< planned-duration-in-minutes clocked-time-in-minutes)))

(defun org-clock-act-on-overtime--maybe-act ()
  "Invoke overtime functions if we're overtime."
  (when (and org-clock-act-on-overtime-mode
             (org-clock-act-on-overtime--overtime-p))
    (org-clock-act-on-overtime--act)))

(defun org-clock-act-on-overtime--act ()
  "Invoke overtime functions if we're overtime."
  (dolist (fn org-clock-act-on-overtime-fns)
    (funcall fn)))


(provide 'org-clock-act-on-overtime)
;;; org-clock-act-on-overtime.el ends here
