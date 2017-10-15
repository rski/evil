;; evil-tests.el --- unit tests for Evil -*- coding: utf-8 -*-

;; Author: Vegard Øye <vegard_oye at hotmail.com>
;; Maintainer: Vegard Øye <vegard_oye at hotmail.com>

;; Version: 1.2.13

;;
;; This file is NOT part of GNU Emacs.

;;; License:

;; This file is part of Evil.
;;
;; Evil is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Evil is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Evil.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file is for developers. It runs some tests on Evil.
;; To load it, run the Makefile target "make test" or add
;; the following lines to .emacs:
;;
;;     (setq evil-tests-run nil) ; set to t to run tests immediately
;;     (global-set-key [f12] 'evil-tests-run) ; hotkey
;;     (require 'evil-tests)
;;
;; Loading this file enables profiling on Evil. The current numbers
;; can be displayed with `elp-results'. The Makefile target
;; "make profiler" shows profiling results in the terminal on the
;; basis of running all tests.
;;
;; To write a test, use `ert-deftest' and specify a :tags value of at
;; least '(evil). The test may inspect the output of functions given
;; certain input, or it may execute a key sequence in a temporary
;; buffer and investigate the results. For the latter approach, the
;; macro `evil-test-buffer' creates a temporary buffer in Normal
;; state. String descriptors initialize and match the contents of
;; the buffer:
;;
;;     (ert-deftest evil-test ()
;;       :tags '(evil)
;;       (evil-test-buffer
;;        "[T]his creates a test buffer." ; cursor on "T"
;;        ("w")                           ; key sequence
;;        "This [c]reates a test buffer."))) ; cursor moved to "c"
;;
;; The initial state, the cursor syntax, etc., can be changed
;; with keyword arguments. See the documentation string of
;; `evil-test-buffer' for more details.
;;
;; This file is NOT part of Evil itself.

(require 'elp)
(require 'ert)
(require 'evil)
(require 'evil-test-helpers)

;;; Code:

(defvar evil-tests-run nil
  "*Run Evil tests.")

(defvar evil-tests-profiler nil
  "*Profile Evil tests.")

(defun evil-tests-initialize (&optional tests profiler interactive)
  (setq profiler (or profiler evil-tests-profiler))
  (when (listp profiler)
    (setq profiler (car profiler)))
  (when profiler
    (setq evil-tests-profiler t)
    (setq profiler
          (or (cdr (assq profiler
                         '((call . elp-sort-by-call-count)
                           (average . elp-sort-by-average-time)
                           (total . elp-sort-by-total-time))))))
    (setq elp-sort-by-function (or profiler 'elp-sort-by-call-count))
    (elp-instrument-package "evil"))
  (if interactive
      (if (y-or-n-p-with-timeout "Run tests? " 2 t)
          (evil-tests-run tests interactive)
        (message "You can run the tests at any time \
with `M-x evil-tests-run'"))
    (evil-tests-run tests)))

(defun evil-tests-run (&optional tests interactive)
  "Run Evil tests."
  (interactive '(nil t))
  (let ((elp-use-standard-output (not interactive)))
    (setq tests
          (or (null tests)
              `(or ,@(mapcar #'(lambda (test)
                                 (or (null test)
                                     (and (memq test '(evil t)) t)
                                     `(or (tag ,test)
                                          ,(format "^%s$" test))))
                             tests))))
    (cond
     (interactive
      (ert-run-tests-interactively tests)
      (when evil-tests-profiler
        (elp-results)))
     (evil-tests-profiler
      (ert-run-tests-batch tests)
      (elp-results))
     (t
      (ert-run-tests-batch-and-exit tests)))))

(defun evil-tests-profiler (&optional force)
  "Profile Evil tests."
  (when (or evil-tests-profiler force)
    (setq evil-tests-profiler t)
    (elp-instrument-package "evil")))


;;; Insertion
(ert-deftest evil-test-copy ()
  :tags '(evil ex)
  "Test `evil-copy'."
  (ert-info ("Copy to last line")
    (evil-test-buffer
      "[l]ine1\nline2\nline3\nline4\nline5\n"
      (":2,3copy$")
      "line1\nline2\nline3\nline4\nline5\nline2\n[l]ine3\n"))
  (ert-info ("Copy to last incomplete line")
    (evil-test-buffer
      "[l]ine1\nline2\nline3\nline4\nline5"
      (":2,3copy$")
      "line1\nline2\nline3\nline4\nline5\nline2\n[l]ine3\n"))
  (ert-info ("Copy incomplete line to last incomplete line")
    (evil-test-buffer
      "[l]ine1\nline2\nline3\nline4\nline5"
      (":4,5copy$")
      "line1\nline2\nline3\nline4\nline5\nline4\n[l]ine5\n"))
  (ert-info ("Copy to first line")
    (evil-test-buffer
      "[l]ine1\nline2\nline3\nline4\nline5\n"
      (":2,3copy0")
      "line2\n[l]ine3\nline1\nline2\nline3\nline4\nline5\n"))
  (ert-info ("Copy to intermediate line")
    (evil-test-buffer
      "[l]ine1\nline2\nline3\nline4\nline5\n"
      (":2,4copy2")
      "line1\nline2\nline2\nline3\n[l]ine4\nline3\nline4\nline5\n"))
  (ert-info ("Copy to current line")
    (evil-test-buffer
      "line1\nline2\nline3\nli[n]e4\nline5\n"
      (":2,4copy.")
      "line1\nline2\nline3\nline4\nline2\nline3\n[l]ine4\nline5\n")))

(provide 'evil-tests)

;;; evil-tests.el ends here
