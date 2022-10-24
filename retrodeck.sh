#!/bin/bash

source /app/libexec/global.sh

# We moved the lockfile in /var/config/retrodeck in order to solve issue #53 - Remove in a few versions
if [ -f "$HOME/retrodeck/.lock" ]
then
  mv "$HOME/retrodeck/.lock" $lockfile
fi

# Arguments section

for i in "$@"; do
  case $i in
    -h*|--help*)
      echo "RetroDECK v""$version"
      echo "
      Usage:
flatpak run [FLATPAK-RUN-OPTION] net.retrodeck-retrodeck [ARGUMENTS]

Arguments:
    -h, --help        Print this help
    -v, --version     Print RetroDECK version
    --info-msg        Print paths and config informations
    --reset           Starts the initial RetroDECK installer (backup your data first!)
    --reset-ra        Resets RetroArch's config to the default values
    --reset-sa        Reset standalone emulator configs to the default values
    --reset-tools     Recreate the tools section

For flatpak run specific options please run: flatpak run -h

https://retrodeck.net
"
      exit
      ;;
    --version*|-v*)
      #conf_init
      echo "RetroDECK v$version"
      exit
      ;;
    --info-msg*)
      #conf_init
      echo "RetroDECK v$version"
      echo "RetroDECK config file is in: $rd_conf"
      echo "Contents:"
      cat $rd_conf
      exit
      ;;
    --reset-ra*)
      ra_init
      shift # past argument with no value
      ;;
    --reset-sa*)
      standalones_init
      shift # past argument with no value
      ;;
    --reset-tools*)
      tools_init
      shift # past argument with no value
      ;;
    --reset*)
      rm -f "$lockfile"
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# UPDATE TRIGGERED
# if lockfile exists
if [ -f "$lockfile" ]
then
  # ...but the version doesn't match with the config file
  if [ "$hard_version" != "$version" ];
  then
      echo "Config file's version is $version but the actual version is $hard_version"
      post_update       # Executing post update script
      conf_write        # Writing variables in the config file (sourced from global.sh)
      start_retrodeck
      exit 0
  fi
# Else, LOCKFILE IS NOT EXISTING (WAS REMOVED)
# if the lock file doesn't exist at all means that it's a fresh install or a triggered reset
else
  echo "Lockfile not found"
  finit             # Executing First/Force init
  conf_write        # Writing variables in the config file (sourced from global.sh)
	exit 0
fi

# Normal Startup
start_retrodeck