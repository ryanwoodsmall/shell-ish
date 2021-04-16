#!/usr/bin/env bash
#
# show java system properties
#
# from old gist:
#   https://gist.github.com/ryanwoodsmall/0562fa2427a393d96bbdfce199e048a2
#
# java version:
# /*
#   import java.util.Properties;
#   
#   public class jsysprop {
#   	public static void main(String[] args) {
#   		System.getProperties().list(System.out);
#   	}
#   }
# */
#

jrunscript -e 'java.lang.System.getProperties().list(java.lang.System.out);'
