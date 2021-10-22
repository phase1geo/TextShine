# TextShine

A powerful, graphical text conversion utility.

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.phase1geo.textshine">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter" />
  </a>
</p>

![<center><b>Main Window</b></center>](https://raw.githubusercontent.com/phase1geo/TextShine/master/data/screenshots/screenshot-actions.png "Text Conversion application for Elementary OS")

## Overview

Easily paste text from the clipboard or load text from a file, modify the text
with loads of built-in text actions and user-created custom text workflows, and
save the changes to the clipboard or to a file.

In addition to the built-in actions, TextShine allows you to create and test
custom text conversion workflows. These custom workflows can then be used in the
same way that built-in actions are used within the application.

## Key Features

- Load text from clipboard or from a file.
- Save text back to clipboard, to the same file or to a new file.
- Unlimited undo/redo of text changes.
- Apply a text action in a single click.
- Support for action favoriting.
- Support for creating and testing custom actions.
- Quickly search available text actions.
- Character, word, line, match and spelling error statistics.
- Support for font size changes.
- Built-in spell checking.
- Categorized text actions which include:
     * Changing case
     * Inserting text, line numbers, lorem ipsum and file contents
     * Removing line numbers, blank lines/spaces and matched text.
     * Replacement of text.
     * Quotation conversion
     * Line sorting
     * Indentation handling
     * Search and replace (includes regular expression support)
     * Automatic text repair
     * Text conversion
     * MD5, SHA-1/256/384/512 encoding and Base64 encoding/decoding.
     * Markdown utilities

## Installation

You will need the following dependencies to build TextShine:

* ninja-build
* python3-pip
* python3-setuptools
* meson
* valac (version 0.48.3 or later is recommended)
* debhelper
* libgtk-3-dev
* libxml2-dev
* libgee-0.8-dev
* libgtksourceview-4-dev
* libmarkdown2-dev
* libcamel1.2-dev
* libgranite-dev
* libgtkspell3-3-dev

From the command-line within the top TextShine directory, run `./app run` to build
and run the application.

To install, run `sudo ./app install` and then run the application from your
application launcher.

