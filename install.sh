#!/bin/bash

apt-get install cups libcups2:i386 -y

cp usr/lib/cups/filter/* /usr/lib/cups/filter/

cp -r usr/share/cups/dell /usr/share/cups/

cp -r usr/share/cups/model/* /usr/share/cups/model/



