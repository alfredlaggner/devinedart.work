Most of the rules for colors, fonts, and other thematic elements are in the theme stylesheet, 
which is found at cw4/theme/cw-theme.css

Cartweaver core structural styles are found in cw-core.css
Specific text styles available in the admin wysiwyg text editor are in cw-styles.css

The theme file is included in the core css using @import
To style your Cartweaver pages, make a copy of the cw-theme.css file, 
(or copy the cw-theme styles into your own css file)
and put into a location of your choosing. 
Then, update the theme file path in cw-core.css to reflect the new path.
@import url(../theme/cw-theme.css);