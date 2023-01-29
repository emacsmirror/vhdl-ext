;;; vhdl-ext-tests-setup.el --- VHDL Tests Setup  -*- lexical-binding: t -*-

;; Copyright (C) 2022-2023 Gonzalo Larumbe

;; Author: Gonzalo Larumbe <gonzalomlarumbe@gmail.com>
;; URL: https://github.com/gmlarumbe/vhdl-ext

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
;;
;; Setup Emacs environment to run vhdl-ext ERT regression
;;
;;; Code:


;;;; Straight bootstrap
(message "Bootstraping straight")

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(message "Bootstraped straight")


;;;; Integration of use-package
(message "Installing use-package")
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)


;;;; Install dependencies
(message "Installing projectile")
(use-package projectile)
(message "Installing ggtags")
(use-package ggtags)
(message "Installing ag")
(use-package ag)
(message "Installing ripgrep")
(use-package ripgrep)
(message "Installing hydra")
(use-package hydra)
(message "Installing outshine")
(use-package outshine)
(message "Installing flycheck")
(use-package flycheck)
(message "Installing faceup for font-lock ERT regressions")
(use-package faceup)
(message "Setting up align")
(use-package align
  :straight nil
  :config
  (setq align-default-spacing 1)
  (setq align-to-tab-stop nil))
(message "Installing lsp-mode")
(use-package lsp-mode)
(message "Installing eglot")
(use-package eglot)
(message "Setting up vhdl-mode")
(use-package vhdl-mode
  :straight nil
  :config
  (setq vhdl-basic-offset 4))


;;;; Install package
(message "Installing and setting up vhdl-ext")
(use-package vhdl-ext
  :straight (:host github :repo "gmlarumbe/vhdl-ext"))



(provide 'vhdl-ext-tests-setup)

;;; vhdl-ext-tests-setup.el ends here
