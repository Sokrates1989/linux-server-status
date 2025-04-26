## Checks for updates and prints update info to user.

# 🔧 Resolve actual script directory, even if called via symlink
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Update APT repository.
echo -e "Fetching available updates..."
sudo apt-get update -qq

# Check for available updates.
updates=$(apt list --upgradable 2>/dev/null)
if [ "${#updates}" -gt 10 ]; # Checks length of updates var, because also a fully updated system returns the string "Listing..."
then
    # Display the updates.
    echo -e "Available Updates:"
    echo -e "$updates"
    
    # Tell user how to apply them.
    echo -e "\nTo update you can use this:"
    echo -e "sudo apt-get -y update && sudo apt-get -y upgrade && server-info -u"
    
    echo -e "\nIf there are still updates remaining, try these:"
    echo -e "sudo apt-get --with-new-pkgs upgrade <list of packages kept back>"
    echo -e "sudo apt-get install <list of packages kept back>"
    
    echo -e "\nAggressive solutions are available. Read link. Try above 2 first!"
    echo -e "https://askubuntu.com/questions/601/the-following-packages-have-been-kept-back-why-and-how-do-i-solve-it"
else
    echo -e "No available updates."
fi
