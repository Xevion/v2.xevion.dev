---
layout: default
title:  Unicode Emojis in Python
date:   2023-05-12 19:07:00 -0500
tags:   unicode emoji python
_preview_description: Dealing with Unicode Emojis in Python
---

While dealing with Emojis, you might notice that some emojis look like normal characters - they
are not colored and look roughly the same on every computer, no matter the font. Others, however, are colored and look
different
on every phone, computer and operating system.

This is because some emojis are made up of multiple characters, while others are made up of a single character.

While that explanation might sound easy enough, and you could click off this article right away, the world of Unicode
is far more complicated. This post intends to explain the basics of Unicode, and how to deal with them in Python.

### Multi-Character Emojis

Multi-character emoji

### Extracting Emojis from Strings

If the string containing emojis has the emojis embedded between 'normal' text, you'll find the `regex` module
invaluable.

> **Note**: Do not confuse the `regex` module with the `re` module. The `regex` module is a third-party module that
> provides more advanced functionality than the standard `re` module. Install it with `pip install regex`.

For example, given a string like this: `💘 I 💖 love ❣️ 💝👨‍👩‍💞✨ emojis! 👨‍👩‍👧‍👦` You'll find that traditional methods
of splitting the string will not work as expected.

- Some emojis are single character, some have 2 characters, and some have an undefined number of characters.
- Some emojis sit directly next to eachother

```python
import regex

embedded_emojis = "💘 I 💖 love ❣️ 💝👨‍👩‍💞✨ emojis! 👨‍👩‍👧‍👦"
for match in regex.finditer(r"\X", embedded_emojis):
    print(match.group(0), ascii(match.group(0))
# 
```

The special `\X` matcher matches complex Graphemes and conforms to the Unicode specification. To translate, it will
properly separate emojis for normal letters, and it won't break apart multi-character emojis.