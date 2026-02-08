#!/bin/bash
. "$HOME/server_profile.sh"

# delete broken symlink
find /usr/local/bin -xtype l -delete
find /usr/local/lib -xtype l -delete

# SERVER PROFILE
cp -af "$PERM_GIT_PATH/ProgramData/server_profile.sh" "$HOME/server_profile.sh"

# chmod and link
## sh
find "$PERM_GIT_PATH/Program/Shell" \( -name '*.lib.sh' \) -prune -o -type f -name '*.sh' -print 2>/dev/null | while IFS= read -r line; do
    chmod 755 "$line"
    line_name=${line##*/}
    ln -sf "$line" "/usr/local/bin/${line_name%.sh}"
done

## lib.sh
find "$PERM_GIT_PATH/Program/Shell" -type f -name '*.lib.sh' -print 2>/dev/null | while IFS= read -r line; do
    line_name=${line##*/}
    ln -sf "$line" "/usr/local/lib/$line_name"
done

## phyton
find "$HOME/Program/Python" \( -name '*.lib.py' \) -prune -o -type f -name '*.py' -print 2>/dev/null | while IFS= read -r line; do
    chmod 755 "$line"
    line_name=${line##*/}
    ln -sf "$line" "/usr/local/bin/${line_name%.py}"
done
