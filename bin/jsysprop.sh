#!/usr/bin/env bash
#
# show java system properties
# from old gist
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
