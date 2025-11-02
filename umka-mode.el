;;; umka-mode.el --- Major Mode for editing Umka source code -*- lexical-binding: t -*-

;; Copyright (C) 2025 Alexey Kutepov <reximkut@gmail.com>

;; Author: Alexey Kutepov <reximkut@gmail.com>
;; URL: https://github.com/rexim/umka

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; Major Mode for editing Umka source code.

(require 'subr-x)

(defvar umka-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C/C++ style comments
	(modify-syntax-entry ?/ ". 124b" table)
	(modify-syntax-entry ?* ". 23" table)
	(modify-syntax-entry ?\n "> b" table)
    ;; Preprocessor stuff?
    (modify-syntax-entry ?# "." table)
    ;; Chars are the same as strings
    (modify-syntax-entry ?' "\"" table)
    ;; Treat <> as punctuation (needed to highlight C++ keywords
    ;; properly in template syntax)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)

    (modify-syntax-entry ?& "." table)
    (modify-syntax-entry ?% "." table)
    table))

(defun umka-types ()
  '("str" "void" "int8" "int16" "int32" "int" "uint8" "uint16" "uint32" "uint" "bool" "char"
    "real32" "real" "fiber" "any" "__file"))

(defun umka-keywords ()
  '("break" "case" "const" "continue" "default" "else" "enum" "for" "fn" "import" "interface"
    "if" "in" "map" "return" "struct" "switch" "type" "var" "weak"))

(defun umka-builtin ()
  '("abs" "append" "atan" "atan2" "cap" "ceil" "copy" "cos" "delete" "exit" "exp" "fabs" "floor"
    "fprintf" "fscanf" "insert" "keys" "len" "log" "make" "memusage" "new" "printf" "resume"
    "round" "scanf" "selfhasptr" "selfptr" "selftypeeq" "sin" "sizeof" "sizeofself" "slice"
    "sort" "sprintf" "sqrt" "sscanf" "trunc" "typeptr" "valid" "validkey"))

(defun umka-font-lock-keywords ()
  (list
   `(,(regexp-opt (umka-keywords) 'symbols) . font-lock-keyword-face)
   `(,(regexp-opt (umka-types) 'symbols) . font-lock-type-face)
   `(,(regexp-opt (umka-builtin) 'symbols) . font-lock-builtin-face)))

;;; TODO: backport this to simpc-mode
(defun umka--previous-non-empty-line ()
  "Returns either NIL when there is no such line or a pair (line . indentation)"
  (save-excursion
    ;; If you are on the first line, but not at the beginning of buffer (BOB) the `(bobp)`
    ;; function does not return `t`. So we have to move to the beginning of the line first.
    ;; TODO: feel free to suggest a better approach for checking BOB here.
    (move-beginning-of-line nil)
    (if (bobp)
        ;; If you are standing at the BOB, you by definition don't have a previous non-empty line.
        nil
      ;; Moving one line backwards because the current line is by definition is not
      ;; the previous non-empty line.
      (forward-line -1)
      ;; Keep moving backwards until we hit BOB or a non-empty line.
      (while (and (not (bobp))
                  (string-empty-p
                   (string-trim-right
                    (thing-at-point 'line t))))
        (forward-line -1))

      (if (string-empty-p
           (string-trim-right
            (thing-at-point 'line t)))
          ;; If after moving backwards for this long we still look at an empty
          ;; line we by definition didn't find the previous empty line.
          nil
        ;; We found the previous non-empty line!
        (cons (thing-at-point 'line t)
              (current-indentation))))))

(defun umka--desired-indentation ()
  (let ((prev (umka--previous-non-empty-line)))
    (if (not prev)
        (current-indentation)
      (let ((indent-len 4)
            (cur-line (string-trim-right (thing-at-point 'line t)))
            (prev-line (string-trim-right (car prev)))
            (prev-indent (cdr prev)))
        (cond
         ((string-match-p "^\\s-*switch\\s-*(.+)" prev-line)
          prev-indent)
         ((and (string-suffix-p "{" prev-line)
               (string-prefix-p "}" (string-trim-left cur-line)))
          prev-indent)
         ((string-suffix-p "{" prev-line)
          (+ prev-indent indent-len))
         ((string-prefix-p "}" (string-trim-left cur-line))
          (max (- prev-indent indent-len) 0))
         ((string-suffix-p ":" prev-line)
          (if (string-suffix-p ":" cur-line)
              prev-indent
            (+ prev-indent indent-len)))
         ((string-suffix-p ":" cur-line)
          (max (- prev-indent indent-len) 0))
         (t prev-indent))))))

;;; TODO: customizable indentation (amount of spaces, tabs, etc)
(defun umka-indent-line ()
  (interactive)
  (when (not (bobp))
    (let* ((desired-indentation (umka--desired-indentation))
           (n (max (- (current-column) (current-indentation)) 0)))
      (indent-line-to desired-indentation)
      (forward-char n))))

;;;###autoload
(define-derived-mode umka-mode prog-mode "Umka"
  "Simple major mode for editing Umka files."
  :syntax-table umka-mode-syntax-table
  (setq-local font-lock-defaults '(umka-font-lock-keywords))
  (setq-local indent-line-function 'umka-indent-line)
  (setq-local comment-start "// "))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.um\\'" . umka-mode))

(provide 'umka-mode)

;;; umka-mode.el ends here
