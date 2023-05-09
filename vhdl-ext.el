;;; vhdl-ext.el --- VHDL Extensions -*- lexical-binding: t -*-

;; Copyright (C) 2022-2023 Gonzalo Larumbe

;; Author: Gonzalo Larumbe <gonzalomlarumbe@gmail.com>
;; URL: https://github.com/gmlarumbe/vhdl-ext
;; Version: 0.1.0
;; Keywords: VHDL, IDE, Tools
;; Package-Requires: ((emacs "28.1") (eglot "1.9") (lsp-mode "8.0.1") (ag "0.48") (ripgrep "0.4.0") (hydra "0.15.0") (flycheck "33-cvs"))

;; This program is free software; you can redistribute it and/or modify
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

;; Extensions for VHDL Mode:
;;
;;  - Improve syntax highlighting
;;  - LSP configuration for `lsp-mode' and `eglot'
;;  - Additional options for `flycheck' linters
;;  - Navigate through instances in a module
;;  - Jump to definition/reference of module at point
;;  - Templates insertion via `hydra'
;;  - Improve `imenu': detect instances
;;
;;  Experimental:
;;  - Tree-sitter powered `verilog-ts-mode` support

;;; Code:

;;; Customization
(defgroup vhdl-ext nil
  "VHDL Extensions."
  :group 'languages
  :group 'vhdl-mode)

(defcustom vhdl-ext-feature-list '(font-lock
                                   eglot
                                   lsp
                                   flycheck
                                   navigation
                                   template
                                   imenu)
  "Which Vhdl-ext features to enable."
  :type '(set (const :tag "Improved syntax highlighting via `font-lock'."
                font-lock)
              (const :tag "Setup LSP servers for `eglot'."
                eglot)
              (const :tag "Setup LSP servers for `lsp-mode'."
                lsp)
              (const :tag "Setup linters for `flycheck'."
                flycheck)
              (const :tag "Code Navigation functions."
                navigation)
              (const :tag "`yasnippet' and custom templates."
                template)
              (const :tag "Improved `imenu'."
                imenu))
  :group 'vhdl-ext)

(defmacro vhdl-ext-when-feature (features &rest body)
  "Macro to run BODY if `vhdl-ext' feature is enabled.
FEATURES can be a single feature or a list of features."
  (declare (indent 1) (debug 1))
  `(let (enabled)
     (if (listp ,features)
         (dolist (feature ,features)
           (when (member feature vhdl-ext-feature-list)
             (setq enabled t)))
       ;; Else
       (when (member ,features vhdl-ext-feature-list)
         (setq enabled t)))
     (when enabled
       ,@body)))

;;; Features
(require 'vhdl-ext-utils)
(require 'vhdl-ext-nav)
(require 'vhdl-ext-imenu)
(require 'vhdl-ext-template)
(require 'vhdl-ext-font-lock)
(require 'vhdl-ext-flycheck)
(require 'vhdl-ext-eglot)
(require 'vhdl-ext-lsp)

;;; Major-mode
(defvar vhdl-ext-mode-map
  (let ((map (make-sparse-keymap)))
    (vhdl-ext-when-feature 'navigation
      (define-key map (kbd "C-M-u") 'vhdl-ext-find-entity-instance-bwd)
      (define-key map (kbd "C-M-d") 'vhdl-ext-find-entity-instance-fwd)
      (define-key map (kbd "C-M-.") 'vhdl-ext-jump-to-parent-entity)
      (define-key map (kbd "C-c M-.") 'vhdl-ext-jump-to-entity-at-point-def)
      (define-key map (kbd "C-c M-?") 'vhdl-ext-jump-to-entity-at-point-ref))
    (vhdl-ext-when-feature 'template
      (define-key map (kbd "C-c C-t") 'vhdl-ext-hydra/body))
    map)
  "Key map for the `vhdl-ext'.")

;;;###autoload
(defun vhdl-ext-mode-setup ()
  "Setup `vhdl-ext-mode' depending on enabled features."
  (interactive)
  ;; Jump to parent module ag/ripgrep hooks
  (add-hook 'ag-search-finished-hook #'vhdl-ext-navigation-ag-rg-hook)
  (add-hook 'ripgrep-search-finished-hook #'vhdl-ext-navigation-ag-rg-hook)
  (vhdl-ext-when-feature 'font-lock
    (vhdl-ext-font-lock-setup))
  (vhdl-ext-when-feature 'eglot
    (vhdl-ext-eglot-set-server vhdl-ext-eglot-default-server))
  (vhdl-ext-when-feature 'lsp
    (vhdl-ext-lsp-setup)
    (vhdl-ext-lsp-set-server vhdl-ext-lsp-mode-default-server)))

;;;###autoload
(define-minor-mode vhdl-ext-mode
  "Minor mode for editing VHDL files.

\\{vhdl-ext-mode-map}"
  :lighter " vX"
  :global nil
  (if vhdl-ext-mode
      (progn
        (vhdl-ext-update-buffer-and-dir-list)
        (add-hook 'kill-buffer-hook #'vhdl-ext-kill-buffer-hook nil :local)
        (vhdl-ext-when-feature 'flycheck
          (setq flycheck-ghdl-language-standard (vhdl-ext-get-standard))
          (setq flycheck-ghdl-workdir (vhdl-ext-workdir))
          (setq vhdl-ext-flycheck-ghdl-include-path (append vhdl-ext-flycheck-extra-include vhdl-ext-dir-list))
          (setq vhdl-ext-flycheck-ghdl-work-lib (vhdl-work-library)))
        ;; `vhdl-mode'-only customization (exclude `vhdl-ts-mode')
        (when (eq major-mode 'vhdl-mode)
          ;; Imenu
          (vhdl-ext-when-feature 'imenu
            (advice-add 'vhdl-index-menu-init :override #'vhdl-ext-index-menu-init))
          ;; Font-lock
          ;;   It's not possible to add font-lock keywords to minor-modes.
          ;;   The workaround consists in add/remove keywords to the major mode when
          ;;   the minor mode is loaded/unloaded.
          ;;   https://emacs.stackexchange.com/questions/60198/font-lock-add-keywords-is-not-working
          (vhdl-ext-when-feature 'font-lock
            (font-lock-flush)
            (setq-local font-lock-multiline nil))))
    ;; Cleanup
    (remove-hook 'kill-buffer-hook #'vhdl-ext-kill-buffer-hook :local)
    (vhdl-ext-when-feature 'imenu
      (advice-remove 'vhdl-index-menu-init #'vhdl-ext-index-menu-init))))


;;; Provide
(provide 'vhdl-ext)

;;; vhdl-ext.el ends here

