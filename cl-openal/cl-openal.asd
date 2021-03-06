;;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Base: 10 -*-

;(declaim (optimize (debug 2) (speed 1) (safety 1) (compilation-speed 1)))
(declaim (optimize (debug 3) (speed 3) (safety 1) (compilation-speed 0)))


(in-package :asdf)

#+(or allegro lispworks cmu mcl cormanlisp sbcl scl)

(defsystem cl-openal
  :name "cl-openal"
  :author "Kenny Tilton <ktilton@nyc.rr.com>"
  :version "1.0.0"
  :maintainer "Kenny Tilton <ktilton@nyc.rr.com>"
  :licence "MIT"
  :description "Partial OpenAL Bindings"
  :long-description "Poorly implemented bindings to half of OpenAL"
  :depends-on (cffi cffi-extender cells)
  :perform (load-op :after (op cl-openal)
             (pushnew :cl-openal cl:*features*))
  :components ((:file "cl-openal")
               (:file "altypes" :depends-on ("cl-openal"))
               (:file "al" :depends-on ("altypes"))
               (:file "alctypes" :depends-on ("al"))
               (:file "alc" :depends-on ("alctypes"))
               (:file "alu" :depends-on ("alc"))
               (:file "alut" :depends-on ("alu"))
               
               (:file "cl-openal-init" :depends-on ("alut"))
               (:file "wav-handling" :depends-on ("cl-openal-init"))
               (:file "cl-openal-demo" :depends-on ("wav-handling"))))
