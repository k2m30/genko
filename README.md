##Description

Small ruby tool to convert svg-files to g-code. Only for triangle drawing machines!

Like this: http://youtu.be/lra0QomDrCA

=====

##Installation

You should install ruby, then install some gems:

`gem install nokogiri`

`gem install yaml`

Clone it

`git clone git@github.com:k2m30/genko.git`

Use it

`cd path_to_genko`

Modify `properties.yml` according to your parameters.

Then

`ruby gcode.rb path_to_your_svg_file`

Following files will be created:

result folder:

`filename_splitted.svg` - as far I don't have full SVG 1.2 support (see below), this file is needed to see future simplified result. 

`filename_result.svg` - drawing translated to triangle coordinates system

`filename.gcode` - g-code file to be sent to you drawing machine.

html folder:

`filename_splitted.html` - shows animated painting

##Features

At the moment it supports only paths elemens with following commands: m, l, q, t, c, s - both, absolute and relative.

No translations supported at the moment (will be added at need).

No matrix transforms even planned.

No viewbox attributes supported (coming soon)

For the complicated images I use iDraw on MacOS - open, slightly modify, export to svg.

##Lisence

MIT, any contribution is appreciated.
