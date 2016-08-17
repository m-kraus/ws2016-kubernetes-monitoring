#!/bin/bash
chown -R demo:demo /omd/sites/demo/etc
service apache2 restart
omd start
omd status
/bin/bash
