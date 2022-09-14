
# PlainText - Module and classes to handle plain text

## Summary

This module provides utility functions and methods to handle plain text.  In
the namespace, classes Part/Paragraph/Boundary are defined, which represent
the logical structure of a document, and another class ParseRule, which
describes the rules to parse plain text to produce a Part-type Ruby instance.
This package also contains a few command-line programs, such as counting the
number of characters (which is especially useful for text in Asian (CJK)
characters) and advanced head/tail commands.

The master of this README file, as well as the document for all the methods,
is found in [RubyGems/plain_text](https://rubygems.org/gems/plain_text), as
well as in [Github](https://github.com/masasakano/plain_text), where all the
hyperlinks are active.

## Design concept

### PlainText - Module and root Namespace

The original plain text should be String in Ruby.

The module {PlainText} provides some useful methods, such as, {PlainText#head}
and {PlainText#tail}, which are meant to be included in String.  The module
also contains some useful module functions, such as, {PlainText.clean_text}
and {PlainText.count_char}.

### PlainText::Part - Core class to describe the logical structure

The {PlainText::Part} class in the namespace of this module is the core class
to describe the logical structure of a plain-text document. It is basically a
container class and behaves like Array (it has been a subclass of Array up to
Version 0.7). It contains one or more components of other {PlainText::Part}
and {PlainText::Part::Paragraph}, each of which is always followed by a single
{PlainText::Part::Boundary}. Both {PlainText::Part::Paragraph} and
{PlainText::Part::Boundary} behave like String (they used to be subclasses of
String up to Version 0.7).

An example instance looks like this:

```ruby
Part (
  (0) Part::Paragraph::Empty,
  (1) Part::Boundary::General,
  (2) Part::ArticleHeader(
        (0) Part::Paragraph::Title,
        (1) Part::Boundary::Empty
      ),
  (3) Part::Boundary::TitleMain,
  (4) Part::ArticleMain(
        (0) Part::ArticleSection(
              (0) Part::Paragraph::Title,
              (1) Part::Boundary::General,
              (2) Part::Paragraph::General,
              (3) Part::Boundary::General,
              (4) Part::ArticleSubSection(...),
              (5) Part::Boundary::General,
              (6) Part::Paragraph::General,
              (7) Part::Boundary::Empty
            ),
        (1) Part::Boundary::General,
        (2) Part::Paragraph::General,
        (3) Part::Boundary::Empty
      ),
  (5) Part::Boundary::General
)
```

where the names of the subclasses are arbitrary, except for
{PlainText::Part::Paragraph::Empty} and {PlainText::Part::Boundary::Empty},
which are pre-defined. Users can define their own subclasses to help organize
the logical structure at their will.

{PlainText::Part} and {PlainText::Part::Paragraph} are supposed to contain
something significant on its own, whereas {PlainText::Part::Boundary} contains
a kind of separators, such as closing parentheses, spaces, newlines, and
alike.

In this library (document, classes and modules), the former and latter are
collectively referred to as Para (or Paras) and Boundary (or Boundaries),
respectively.  Namely, a Para means either of {PlainText::Part} and
{PlainText::Part::Paragraph}.

`Part#join` method returns the entire plain-text document as a String
instance, just like `Array#join`.

### PlainText::ParseRule - Class to describe the rule of how to parse

{PlainText::ParseRule} is the class to describe how to parse initially String,
and subsequently {PlainText::Part}, which is basically an Array.
{PlainText::ParseRule} is a container class and holds a set of ordered rules,
each of which is either Proc or Regexp.

A rule of Proc is defined by a user and is designed to receive either String
(the first application only) or {PlainText::ParseRule} (Array) and to return a
fully (or partially) parsed {PlainText::ParseRule}. In short, the rule
descries how to determine from where to where a Paras and Boundaries are
located — for example, what and where the sections and sub-sections and so on
are.

For example, if a rule is Regexp, it describes how to split a String; it is
applied to String in the first application, but if it is applied (and maybe
registered as such) at the second or later stages, it is applied to each Para
separately to split them further.

{PlainText::ParseRule#apply} and {PlainText::Part.parse} are the standard
methods to apply the rules to an object (either String or {PlainText::Part}).

## Command-line tools

All the commands here accept `-h` (or `--help`) option to print the help
message.

### countchar 

Counts the number of characters in a file(s) or STDIN.

The simplest example to run the command-line script is

```sh
% countchar YourFile.txt
```

### textclean

Wrapper command of {PlainText.clean_text}. Outputs **cleaned** text, such as,
truncating more than 3 linebreaks into 2.  See the reference of
{PlainText.clean_text} for detail.

### head.rb

This gives advanced functions, in addition to the standard `head`, including

<dl>
<dt>Regexp</dt>
<dd>   It can accept Ruby Regexp to determine the boundary (beginning to the
    first-matched line), including ignore-case, multi-line, extra
    &lt;strong&gt;padding-line&lt;/strong&gt; etc.</dd>
<dt>Character-based</dt>
<dd>   With &lt;tt&gt;--char&lt;/tt&gt; option, it handles the file in units of a character, which
    is especially handy to deal with multi-byte characters like UTF-8.</dd>
<dt>Reverse</dt>
<dd>   It can &lt;strong&gt;reverse&lt;/strong&gt; the behaviour - inverse the counting to output
    everything but initial NUM lines.</dd>
</dl>



A few examples are

```sh
% head.rb -n 5 < try.txt
  # the same as the UNIX head; printing the first 5 lines

% head.rb -i -n 5 try.txt
  # printing everything but the first 5 lines
  # The same as the UNIX command:  tail -n +5

% head.rb -e '^===+' try.txt
  # => from the top up to the line that begins with more than 3 "="

% head.rb -x -e '^===+' try.txt
  # => from the top up to the line before what begins with more than 3 "="

% head.rb -e '^===+' -p 3 try.txt
  # => from the top up to 3 lines after what begins with more than 3 "="

% head.rb -e '([a-z])\1$' --padding=-2 try.txt
  # => from the top up to 2 lines before what ends with 2
  #    consecutive same letters (case-insensitive) like "AA" or "qQ"
```

The suffix `.rb` is used to distinguish this command from the UNIX-shell
standard command.

### tail.rb

This gives advanced functions, in addition to the standard `tail`, including

<dl>
<dt>Regexp</dt>
<dd>   It can accept Ruby Regexp to determine the boundary (last-matched line to
    the end), including ignore-case, multi-line, extra &lt;strong&gt;padding-line&lt;/strong&gt; etc.</dd>
<dt>Character-based</dt>
<dd>   With &lt;tt&gt;--char&lt;/tt&gt; option, it handles the file in units of a character, which
    is especially handy to deal with multi-byte characters like UTF-8.</dd>
<dt>Reverse</dt>
<dd>   It can &lt;strong&gt;reverse&lt;/strong&gt; the behaviour - inverse the counting to output
    everything but the last NUM lines.</dd>
</dl>



See `head.rb` for practical examples.

Note the UNIX form of

```sh
% tail -n +5
```

(which I think is a bit counter-intuitive format) is equivalent to

```sh
% head.rb -i -n 5
```

The suffix `.rb` is used to distinguish this command from the UNIX-shell
standard command.

### yard2md_afterclean

This stands for "yard to markdown - after-clean".


The standard conversion way of RDoc (written for yard) with `rdoc` library

```ruby
RDoc::Markup::ToMarkdown.new.convert
```

is limited, with the produced markdown having a fair number of flaws. This
command tries to botch-fix it.  The result is still not perfect but does some
good automation job.

## Miscellaneous

Module {PlainText::Split} contains an instance method (and class method with
the same name) {PlainText::Split#split_with_delimiter}, which is included in
String in default.  The method realizes a reversible split of String with a
delimiter of an arbitrary Regexp.

In the standard String#split, the following is the result, when sent by a
String instance `s` = `"XQabXXcXQ"`:

```ruby
s.split(/X+Q?/)         #=> ["", "ab", "c"],                   
s.split(/X+Q?/, -1)     #=> ["", "ab", "c", ""],               
s.split(/X+(Q?)/, -1)   #=> ["", "Q", "ab", "", "c", "Q", ""], 
s.split(/(X+(Q?))/, -1) #=> ["", "XQ", "Q", "ab", "XX", "", "c", "XQ", "Q", ""],
```

With this method,

```ruby
s.split_with_delimiter(/X+(Q?)/)
                        #=> ["", "XQ", "ab", "XX", "c", "XQ"]
```

from which the original string is always easily recovered by simple `join`.

Also, {PlainText::Util} contains some miscellaneous methods.

## Description

Work in progress...

## Install

The easiest way to install this library is simply

```ruby
gem install plain_text
```

The library files should be installed in one of your `$LOAD_PATH` and also all
the executables (commands) should be installed in one of your command-line
search paths.

Alternatively, get it from {http://rubygems.org/gems/plain_text}, making sure
the library path and command-line search path are set appropriately.

Then all you need to do is

```ruby
require "plain_text"
```

in your Ruby script (or irb).

This script requires [Ruby](http://www.ruby-lang.org) Version 2.0 or above
(possibly 2.2 or above?).

If you `include PlainText` from String, it would be handy, though not
mandatory to use this library.

As for the shell-executables, you might need to modify the first line (Shebang
line) of the scripts to suit your environment (it should be unnecessary for
Linux and MacOS), or run them explicitly with your Ruby command, such as

```sh
% /YOUR/ENV/ruby /YOUR/INSTALLED/countchar
```

## Developer's note

The source codes are annotated in the [YARD](https://yardoc.org/) format. You
can view it in [RubyGems/plain_text](https://rubygems.org/gems/plain_text) .

The source code is maintained also in
[Github](https://github.com/masasakano/plain_text) with no intuitive interface
for annotation but with easily-browsable
[ChangeLog](https://github.com/masasakano/plain_text/blob/master/ChangeLog)

### Tests

The test suite is located under the directory `test/`. You can run them from
the top directory as `ruby test/test_****.rb` or simply run `make test`.

## Known bugs

None.

## Copyright

<dl>
<dt>Author</dt>
<dd>   Masa Sakano &lt; info a_t wisebabel dot com &gt;</dd>
<dt>Versions</dt>
<dd>   The versions of this package follow Semantic Versioning (2.0.0)
    http://semver.org/</dd>
<dt>License</dt>
<dd>   MIT</dd>
</dl>



