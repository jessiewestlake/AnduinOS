# Contributor test checklist

Test at least `en_US` and `zh_CN` locales.

* Ensure during boot, it shall show the logo of our distro.
* Ensure the image can be installed with both BIOS and UEFI.
* Boot the image with **UEFI**. (This is to test the UEFI grub installation)
* Ensure there is no overview on startup.
* Ensure the cursor theme is applied.
* Ensure the resolution is same with the virtual machine.
* Ensure the timezone and language is localized.
* Ensure right clicking the desktop can open console here.
* Ensure desktop icons are shown.
* Ensure there is start button on the task bar with the logo of our distro.
* Right click the icon on taskbar, ensure the menu is localized, shows `Remove from taskbar`.
* Right click the icon on start menu, ensure the menu is localized, shows `Pin to taskbar` and `Unpin from Start menu`.
* Ensure Super + Tab, Alt + Tab, Super + I are functional. (Super + I is (UNDER DEVELOPMENT))
* Ensure Super + U can toggle network stat display.
* Ensure Super + Shift + S will take a screenshot.
* Ensure if the user search `spotify` in the start menu, it will show `Spotify` and can be opened in store.
* Ensure if the device has a battery, battery is shown on the task bar. Otherwise, it's hidden.
* Ensure sound theme, icon theme, shell theme are all set.
* Press `Alt + F2`, then type `r` and press `Enter`. Ensure the shell can be restarted successfully.
* Ensure there will be a `DO` sound (Yaru) when typing tab on terminal.
* Ensure when running `sudo apt update`, it's connecting to localized apt source.
* Ensure `lsb_release` with arg `-i -d -r -c -a` will show the correct information.
* Ensure `https://gist.aiursoft.cn/anduin/53650b8fdc7446b591d4b40cc667bab6/raw/HEAD/check.sh` runs well.
* Ensure folders are sorted before files in nautilus.
* Ensure the `help` in nautilus is working and localized.
* Ensure `/opt` folder is empty.
* Ensure double click a photo file is opened with shotwell; double click a video file is opened with totem; double click a music file is opened with rhythmbox.
* Download a png file and a mp4 file. Ensure the photo and video files have previews on nautilus.
* Ensure double clicking a .deb file will open gnome-software.
* Try start instllation (Ubiquty) and ensure all language texts are shown correctly. (Without square boxes)
* Try running installation. Select `中文`. Ensure in the log there is no error like ``Gtk-WARNING **: Locale not supported by C library. `
* After installation, ensure the start menu apps' names are localized.
* Open terminal and type `ubuntu-` with `Tab`. Ensure it can auto complete to `ubuntu-drivers`.
* Ensure the printer tab in settings can show the printer.
* Ensure the Chinese input can be switched by `Windows + Space` in org.gnome.TextEditor.desktop.
* Ensure Chinese users won't see ibus-libpinyin.
* Ensure the candidate words are shown correctly when typing in org.gnome.TextEditor.desktop.
* Ensure the text `遍角次亮采之门` in org.gnome.TextEditor.desktop is shown correctly.
* Ensure the text `http://` in org.gnome.TextEditor.desktop is shown correctly.
* Try installing Motrix and see if it can be shown successfully on the tray.
* Ensure the corners of the Motrix window is rounded.
* Try installing VSCode and ensure it can be opened successfully, and the corners of the window is rounded.
* Download a H264 video and try to play with `totem` and ensure it can play.
* Try switching from dark and light theme in the bottom drop down menu. And the text should be localized. Both GTK and QT apps should be switched.
* Try pressing `Ctrl + Alt + F6` and ensure it can switch to tty6. Message is `AnduinOS`.
* Try logout. On login screen, correct cursor theme and branding should be applied.

## Release steps

* Build the code, test the image.
* If all tests passed, tag the commit with the version number.
* Build the code for all languages.
* Write the release notes in `AnduinOS-Docs` repo.
* Copy the image and the hash to the server. Verify the hash on the server.
* Update the `AnduinOS-Home` repo with the new version number. (Both `versions.json` and `index.html`.)
* Write the upgrade script for OTA updates in `AnduinOS` repo.
* Copy the OSS software lists.

## Helpfull commands


To check the checksums of all .iso files and their corresponding .sha256 files:

```bash
#!/bin/bash

# Find all .iso files and their corresponding .sha256 files, including subdirectories
find . -type f -name "*.iso" | while read -r iso_file; do
    # Get the corresponding .sha256 file in the same directory
    sha256_file="${iso_file%.iso}.sha256"

    # Check if the .sha256 file exists
    if [[ -f "$sha256_file" ]]; then
        # Read the expected checksum from the .sha256 file and strip the 'SHA256: ' prefix
        expected_checksum=$(cat "$sha256_file" | sed 's/^SHA256: //')

        # Calculate the checksum of the .iso file
        actual_checksum=$(sha256sum "$iso_file" | awk '{ print $1 }')

        # Compare the checksums
        if [[ "$expected_checksum" == "$actual_checksum" ]]; then
            echo "Checksum for $iso_file matches."
        else
            echo "Checksum for $iso_file does not match!"
            echo "Expected: $expected_checksum"
            echo "Actual:   $actual_checksum"
        fi
    else
        echo "SHA256 file for $iso_file not found!"
    fi
done
```
