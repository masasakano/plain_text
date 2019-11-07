
# PlainText - Module and classes to handle plain text

## Summary

This module provides utility functions and methods to handle plain text.  In
the namespace, classes Part/Paragraph/Boundary are defined, which represent
the logical structure of a document and another class ParseRule, which
describes the rules to parse plain text to produce a Part-type Ruby instance.
This package also provides a few command-line programs, such as counting the
number of characters (especially useful for documents in Asian (CJK)
chatacters) and advanced head/tail commands.

The master of this README file, as well as the document for all the methods,
is found in [RubyGems/plain_text](https://rubygems.org/gems/plain_text) and in
[Github](https://github.com/masasakano/plain_text) where all the hyperlinks
are active.

## Design concept

### PlainText - Module and root Namespace

The original plain text should be in String in Ruby.

The module {PlainText} offers some useful methods, such as, {PlainText#head}
and {PlainText#tail}.  They are meant to be included in String.  However, it
also contains some useful module functions, such as, {PlainText.clean_text}
and {PlainText.count_char}.

### PlainText::Part - Core class to describe the logical structure

In the namespace of this module, it contains {PlainText::Part} class, which is
the heart to describe the logical structure of documents. It is basically a
container class and indeed a sub-class of Array. It can contain either of
another {PlainText::Part} or more basic components of either of
{PlainText::Part::Paragraph} and {PlainText::Part::Boundary}, both of which
are sub-classes of String.

An example instance looks like this:

```ruby
Part (
  (0) Paragraph::Empty,
  (1) Boundary::General,
  (2) Part::ArticleHeader(
        (0) Paragraph::Title,
        (1) Boundary::Empty
      ),
  (3) Boundary::TitleMain,
  (4) Part::ArticleMain(
        (0) Part::ArticleSection(
              (0) Paragraph::Title,
              (1) Boundary::General,
              (2) Paragraph::General,
              (3) Boundary::General,
              (4) Part::ArticleSubSection(...),
              (5) Boundary::General,
              (6) Paragraph::General,
              (7) Boundary::Empty
            ),
        (1) Boundary::General,
        (2) Paragraph::General,
        (3) Boundary::Empty
      ),
  (5) Boundary::General
)
```

where the name of subclasses (or constants) here arbitrary, except for
{PlainText::Part::Paragraph::Empty} and {PlainText::Part::Boundary::Empty},
which are pre-defined. Users can define their own subclasses to help organize
the logical structure at their will.

Basically, at every layer, every {PlainText::Part} or
{PlainText::Part::Paragraph} is sandwiched by {PlainText::Part::Boundary},
except for the very first one.

By performing `join` method, one can retrieve the entire document as a String
instance any time.

### PlainText::ParseRule - Class to describe the rule of how to parse

{PlainText::ParseRule} is the class to describe how to parse initially String,
and subsequently {PlainText::Part}, which is basically an Array.
{PlainText::ParseRule} is a container class and holds a set of ordered rules,
each of which is either Proc or Regexp as a more simple rule. A rule, Proc, is
defined by a user and is designed to receive either String (the first
application only) or {PlainText::ParseRule} (Array) and to return a fully (or
partially) parsed {PlainText::ParseRule}. In short, the rule descries how to
determine from where to where a paragraphs and boundaries are located, and
maybe what and where the sections and sub-sections and so on are.

For example, if a rule is Regexp, it describes how to split a String; it is
applied to String in the first application, but if it is applied (and maybe
registered as such) at the second or later stage, it is applied to each
Paragraph and Section separately to split them further.

{PlainText::ParseRule#apply} and {PlainText::Part.parse} are the standard
methods to apply the rules to an object (either String or {PlainText::Part}.

## Command-line tools

All the commands here accept `-h` (or `--help`) option to print the help
message.

### countchar 

Counts the number of characters in a file(s) or STDIN.

The simplest example to run the command-line script is

```ruby
countchar YourFile.txt
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
<dd>   With &lt;tt&gt;--char&lt;/tt&gt; option, it handles the file in units of a chracter, which is
    especially handy to deal with multi-byte characters like UTF-8.</dd>
<dt>Reverse</dt>
<dd>   It can &lt;strong&gt;reverese&lt;/strong&gt; the behaviour - inverse the counting to ouput
    everything but initial NUM lines</dd>
</dl>



A few examples are

```ruby
head.rb -n 5 < try.txt
  # the same as the UNIX head; printing the first 5 lines

head.rb -i -n 5 try.txt
  # printing everything but the first 5 lines
  # The same as the UNIX command:  tail -n +5

head.rb -e '^===+' try.txt
  # => from the top up to the line that begins with more than 3 "="

head.rb -x -e '^===+' try.txt
  # => from the top up to the line before what begins with more than 3 "="

head.rb -e '^===+' -p 3 try.txt
  # => from the top up to 3 lines after what begins with more than 3 "="

head.rb -e '([a-z])\1$' --padding=-2 try.txt
  # => from the top up to 2 lines before what ends with 2
  #    consecutive same letters (case-insentive) like "AA" or "qQ"
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
<dd>   With &lt;tt&gt;--char&lt;/tt&gt; option, it handles the file in units of a chracter, which is
    especially handy to deal with multi-byte characters like UTF-8.</dd>
<dt>Reverse</dt>
<dd>   It can &lt;strong&gt;reverese&lt;/strong&gt; the behaviour - inverse the counting to ouput
    everything but the last NUM lines</dd>
</dl>



See `head.rb` for practical examples.

Note the UNIX form of

```ruby
tail -n +5
```

(which I think is a bit counter-intuieive format) is equivalent to

```ruby
head.rb -i -n 5
```

The suffix `.rb` is used to distinguish this command from the UNIX-shell
standard command.

### yard2md_afterclean

This stands for "yard to markdown - after-clean".


The standard conversion way of RDoc (written for yard) with `rdoc` library

RDoc::Markup::ToMarkdown.new.convert

is limited, with the produced markdown having a fair number of flaws. This
command tries to botch-fix it.  The result is still not perfect but does some
good automation job.

## Miscellaneous

Module {PlainText::Split} contains an instance method (and class method with
the same name) {PlainText::Split#split_with_delimiter}, which is included in
String in default.  The method realises a reversible split of String with a
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

This script requires [Ruby](http://www.ruby-lang.org) Version 2.0 or above
(possibley 2.2 or above?).

For use of the library, if your Ruby script declares

```ruby
require "plain_text"
```

all the related libraries should be read. If you `include PlainText` from
String, it would be handy, though not mandatory to use this library.

As for the command-line script files, they can be put in any of your
command-line search paths.  Make sure the RUBYLIB environment variable
contains the library directory to this gem, which is

```ruby
/THIS/GEM/LIBRARY/PATH/plain_text/lib
```

(which should be set automatically, as long as you use the standard Gem
environment). You may need to modify the first line (Shebang line) of the
script to suit your environment (it should be unnecessary for Linux and
MacOS), or run it explicitly with your Ruby command as

```ruby
Prompt% /YOUR/ENV/ruby /YOUR/INSTALLED/countchar
```

## Developer's note

The source codes are annotated in the [YARD](https://yardoc.org/) format. You
can view it in [RubyGems/plain_text](https://rubygems.org/gems/plain_text) .

The source code is maintained also in
[Github](https://github.com/masasakano/plain_text) with no intuitive interface
for annotation but with easily-browsable
[ChangeLog](https://github.com/masasakano/plain_text/blob/master/ChangeLog)

### Tests

Ruby codes under the directory `test/` are the test scripts. You can run them
from the top directory as `ruby test/test_****.rb` or simply run `make test`.

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
<dd>   MI</dd>
</dl>



