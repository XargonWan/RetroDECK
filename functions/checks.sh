#!/bin/bash

check_network_connectivity() {
  # This function will do a basic check for network availability and return "true" if it is working.
  # USAGE: if [[ $(check_network_connectivity) == "true" ]]; then

  wget -q --spider "$remote_network_target"

  if [ $? -eq 0 ]; then
    echo "true"
  else
    echo "false"
  fi
}

check_desktop_mode() {
  # This function will do a basic check of if we are running in Steam Deck game mode or not, and return "true" if we are outside of game mode
  # USAGE: if [[ $(check_desktop_mode) == "true" ]]; then

  if [[ ! $XDG_CURRENT_DESKTOP == "gamescope" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

check_for_version_update() {
  # This function will perform a basic online version check and alert the user if there is a new version available.

  local online_version=$(curl --silent "https://api.github.com/repos/XargonWan/$update_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ ! "$update_ignore" == "$online_version" ]]; then
    if [[ "$update_repo" == "RetroDECK" ]] && [[ $(sed -e 's/[\.a-z]//g' <<< $version) -le $(sed -e 's/[\.a-z]//g' <<< $online_version) ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a new version of RetroDECK available!\nYou are running version $hard_version, the latest is $online_version.\n\nIf you would like to update to the new version now, click \"Yes\".\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        (
        flatpak-spawn --host flatpak update --noninteractive -y net.retrodeck.retrodeck
        ) |
        zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Updater" \
        --text="RetroDECK is updating to the latest version, please wait."
        configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
        exit 1
      fi
    elif [[ "$update_repo" == "RetroDECK-cooker" ]] && [[ ! $version == $online_version ]]; then
      choice=$(zenity --icon-name=net.retrodeck.retrodeck --info --no-wrap --ok-label="Yes" --extra-button="No" --extra-button="Ignore this version" \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Update Available" \
        --text="There is a more recent build of the RetroDECK cooker branch.\nYou are running version $hard_version, the latest is $online_version.\n\nWould you like to update to it?\nIf you would like to skip reminders about this version, click \"Ignore this version\".\nYou will be reminded again at the next version update.\n\nIf you would like to disable these update notifications entirely, disable Online Update Checks in the Configurator.")
      rc=$? # Capture return code, as "Yes" button has no text value
      if [[ $rc == "1" ]]; then # If any button other than "Yes" was clicked
        if [[ $choice == "Ignore this version" ]]; then
          set_setting_value $rd_conf "update_ignore" "$online_version" retrodeck "options" # Store version to ignore for future checks.
        fi
      else # User clicked "Yes"
        configurator_generic_dialog "RetroDECK Online Update" "The update process may take several minutes.\n\nAfter the update is complete, RetroDECK will close. When you run it again you will be using the latest version."
        (
        local latest_cooker_download=$(curl --silent https://api.github.com/repos/XargonWan/$update_repo/releases/latest | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')
        mkdir -p "$rdhome/RetroDECK_Updates"
        wget -P "$rdhome/RetroDECK_Updates" $latest_cooker_download
        flatpak-spawn --host flatpak install --user --bundle --noninteractive -y "$rdhome/RetroDECK_Updates/RetroDECK.flatpak"
        rm -rf "$rdhome/RetroDECK_Updates" # Cleanup old bundles to save space
        ) |
        zenity --icon-name=net.retrodeck.retrodeck --progress --no-cancel --pulsate --auto-close \
        --window-icon="/app/share/icons/hicolor/scalable/apps/net.retrodeck.retrodeck.svg" \
        --title "RetroDECK Updater" \
        --text="RetroDECK is updating to the latest version, please wait."
        configurator_generic_dialog "RetroDECK Online Update" "The update process is now complete!\n\nPlease restart RetroDECK to keep the fun going."
        exit 1
      fi
    fi
  fi
}

validate_input() {
  while IFS="^" read -r input action
  do
    if [[ "$input" == "$1" ]]; then
      eval "$action"
      input_validated="true"
    fi
  done < $input_validation
}