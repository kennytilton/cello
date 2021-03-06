;; -*- mode: Lisp; Syntax: Common-Lisp; Package: cl-ftgl; -*-
;;;
;;; Copyright (c) 2004 by Kenneth William Tilton.
;;;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy 
;;; of this software and associated documentation files (the "Software"), to deal 
;;; in the Software without restriction, including without limitation the rights 
;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
;;; copies of the Software, and to permit persons to whom the Software is furnished 
;;; to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in 
;;; all copies or substantial portions of the Software.
;;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
;;; IN THE SOFTWARE.

;;; $Header: /project/cello/cvsroot/cello/cl-ftgl/cl-ftgl.lisp,v 1.19 2008/06/16 12:39:26 ktilton Exp $

(eval-when (:compile-toplevel :load-toplevel)
  (pushnew :cl-ftgl *features*))

(defpackage #:cl-ftgl
  (:nicknames #:ftgl)
  (:use #:common-lisp #:cffi #:kt-opengl #:utils-kt #:cells #:cl-freetype)
  (:export #:ftgl 
    #:ftgl-pixmap 
    #:ftgl-texture 
    #:ftgl-bitmap
    #:ftgl-polygon 
    #:ftgl-extruded 
    #:ftgl-outline
    #:ftgl-string-length 
    #:ftgl-char-width
    #:ftgl-get-ascender 
    #:ftgl-get-descender
    #:ftgl-height
    #:ftgl-filetype
    #:ftgl-make 
    #:cl-ftgl-init 
    #:cl-ftgl-reset 
    #:xftgl 
    #:ftgl-render
    #:ftgl-font-ensure
    #:ftgl-format    
    #:ftgl-ft-face
    #:*font-directory-path*
    #:*gui-style-default-face*
    #:*gui-style-button-face*
    #:*ftgl-ogl*))

(in-package :cl-ftgl)

;;; NOTE: Must build the ftgl-int/FTGLFromC.cpp glue library.
(define-foreign-library FTGL
  (:darwin "libfgc.dylib")
  (:windows (:or "ftgl_dynamic_MTD_d.dll")))


#+test
(inspect (cffi::get-foreign-library 'FTGL))

#+test
(probe-file (ukt:exe-dll "ftgl_dynamic_MTD_d"))
;;(use-foreign-library FTGL) - frgo: This leads to problems on OS X !!!
;; -> Use function cl-ftgl-init !

(defparameter *gui-style-default-face*
  #-cffi-features:darwin "STIXGeneral" ;; "Sylfaen"
  #+cffi-features:darwin "Helvetica")

(defparameter *gui-style-button-face*
  #-cffi-features:darwin "comicbd" ;;"STIXGeneral" ;; "Sylfaen"
  #+cffi-features:darwin "Helvetica")

(defparameter *ftgl-loaded-p* nil)
(defparameter *ftgl-fonts-loaded* nil)
(defparameter *ftgl-ogl* nil)


(defparameter *ftgl-font-dirs* nil)
(defparameter *ftgl-application-font-paths*
  (list (make-pathname
         :directory
         '(:relative  "font"))))

(export! ftgl-application-font-paths)

(defun ftgl-application-font-paths ()
  *ftgl-application-font-paths*)

(defun (setf ftgl-application-font-paths) (paths)
  (loop for p in paths
      unless (probe-file p)
      do (error "application font path ~a not found" p))
  (setf *ftgl-application-font-paths* paths))

(defun ftgl-font-directories ()
  (or *ftgl-font-dirs*
    (setf *ftgl-font-dirs*
      #+cffi-features:windows
      (append (ftgl-application-font-paths)
        #+nahhh (list (make-pathname
               :directory
               '(:absolute "Windows" "fonts"))))
      #+cffi-features:darwin
      (append 
       (ftgl-application-font-paths)
       (list
        (make-pathname
         :directory
         '(:absolute "System" "Library" "Fonts"))
        (make-pathname
         :directory
         '(:absolute "Library" "Fonts"))
        (make-pathname
         :directory
         '(:relative "~" "Library" "Fonts"))))
            
      #+(and cffi-features:unix (not cffi-features:darwin))
      (append 
       (ftgl-application-font-paths)
       (list
        (make-pathname
         :directory
         '(:absolute "usr" "share" "truetype")))))))

(defparameter *ftgl-font-types-list* ;; list of font types
  ;; (font filename endings)
  #+cffi-features:darwin
  '("dfont" "ttf")
  
  #+(or cffi-features:windows (and cffi-features:unix (not cffi-features:darwin)))
  '("ttf" "otf"))

(defun find-font-file (font)
  (trc nil "find.font.file> seeks" (ftgl-face font) :n (ftgl-font-directories))
  (or
   (loop for dir in (ftgl-font-directories)
       thereis (loop for ending in *ftgl-font-types-list*
                   thereis (probe-file (merge-pathnames (make-pathname
                                                         :name (string (ftgl-face font))
                                                         :type ending)
                                         dir))))
   (loop initially (trc "find.font.file cant find any of"
                     (loop for ending in *ftgl-font-types-list*
                         collecting (make-pathname
                                     :name (string (ftgl-face font))
                                     :type ending)))
       for dir in (ftgl-font-directories) do
         (loop for f in (directory dir)
             when (and (string-equal (pathname-type f) "TTF")
                    (string-equal (pathname-name f) (string (ftgl-face font))))
             do (trc "...does see" (namestring f))))))

#+test
(probe-file "C:\\0Algebra\\TYExtender\\font\\Sylfaen.ttf")

(defun ftgl-format (font control-string &rest args)
  (ftgl-render font (apply 'format nil control-string args)))

;; ----------------------------------------------------------------------------
;; FOREIGN FUNCTION INTERFACE
;; ----------------------------------------------------------------------------

(defcfun ("fgcSetFaceSize" fgc-set-face-size) :unsigned-char
  (f :pointer)(size :int)(res :int))

;; (defcfun ("fgcCharTexture" fgc-char-texture) :int
;;  (f :pointer)(charCode :int))

(defcfun ("fgcAscender" fgc-ascender) :float
  (font :pointer))

(defcfun ("fgcDescender" fgc-descender) :float
  (font :pointer))

(defcfun ("fgcStringAdvance" fgc-string-advance) :float
  (font :pointer) (text :string))

(defcfun ("fgcStringX" fgc-string-x) :float
  (font :pointer)(text :string))

(defcfun ("fgcRender" fgc-render) :void
  (font :pointer)(text :string))

;; (defcfun ("fgcBuildGlyphs" fgc-build-glyphs) :void
;;  (font :pointer))

(defcfun ("fgcFree" fgc-free) :void
  (font :pointer))

(defcfun ("fgcBitmapMake" fgc-bitmap-make) :pointer
  (typeface :string))
(defcfun ("fgcPixmapMake" fgc-pixmap-make) :pointer
  (typeface :string))
(defcfun ("fgcTextureMake" fgc-texture-make) :pointer
  (typeface :string))
(defcfun ("fgcPolygonMake" fgc-polygon-make) :pointer
  (typeface :string))
(defcfun ("fgcOutlineMake" fgc-outline-make) :pointer
  (typeface :string))
(defcfun ("fgcExtrudedMake" fgc-extruded-make) :pointer
  (typeface :string))

(defcfun ("fgcSetFaceDepth" fgcSetFaceDepth) :unsigned-char
  (font :pointer)(depth :float))

(defun fgc-set-face-depth (font depth)
  (fgcSetFaceDepth font (coerce depth 'float)))

;; ----------------------------------------------------------------------------
;; FUNCTIONS/METHODS
;; ----------------------------------------------------------------------------

(defun cl-ftgl-reset ()
#-(or mcl macosx)  
  (setq *ftgl-loaded-p* nil) 
  #+noway (loop for (nil . font) in *ftgl-fonts-loaded*
      do (fgc-free (ftgl-ifont font)))
  (setq *ftgl-fonts-loaded* nil))

#+test
(progn
  (mgk:wands-clear)
  (cl-ftgl-reset))

(defmacro dbgftgl (tag &body body)
  (declare (ignorable tag))
  `(progn
     #+nahhh (unless (boundp 'ogl::*gl-begun*)
       (assert (zerop (glgeterror))))
     (progn ;; cells:wtrc (0 100 "dbgftgl" ,tag)
       (ftgl-assert-opengl-context)
       (unless (boundp 'ogl::*gl-begun*) (glec :dbgftgl-entry))
       (prog1
           (progn ,@body)
         (unless (boundp 'ogl::*gl-begun*)
           (progn
             (glec :dbgftgl-post-body)))))))

#+test
(progn
  (cl-ftgl-init)
  (let ((sylfaen (ftgl-font-ensure :texture '|ArialHB| 24 96)))
    (print (list "ArialHB ascender" (ftgl-get-ascender sylfaen)))
    (print (list "ArialHB descender" (ftgl-get-descender sylfaen)))
    (print (list "ArialHB hello world length" (ftgl-string-length sylfaen "Hello world")))
    (print (list "ArialHB disp font" (ftgl-get-display-font sylfaen)))
  ))

(defun cl-ftgl-init ()
  (initialize-ft)
  (unless *ftgl-loaded-p*
    (assert (setq *ftgl-loaded-p* (use-foreign-library FTGL)))
    ;(print `(*ftgl-loaded-p* ,*ftgl-loaded-p*))
    ))

#+test
(loop for (fspec . f) in *ftgl-fonts-loaded*
      do (print (list fspec f)))

(defun ftgl-font-ensure (type face size target-res &optional (depth 0))
  (let* ((fspec (list type face size target-res depth))
         (match (cdr (assoc fspec *ftgl-fonts-loaded* :test 'equal))))
    #+shhh (if match
        (progn (cells::trc "ftgl-font-ensure finds match" fspec (ftgl-ifont match)))
      (cells::trc "ftgl-font-ensure NO match"  fspec :in #+shhh (loop for (fspec nil) in *ftgl-fonts-loaded*
                                                             collecting fspec)))
    (or match
      (let ((f (apply 'ftgl-make fspec)))
        (push (cons fspec f) *ftgl-fonts-loaded*)
        ;; (cells::trc "ftgl-font-ensure allocating!!!!!!!!!!! new font spec ifont" fspec (ftgl-ifont f))
        f))))

(defun ftgl-make (type face size target-res &optional (depth 0))
  ;;(print (list "ftgl-make entry" type face size))
  
  (funcall (ecase type
             (:bitmap 'make-ftgl-bitmap)
             (:pixmap 'make-ftgl-pixmap)
             (:texture 'make-ftgl-texture)
             (:outline 'make-ftgl-outline)
             (:polygon 'make-ftgl-polygon)
             (:extruded 'make-ftgl-extruded))
    :face face
    :size (floor size) 
    :target-res target-res
    :depth depth))
    

;; --------- ftgl structure -----------------


(defstruct ftgl
  dbg
  face size target-res depth
  descender ascender 
  (widths (make-array 256 :initial-element nil))
  ft-face
  filetype
  ft-metrics
  (ifont nil))

(defun dbgfont (font calltag)
  (declare (ignore font calltag))
  )

(defun ftgl-assert-opengl-context ()
  ;; use when debugging FTGL being hit before opengl context estanblished 
  (assert *ftgl-ogl*)
  )

(defun ftgl-char-width (f c)
  (ogl-echk :ftgl-char-width)
  (dbgftgl :ftgl-char-width
   (or (aref (ftgl-widths f) (char-code c))
     (setf (aref (ftgl-widths f) (char-code c))
       (ftgl-string-length f (string c))))))

(defstruct (ftgl-disp (:include ftgl))
  ready-p)

(defstruct (ftgl-pixmap (:include ftgl-disp)))
(defstruct (ftgl-texture (:include ftgl-disp)))
(defstruct (ftgl-bitmap (:include ftgl)))
(defstruct (ftgl-polygon (:include ftgl)))
(defstruct (ftgl-extruded (:include ftgl-disp)))
(defstruct (ftgl-outline (:include ftgl)))

(defmethod ftgl-ready (font)
  (declare (ignorable font))
  t)

(defmethod (setf ftgl-ready) (new-value (font ftgl-disp))
  (setf (ftgl-disp-ready-p font) new-value))

(defmethod (setf ftgl-ready) (new-value font)
  (declare (ignore new-value font)))

(defmethod ftgl-ready ((font ftgl-disp))
  (ftgl-disp-ready-p font))


#+allegro
(defun xftgl ()
  (dolist (dll (ff:list-all-foreign-libraries))
    (when (search "ftgl" (pathname-name dll))
      (print `(unloading foreign library ,dll))
      (ff:unload-foreign-library dll)
      (cl-ftgl-reset))))

#+test
(dolist (dll (ff:list-all-foreign-libraries))
  (when t ;(search "free" (pathname-name dll) :test 'string-equal)
    (print `(foreign library ,dll))))

#+doit
(xftgl)

(defun ftgl-get-ascender (font)
  (cells::trc nil "ftgl-get-ascender" (ftgl-ifont font))
  (dbgftgl :ftgl-get-ascender
    (or (ftgl-ascender font)
      (setf (ftgl-ascender font)
        (eko (nil "ftgl.get.ascender" font)
          (let ((mf (ftgl-get-metrics-font font))) ; also loads face
            (if (string-equal (ftgl-face font) "math2___")
                (ftgl-size font)
              #+yeahyeah (round (ft:ft-glyphslotrec/metrics/hori-bearing/y
                        (ft:load-glyph (ftgl-ft-face font) 0 3)) 96)
              (fgc-ascender mf))))))))

(defun ftgl-get-descender (font)
  (cells:trc nil "ftgl-get-descender" (ftgl-ifont font))
  (dbgftgl :ftgl-get-descender
   (or (ftgl-descender font)
     (setf (ftgl-descender font)
       (eko (nil "ftgl.get.descender" font)
         (if (string-equal (ftgl-face font) "math2___")
             (round (ftgl-size font) -2)
           (fgc-descender (ftgl-get-metrics-font font))))))))

(defun ftgl-height (f)
  (cells:trc nil "ftgl-height" (ftgl-ifont f))
  (dbgftgl :ftgl-height
   (- (ftgl-get-ascender f)
     (ftgl-get-descender f))))

(defun ftgl-get-display-font (font)
  (cells:trc nil "ftgl-get-display-font" (ftgl-ifont font))
  (dbgftgl :ftgl-get-display-font
   (let ((cf (ftgl-get-metrics-font font)))
     (assert cf)
     ; (print (list "FTGL-GET-DISPLAY-FONT sees" (ftgl-disp-ready-p font)))
     ;; (print (list "FTGL-GET-DISPLAY-FONT sees" (ftgl-ready font)))
     
     (Unless (ftgl-ready font)
       (cells:trc "ftgl-get-display-font" (ftgl-face font) (ftgl-size font)(ftgl-ifont font))
        (when *ogl-listing-p*
          (cells::c-break "bad time #1 for sizing? ~a ~a" *ogl-listing-p* (cons (ftgl-face font)(ftgl-size font))(ftgl-ifont font)))
       (setf (ftgl-ready font) t)
       (typecase font
         (ftgl-extruded
          #+nyet (let ((*ogl-listing-p* t))
                   (cells:trc nil "ftgl-get-display-font> building glyphs for" font)
                   
                   (fgc-build-glyphs cf)
                   (cells:trc nil "ftgl-get-display-font> glyphs built OK for" font)))
         (ftgl-texture
          #+fails (fgc-set-face-size cf (ftgl-size font) (ftgl-target-res font)))
         (ftgl-pixmap
          #+no (fgc-set-face-size cf (ftgl-size font) (ftgl-target-res font)))))
     (glec :ftgl-get-display-font)
     cf)))

(defun ftgl-get-metrics-font (font)
  (or (ftgl-ifont font)
    (setf (ftgl-ifont font) (ftgl-font-make font))))

(defun ftgl-font-make (font)
  (eko (nil "made cpp FTGL font ~a" (ftgl-face font)(ftgl-size font))
    (bif (path (find-font-file font))
      (let ((fpath (namestring path)))
        (bif (f (fgc-font-make font fpath))
          (progn
            (prog1
                (setf (ftgl-ft-face font) (ft:get-new-face (namestring path)))
              ;(trc "making!!!!!!!!!!!! afce!!!!!!" (ftgl-face font))
              (assert (ftgl-ft-face font)))
            (ft:set-char-size (ftgl-ft-face font) (ft:to-ft (ftgl-size font)) (ftgl-target-res font))
            #+shhh (loop with size = (ft:ft-facerec/size (ftgl-ft-face font))
                       for (k m) on (list :x-ppem (ft:ft-sizerec/metrics/x-ppem size)
                                      :y-ppem (ft:ft-sizerec/metrics/y-ppem size)
                                      :x-scale (ft:ft-sizerec/metrics/x-scale size)
                                      :y-scale (ft:ft-sizerec/metrics/y-scale size)
                                      :ascender (ft:ft-sizerec/metrics/ascender size)
                                      :descender (ft:ft-sizerec/metrics/descender size)
                                      :height (ft:ft-sizerec/metrics/height size)
                                      :max-advance (ft:ft-sizerec/metrics/max-advance size)) by #'cddr
                       do (print (list k (ft:from-ft m))))
            
            (setf (ftgl-filetype font) (intern (up$ (pathname-type path)) :keyword))
            (fgc-set-face-size f (ftgl-size font) (ftgl-target-res font))
            f)
          (error "cannot load ~a font ~a" (type-of font) fpath)))
      (error "Font not found: ~a" path))))

(defmethod ftgl-render (font s)
  (assert font)
  (assert (stringp s))
  (dbgfont font :ftgl-render)
  (dbgftgl :ftgl-render
   (when font
     (fgc-render (ftgl-get-metrics-font font) s))))

(defmethod ftgl-render :before ((font ftgl-extruded) s)
  (declare (ignorable s))
  (ftgl-get-display-font font))

(defmethod ftgl-render :before ((font ftgl-texture) s)
  (declare (ignorable s))
  (dbgfont font :ftgl-render-before)
  
  (if (boundp 'ogl::*gl-begun*)
      (break "gl begun OK?" font)
    (trc nil "cool" s))
  
  (dbgftgl :ftgl-render
    (gl-enable gl_texture_2d)
    (gl-enable gl_blend)
    (gl-disable gl_lighting)))
    
(defmethod fgc-font-make :before (font fpath)
  (declare (ignore font fpath))
  ;(format t "~%FGC-FONT-MAKE: ~a fpath = ~A" (type-of font) fpath)
  (cl-ftgl-init))

(defmethod fgc-font-make ((font ftgl-pixmap) fpath)
  (fgc-pixmap-make fpath))
  
(defmethod fgc-font-make ((font ftgl-bitmap) fpath)
  (fgc-bitmap-make fpath))
  
(defmethod fgc-font-make ((font ftgl-texture) fpath)
  (fgc-texture-make fpath))

(defmethod fgc-font-make ((font ftgl-extruded) fpath)
  (let ((fgc (fgc-extruded-make fpath)))
    (fgc-set-face-depth fgc (ftgl-depth font))
    fgc))

(defmethod fgc-font-make ((font ftgl-outline) fpath)
  (fgc-outline-make fpath))

(defmethod fgc-font-make ((font ftgl-polygon) fpath)
  (fgc-polygon-make fpath))

(defun ftgl-string-length (font cs)
  (dbgftgl :ftgl-string-length
    (fgc-string-advance (ftgl-get-metrics-font font) cs)))

(defmethod font-bearing-x (font &optional text)
  (declare (ignorable font text))
  0)
