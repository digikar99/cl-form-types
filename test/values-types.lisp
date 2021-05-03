;;;; values-types.lisp
;;;;
;;;; Copyright 2021 Alexander Gutev <alex.gutev@mail.bg>
;;;;
;;;; Permission is hereby granted, free of charge, to any person
;;;; obtaining a copy of this software and associated documentation
;;;; files (the "Software"), to deal in the Software without
;;;; restriction, including without limitation the rights to use,
;;;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;;;; copies of the Software, and to permit persons to whom the
;;;; Software is furnished to do so, subject to the following
;;;; conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be
;;;; included in all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;;;; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;;;; OTHER DEALINGS IN THE SOFTWARE.

;;;; Test that VALUES type specifiers are handled correctly, in the
;;;; internals.

(defpackage :cl-form-types/test.values-types
  (:use :cl-environments-cl
	:cl-form-types
	:alexandria

	:fiveam
	:cl-form-types/test)

  (:import-from :cl-form-types
		:combine-values-types))

(in-package :cl-form-types/test.values-types)


;;; Test Suite Definition

(def-suite values-types
    :description "Test that VALUES type specifiers are handled correctly internally."
    :in cl-form-types)

(in-suite values-types)

(defun values-type= (expected got)
  (flet ((spec= (type1 type2)
	   (if (or (member type1 lambda-list-keywords)
		   (member type2 lambda-list-keywords))
	       (eq type1 type2)
	       (type= type1 type2))))

    (and (eq (first got) 'values)
     (length= got expected)
	 (every #'spec= (cdr expected) (cdr got)))))


;;; Tests

(test combine-simple-types
  "Test combining two simple types (no VALUES specifiers)"

  (is (equal
       '(and integer (eql 10))
       (combine-values-types 'and 'integer '(eql 10))))

  (is (equal
       '(or number character)
       (combine-values-types 'or 'number 'character))))

(test combine-values-types
  "Test combining two VALUES types"

  (is (values-type=
       '(values (and integer (eql 10)) (and character (eql #\x)))

       (combine-values-types
	'and
	'(values integer character)
	'(values (eql 10) (eql #\x))))))

(test combine-simple-with-values-types
  "Test combining a simple type with a VALUES types"

  (is (values-type=
       '(values (or integer (eql 10)) (or character nil))

       (combine-values-types
	'or
	'(values integer character)
	'(eql 10)))))

(test combine-values-type-with-simple
  "Test combining a VALUES types with simple type"

  (is (values-type=
       '(values (or (eql 10) integer) (or nil character))

       (combine-values-types
	'or
	'(eql 10)
	'(values integer character)))))

(test combine-values-optional-types-1
  "Test combining two VALUES types, one with &OPTIONAL"

  (is (values-type=
       '(values (and integer (eql 10)) &optional (and character (eql #\x)))

       (combine-values-types
	'and
	'(values integer character)
	'(values (eql 10) &optional (eql #\x))))))

(test combine-values-optional-types-2
  "Test combining two VALUES types, second with &OPTIONAL"

  (is (values-type=
       '(values (or integer (eql 10)) &optional (or character (eql #\x)))

       (combine-values-types
	'or
	'(values integer &optional character)
	'(values (eql 10) (eql #\x))))))

(test combine-values-optional-types-3
  "Test combining two VALUES types, with &OPTIONAL in different places"

  (is (values-type=
       '(values (and integer (eql 10)) &optional (and number (eql 500)) (and character (eql #\a)))

       (combine-values-types
	'and
	'(values integer number &optional character)
	'(values (eql 10) &optional (eql 500) (eql #\a))))))

(test combine-values-optional-types-1
  "Test combining two VALUES types, one with &OPTIONAL at last element"

  (is (values-type=
       '(values (and integer (eql 10)) (and character (eql #\x)) &optional)

       (combine-values-types
	'and
	'(values integer character)
	'(values (eql 10) (eql #\x) &optional)))))

(test combine-values-type-rest
  "Test combining two VALUES types, one with &REST"

  (is (values-type=
       '(values (or integer number) &rest (or fixnum nil))

       (combine-values-types
	'or
	'(values integer &rest fixnum)
	'(values number)))))

(test combine-values-type-rest-2
  "Test combining two VALUES types, one with &REST"

  (is (values-type=
       '(values (or integer number) (or fixnum (integer 3)) &rest (or fixnum nil))

       (combine-values-types
	'or
	'(values integer &rest fixnum)
	'(values number (integer 3))))))

(test combine-values-type-rest-3
  "Test combining two VALUES types, both with &REST"

  (is (values-type=
       '(values (or integer number) (or fixnum (integer 3)) &rest (or fixnum integer))

       (combine-values-types
	'or
	'(values integer &rest fixnum)
	'(values number (integer 3) &rest integer)))))

(test combine-values-type-rest-last
  "Test combining two VALUES types, one with &REST at last element"

  (is (values-type=
       '(values (or integer number) &rest (or t nil))

       (combine-values-types
	'or
	'(values integer &rest)
	'(values number)))))

(test combine-values-type-rest-optional
  "Test combining two VALUES types, one with &REST and &OPTIONAL"

  (is (values-type=
       '(values &optional (or integer number) &rest (or fixnum nil))

       (combine-values-types
	'or
	'(values &optional integer &rest fixnum)
	'(values number)))))

(test combine-values-type-rest-optional-2
  "Test combining two VALUES types, one with &REST and &OPTIONAL"

  (is (values-type=
       '(values (or integer number) &optional (or fixnum (integer 3)) &rest (or fixnum nil))

       (combine-values-types
	'or
	'(values integer &rest fixnum)
	'(values number &optional (integer 3))))))

(test combine-values-type-rest-optional-3
  "Test combining two VALUES types, both with &REST and &OPTIONAL"

  (is (values-type=
       '(values &optional (or integer number) (or fixnum (integer 3)) &rest (or fixnum integer))

       (combine-values-types
	'or
	'(values &optional integer &rest fixnum)
	'(values number &optional (integer 3) &rest integer)))))

(test combine-values-type-allow-other-keys
  "Test combining two VALUES types, one with &ALLOW-OTHER-KEYS"

  (is (values-type=
       '(values &optional (or integer number) &rest (or fixnum nil) &allow-other-keys)

       (combine-values-types
	'or
	'(values integer &rest fixnum &allow-other-keys)
	'(values &optional number)))))
